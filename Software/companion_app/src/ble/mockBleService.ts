/**
 * High-fidelity virtual F91_Jepler smartwatch BLE driver.
 *
 * Implements BleClientInterface for testing, prototyping, and automated CI verification.
 * Accurately simulates the Zephyr RTOS clock_service.c GATT server:
 * - In-memory GATT database
 * - Strict length validation (4B, 2B, 1B, 1B) returning BT_ATT_ERR_INVALID_OFFSET (0x07) on mismatch
 * - Real-time simulated watch clock state
 * - Programmable fault injection (link loss, write failure, connection rejection)
 * - Chronological write history logging
 */

import {
  BleClientInterface,
  BleDevice,
  DisconnectListener,
} from './bleClientInterface';
import {
  F91_DEVICE_NAME,
  CLOCK_SERVICE_UUID,
  CLOCK_TIME_CHAR_UUID,
  CLOCK_TIMEZONE_CHAR_UUID,
  CLOCK_TIMEMODE_CHAR_UUID,
  CLOCK_DST_CHAR_UUID,
  CLOCK_PAYLOAD_LENGTHS,
  BT_ATT_ERR_INVALID_OFFSET,
} from './gattConstants';
import {
  deserializeTime,
  deserializeTimezone,
  deserializeTimeMode,
  deserializeDst,
  serializeTime,
  serializeTimezone,
  serializeTimeMode,
  serializeDst,
} from './gattSerializer';

export interface SimulatedWatchState {
  clockTime: number; // Unix epoch seconds
  clockTimezone: number; // Minutes from UTC
  clockTimeMode: number; // 0 for 12h, 1 for 24h
  clockDst: number; // 0 for standard, 1 for DST
}

export interface GattWriteRecord {
  deviceId: string;
  serviceUuid: string;
  characteristicUuid: string;
  data: Uint8Array;
  timestamp: number;
}

export class MockBleService implements BleClientInterface {
  private initialized = false;
  private scanning = false;
  private scanCallback: ((device: BleDevice) => void) | null = null;
  private connectedDeviceId: string | null = null;
  private disconnectListeners: Set<DisconnectListener> = new Set();

  /** Discovered / discoverable mock devices */
  private availableDevices: BleDevice[] = [
    {
      deviceId: 'F91-WATCH-SIM-01',
      name: F91_DEVICE_NAME,
      rssi: -62,
      services: [CLOCK_SERVICE_UUID],
    },
  ];

  /** Simulated internal watch clock registers */
  private watchState: SimulatedWatchState = {
    clockTime: 1700000000,
    clockTimezone: -300,
    clockTimeMode: 0,
    clockDst: 0,
  };

  /** In-memory GATT characteristic value store */
  private gattDatabase: Map<string, Uint8Array> = new Map();

  /** Chronological history of all GATT writes */
  private writeHistory: GattWriteRecord[] = [];

  /** Fault injection controls */
  private nextConnectionError: string | null = null;
  private nextWriteError: { charUuid?: string; error: string } | null = null;
  private writeLatencyMs = 0;

  constructor() {
    this.syncGattDatabaseFromState();
  }

  /**
   * Syncs raw byte buffers in GATT database to match current watchState.
   */
  private syncGattDatabaseFromState(): void {
    this.gattDatabase.set(CLOCK_TIME_CHAR_UUID, serializeTime(this.watchState.clockTime));
    this.gattDatabase.set(CLOCK_TIMEZONE_CHAR_UUID, serializeTimezone(this.watchState.clockTimezone));
    this.gattDatabase.set(CLOCK_TIMEMODE_CHAR_UUID, serializeTimeMode(this.watchState.clockTimeMode));
    this.gattDatabase.set(CLOCK_DST_CHAR_UUID, serializeDst(this.watchState.clockDst));
  }

  // --- BleClientInterface Implementation ---

  async initialize(): Promise<void> {
    this.initialized = true;
  }

  async startScan(onDeviceFound: (device: BleDevice) => void): Promise<void> {
    if (!this.initialized) {
      await this.initialize();
    }
    this.scanning = true;
    this.scanCallback = onDeviceFound;

    // Simulate immediate discovery of matching peripherals
    for (const dev of this.availableDevices) {
      // Filter for F91_Jepler name or Clock Service UUID
      const matchesName = dev.name === F91_DEVICE_NAME;
      const matchesService = dev.services?.some(
        (s) => s.toLowerCase() === CLOCK_SERVICE_UUID.toLowerCase()
      );

      if (matchesName || matchesService) {
        onDeviceFound({ ...dev });
      }
    }
  }

