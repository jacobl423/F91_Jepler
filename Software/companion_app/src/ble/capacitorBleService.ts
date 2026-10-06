/**
 * Production BLE driver for Android and iOS devices using @capacitor-community/bluetooth-le.
 *
 * Implements BleClientInterface for live mobile hardware:
 * - Scans with filtering for device name "F91_Jepler" or Clock Service UUID "fa35b2f0-7989-11eb-9439-0242ac130002"
 * - Manages peripheral connection lifecycle and link lost callbacks
 * - Executes GATT Characteristic Write Requests with ATT responses
 * - Handles native data type conversions between Uint8Array and DataView
 */

import { BleClient, ScanResult } from '@capacitor-community/bluetooth-le';
import {
  BleClientInterface,
  BleDevice,
  DisconnectListener,
} from './bleClientInterface';
import {
  F91_DEVICE_NAME,
  CLOCK_SERVICE_UUID,
} from './gattConstants';

export class CapacitorBleService implements BleClientInterface {
  private isInitialized = false;
  private isScanning = false;
  private connectedDevices = new Set<string>();
  private disconnectListeners = new Set<DisconnectListener>();

  async initialize(): Promise<void> {
    if (this.isInitialized) {
      return;
    }

    try {
      await BleClient.initialize();
      this.isInitialized = true;
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      throw new Error(`Failed to initialize Capacitor BLE: ${message}`);
    }
  }

  async startScan(onDeviceFound: (device: BleDevice) => void): Promise<void> {
    if (!this.isInitialized) {
      await this.initialize();
    }

    if (this.isScanning) {
      await this.stopScan();
    }

    this.isScanning = true;

    try {
      // Use requestLEScan without strict service filter in the OS call,
      // because F91_Jepler broadcasts its name in primary advertisement
      // and service UUID in scan response/GATT.
      await BleClient.requestLEScan(
        {
          allowDuplicates: false,
        },
        (result: ScanResult) => {
          if (this.matchesF91Jepler(result)) {
            const device: BleDevice = {
              deviceId: result.device.deviceId,
              name: result.localName || result.device.name || F91_DEVICE_NAME,
              rssi: result.rssi,
              services: result.device.uuids,
            };
            onDeviceFound(device);
          }
        }
      );
    } catch (err: unknown) {
      this.isScanning = false;
      const message = err instanceof Error ? err.message : String(err);
      throw new Error(`Failed to start BLE scan: ${message}`);
    }
  }

  /**
   * Evaluates whether a scan result matches the F91_Jepler criteria:
   * 1. Peripheral name matches "F91_Jepler"
   * 2. Advertised service UUID matches Clock Service UUID
   */
  private matchesF91Jepler(result: ScanResult): boolean {
    const targetName = F91_DEVICE_NAME.toLowerCase();
    const targetService = CLOCK_SERVICE_UUID.toLowerCase();

    // Check device name or advertised localName
    if (
      result.localName?.toLowerCase() === targetName ||
      result.device.name?.toLowerCase() === targetName
    ) {
      return true;
    }

    // Check advertised service UUIDs
    if (result.device.uuids?.some((uuid) => uuid.toLowerCase() === targetService)) {
      return true;
    }

    return false;
  }

  async stopScan(): Promise<void> {
    if (!this.isScanning) {
      return;
    }

    try {
      await BleClient.stopLEScan();
    } catch (err: unknown) {
      console.warn('Error while stopping BLE scan:', err);
    } finally {
      this.isScanning = false;
    }
  }

  async connect(deviceId: string): Promise<void> {
    if (!this.isInitialized) {
      await this.initialize();
    }

    try {
      await BleClient.connect(deviceId, (disconnectedDeviceId) => {
        this.connectedDevices.delete(disconnectedDeviceId);
        this.notifyDisconnect(disconnectedDeviceId);
      });
      this.connectedDevices.add(deviceId);
    } catch (err: unknown) {
      this.connectedDevices.delete(deviceId);
      const message = err instanceof Error ? err.message : String(err);
      throw new Error(`Failed to connect to device ${deviceId}: ${message}`);
    }
  }

  async disconnect(deviceId: string): Promise<void> {
    try {
      await BleClient.disconnect(deviceId);
    } catch (err: unknown) {
      console.warn(`Error during disconnect of ${deviceId}:`, err);
    } finally {
      this.connectedDevices.delete(deviceId);
      this.notifyDisconnect(deviceId);
    }
  }

  async writeCharacteristic(
    deviceId: string,
    serviceUuid: string,
    characteristicUuid: string,
    data: Uint8Array
  ): Promise<void> {
    const dataView = new DataView(data.buffer, data.byteOffset, data.byteLength);

    try {
      // Standard Write Request (with ATT response) to ensure sequential synchronization
      await BleClient.write(deviceId, serviceUuid, characteristicUuid, dataView);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      throw new Error(
        `Failed to write characteristic ${characteristicUuid} on device ${deviceId}: ${message}`
      );
    }
  }

  async readCharacteristic(
    deviceId: string,
    serviceUuid: string,
    characteristicUuid: string
  ): Promise<Uint8Array> {
    try {
      const dataView = await BleClient.read(deviceId, serviceUuid, characteristicUuid);
      return new Uint8Array(dataView.buffer, dataView.byteOffset, dataView.byteLength);
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : String(err);
      throw new Error(
        `Failed to read characteristic ${characteristicUuid} on device ${deviceId}: ${message}`
      );
    }
  }

  async isConnected(deviceId: string): Promise<boolean> {
    return this.connectedDevices.has(deviceId);
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
        console.error('Error in disconnect listener callback:', err);
      }
    }
  }
}