  async stopScan(): Promise<void> {
    this.scanning = false;
    this.scanCallback = null;
  }

  async connect(deviceId: string): Promise<void> {
    if (!this.initialized) {
      await this.initialize();
    }

    if (this.nextConnectionError) {
      const err = new Error(this.nextConnectionError);
      this.nextConnectionError = null;
      throw err;
    }

    const device = this.availableDevices.find((d) => d.deviceId === deviceId);
    if (!device) {
      throw new Error(`Device not found: ${deviceId}`);
    }

    this.connectedDeviceId = deviceId;
  }

  async disconnect(deviceId: string): Promise<void> {
    if (this.connectedDeviceId === deviceId) {
      this.connectedDeviceId = null;
      this.notifyDisconnect(deviceId);
    }
  }

  async writeCharacteristic(
    deviceId: string,
    serviceUuid: string,
    characteristicUuid: string,
    data: Uint8Array
  ): Promise<void> {
    if (this.connectedDeviceId !== deviceId) {
      throw new Error(`Device is not connected: ${deviceId}`);
    }

    if (this.writeLatencyMs > 0) {
      await new Promise((resolve) => setTimeout(resolve, this.writeLatencyMs));
    }

    if (
      this.nextWriteError &&
      (!this.nextWriteError.charUuid ||
        this.nextWriteError.charUuid.toLowerCase() === characteristicUuid.toLowerCase())
    ) {
      const err = new Error(this.nextWriteError.error);
      this.nextWriteError = null;
      throw err;
    }

    // Verify service UUID
    if (serviceUuid.toLowerCase() !== CLOCK_SERVICE_UUID.toLowerCase()) {
      throw new Error(`Unknown service UUID: ${serviceUuid}`);
    }

    const lowerChar = characteristicUuid.toLowerCase();

    // Strict length checking conforming directly to Zephyr clock_service.c
    if (lowerChar === CLOCK_TIME_CHAR_UUID.toLowerCase()) {
      if (data.byteLength !== CLOCK_PAYLOAD_LENGTHS.TIME) {
        throw new Error(
          `GATT Error 0x${BT_ATT_ERR_INVALID_OFFSET.toString(16)} (BT_ATT_ERR_INVALID_OFFSET): invalid Time payload length ${data.byteLength}, expected ${CLOCK_PAYLOAD_LENGTHS.TIME}`
        );
      }
      this.watchState.clockTime = deserializeTime(data);
    } else if (lowerChar === CLOCK_TIMEZONE_CHAR_UUID.toLowerCase()) {
      if (data.byteLength !== CLOCK_PAYLOAD_LENGTHS.TIMEZONE) {
        throw new Error(
          `GATT Error 0x${BT_ATT_ERR_INVALID_OFFSET.toString(16)} (BT_ATT_ERR_INVALID_OFFSET): invalid Timezone payload length ${data.byteLength}, expected ${CLOCK_PAYLOAD_LENGTHS.TIMEZONE}`
        );
      }
      this.watchState.clockTimezone = deserializeTimezone(data);
    } else if (lowerChar === CLOCK_TIMEMODE_CHAR_UUID.toLowerCase()) {
      if (data.byteLength !== CLOCK_PAYLOAD_LENGTHS.TIMEMODE) {
        throw new Error(
          `GATT Error 0x${BT_ATT_ERR_INVALID_OFFSET.toString(16)} (BT_ATT_ERR_INVALID_OFFSET): invalid Time Mode payload length ${data.byteLength}, expected ${CLOCK_PAYLOAD_LENGTHS.TIMEMODE}`
        );
      }
      this.watchState.clockTimeMode = deserializeTimeMode(data) ? 1 : 0;
    } else if (lowerChar === CLOCK_DST_CHAR_UUID.toLowerCase()) {
      if (data.byteLength !== CLOCK_PAYLOAD_LENGTHS.DST) {
        throw new Error(
          `GATT Error 0x${BT_ATT_ERR_INVALID_OFFSET.toString(16)} (BT_ATT_ERR_INVALID_OFFSET): invalid DST payload length ${data.byteLength}, expected ${CLOCK_PAYLOAD_LENGTHS.DST}`
        );
      }
      this.watchState.clockDst = deserializeDst(data) ? 1 : 0;
    } else {
      throw new Error(`Unknown characteristic UUID: ${characteristicUuid}`);
    }

    // Store in GATT DB
    this.gattDatabase.set(lowerChar, new Uint8Array(data));

    // Record write history
    this.writeHistory.push({
      deviceId,
      serviceUuid,
      characteristicUuid: lowerChar,
      data: new Uint8Array(data),
      timestamp: Date.now(),
    });
  }

  async readCharacteristic(
    deviceId: string,
    serviceUuid: string,
    characteristicUuid: string
  ): Promise<Uint8Array> {
    if (this.connectedDeviceId !== deviceId) {
      throw new Error(`Device is not connected: ${deviceId}`);
    }

    if (serviceUuid.toLowerCase() !== CLOCK_SERVICE_UUID.toLowerCase()) {
      throw new Error(`Unknown service UUID: ${serviceUuid}`);
    }

    const val = this.gattDatabase.get(characteristicUuid.toLowerCase());
    if (!val) {
      throw new Error(`Characteristic not found: ${characteristicUuid}`);
    }

    return new Uint8Array(val);
  }

  async isConnected(deviceId: string): Promise<boolean> {
    return this.connectedDeviceId === deviceId;
  }

  onDisconnect(listener: DisconnectListener): void {
    this.disconnectListeners.add(listener);
  }

  removeDisconnectListener(listener: DisconnectListener): void {
    this.disconnectListeners.delete(listener);
  }

  private notifyDisconnect(deviceId: string): void {
    for (const listener of this.disconnectListeners) {
      try {
        listener(deviceId);
      } catch (err) {
        console.error('Error in disconnect listener:', err);
      }
    }
  }

  // --- Testing & Simulation Utilities ---

  /**
   * Returns current internal clock registers of the simulated watch.
   */
  getWatchState(): Readonly<SimulatedWatchState> {
    return { ...this.watchState };
  }

  /**
   * Sets current internal clock registers of the simulated watch.
   */
  setWatchState(state: Partial<SimulatedWatchState>): void {
    this.watchState = { ...this.watchState, ...state };
    this.syncGattDatabaseFromState();
  }

  /**
   * Returns all recorded GATT writes in chronological order.
   */
  getWriteHistory(): readonly GattWriteRecord[] {
    return [...this.writeHistory];
  }

  /**
   * Clears the write history log.
   */
  clearWriteHistory(): void {
    this.writeHistory = [];
  }

  /**
   * Returns the raw byte buffer currently stored in the simulated GATT database for a characteristic.
   */
  getCharacteristicValue(charUuid: string): Uint8Array | undefined {
    const val = this.gattDatabase.get(charUuid.toLowerCase());
    return val ? new Uint8Array(val) : undefined;
  }

  /**
   * Configures the list of available mock devices for scanning.
   */
  setAvailableDevices(devices: BleDevice[]): void {
    this.availableDevices = [...devices];
  }

  /**
   * Simulates finding an additional device during an active scan.
   */
  simulateDeviceFound(device: BleDevice): void {
    this.availableDevices.push(device);
    if (this.scanning && this.scanCallback) {
      this.scanCallback({ ...device });
    }
  }

  /**
   * Simulates an unexpected link drop (e.g. watch battery pulled or out of range).
   */
  simulateDisconnect(deviceId?: string): void {
    const target = deviceId || this.connectedDeviceId;
    if (target && this.connectedDeviceId === target) {
      this.connectedDeviceId = null;
      this.notifyDisconnect(target);
    }
  }

  /**
   * Configures the next connection attempt to fail with the given error message.
   */
  failNextConnection(reason: string = 'Connection failed'): void {
    this.nextConnectionError = reason;
  }

  /**
   * Configures the next characteristic write to fail with the given error message.
   */
  failNextWrite(charUuid?: string, reason: string = 'GATT Write failed'): void {
    this.nextWriteError = { charUuid, error: reason };
  }

  /**
   * Sets artificial write delay in milliseconds for stress testing.
   */
  setWriteLatency(ms: number): void {
    this.writeLatencyMs = ms;
  }

  /**
   * Resets all state, history, and fault injection hooks.
   */
  reset(): void {
    this.connectedDeviceId = null;
    this.scanning = false;
    this.scanCallback = null;
    this.nextConnectionError = null;
    this.nextWriteError = null;
    this.writeLatencyMs = 0;
    this.writeHistory = [];
    this.watchState = {
      clockTime: 1700000000,
      clockTimezone: -300,
      clockTimeMode: 0,
      clockDst: 0,
    };
    this.syncGattDatabaseFromState();
  }
}
