import { describe, it, expect, beforeEach, vi } from 'vitest';
import { MockBleService } from '../src/ble/mockBleService';
import {
  F91_DEVICE_NAME,
  CLOCK_SERVICE_UUID,
  CLOCK_TIME_CHAR_UUID,
  CLOCK_TIMEZONE_CHAR_UUID,
  CLOCK_TIMEMODE_CHAR_UUID,
  CLOCK_DST_CHAR_UUID,
} from '../src/ble/gattConstants';
import {
  serializeTime,
  serializeTimezone,
  serializeTimeMode,
  serializeDst,
  deserializeTime,
  deserializeTimezone,
} from '../src/ble/gattSerializer';
import { BleDevice } from '../src/ble/bleClientInterface';

describe('MockBleService Engine & GATT Server Simulation Tests', () => {
  let mockBle: MockBleService;
  const targetDeviceId = 'F91-WATCH-SIM-01';

  beforeEach(() => {
    mockBle = new MockBleService();
  });

  describe('S1: Initialization and Device Discovery', () => {
    it('should initialize cleanly and transition state', async () => {
      await expect(mockBle.initialize()).resolves.toBeUndefined();
    });

    it('should discover matching F91_Jepler peripheral during scan', async () => {
      const discovered: BleDevice[] = [];
      await mockBle.startScan((device) => {
        discovered.push(device);
      });

      expect(discovered.length).toBeGreaterThanOrEqual(1);
      const target = discovered.find((d) => d.name === F91_DEVICE_NAME);
      expect(target).toBeDefined();
      expect(target?.deviceId).toBe(targetDeviceId);

      await mockBle.stopScan();
    });

    it('should filter out non-matching devices and discover both name & service UUID matches', async () => {
      mockBle.setAvailableDevices([
        { deviceId: 'DEV-1', name: F91_DEVICE_NAME, rssi: -50 },
        { deviceId: 'DEV-2', name: 'Other_Band', services: [CLOCK_SERVICE_UUID], rssi: -70 },
        { deviceId: 'DEV-3', name: 'Rogue_Earbuds', services: ['0000180f-0000-1000-8000-00805f9b34fb'], rssi: -85 },
      ]);

      const discovered: BleDevice[] = [];
      await mockBle.startScan((device) => {
        discovered.push(device);
      });

      expect(discovered.length).toBe(2);
      expect(discovered.map((d) => d.deviceId)).toEqual(['DEV-1', 'DEV-2']);
      expect(discovered.some((d) => d.deviceId === 'DEV-3')).toBe(false);

      await mockBle.stopScan();
    });

    it('should support dynamic peripheral discovery while scanning', async () => {
      const discovered: BleDevice[] = [];
      await mockBle.startScan((device) => {
        discovered.push(device);
      });

      const initialCount = discovered.length;
      mockBle.simulateDeviceFound({
        deviceId: 'F91-WATCH-SIM-02',
        name: F91_DEVICE_NAME,
        rssi: -55,
      });

      expect(discovered.length).toBe(initialCount + 1);
      expect(discovered[discovered.length - 1].deviceId).toBe('F91-WATCH-SIM-02');

      await mockBle.stopScan();
    });
  });

  describe('S2: Connection Lifecycle & Event Management', () => {
    it('should connect to existing device and report isConnected accurately', async () => {
      expect(await mockBle.isConnected(targetDeviceId)).toBe(false);

      await mockBle.connect(targetDeviceId);
      expect(await mockBle.isConnected(targetDeviceId)).toBe(true);

      await mockBle.disconnect(targetDeviceId);
      expect(await mockBle.isConnected(targetDeviceId)).toBe(false);
    });

    it('should reject connection when target device is not in available devices', async () => {
      await expect(mockBle.connect('NON-EXISTENT-DEVICE')).rejects.toThrow(/Device not found/i);
    });

    it('should fail connection when next connection error is programmed', async () => {
      mockBle.failNextConnection('BLE link establishment timed out');
      await expect(mockBle.connect(targetDeviceId)).rejects.toThrow('BLE link establishment timed out');

      // Subsequent attempt should succeed once error consumed
      await expect(mockBle.connect(targetDeviceId)).resolves.toBeUndefined();
      expect(await mockBle.isConnected(targetDeviceId)).toBe(true);
    });

    it('should trigger disconnect listeners on intentional disconnect', async () => {
      const disconnectListener = vi.fn();
      mockBle.onDisconnect(disconnectListener);

      await mockBle.connect(targetDeviceId);
      await mockBle.disconnect(targetDeviceId);

      expect(disconnectListener).toHaveBeenCalledWith(targetDeviceId);
      expect(disconnectListener).toHaveBeenCalledTimes(1);

      mockBle.removeDisconnectListener(disconnectListener);
    });

    it('should trigger disconnect listeners on simulated link loss', async () => {
      const disconnectListener = vi.fn();
      mockBle.onDisconnect(disconnectListener);

      await mockBle.connect(targetDeviceId);
      mockBle.simulateDisconnect(targetDeviceId);

      expect(await mockBle.isConnected(targetDeviceId)).toBe(false);
      expect(disconnectListener).toHaveBeenCalledWith(targetDeviceId);
    });
  });

  describe('S3: GATT Writes & Simulated Watch State Updates', () => {
    beforeEach(async () => {
      await mockBle.connect(targetDeviceId);
    });

    it('should write Time characteristic and update simulated watch state', async () => {
      const testTime = 1791169728;
      const bytes = serializeTime(testTime);

      await mockBle.writeCharacteristic(
        targetDeviceId,
        CLOCK_SERVICE_UUID,
        CLOCK_TIME_CHAR_UUID,
        bytes
      );

      const state = mockBle.getWatchState();
      expect(state.clockTime).toBe(testTime);

      const readBack = await mockBle.readCharacteristic(
        targetDeviceId,
        CLOCK_SERVICE_UUID,
        CLOCK_TIME_CHAR_UUID
      );
      expect(deserializeTime(readBack)).toBe(testTime);
    });

    it('should write Timezone characteristic and update simulated watch state', async () => {
      const testTz = -480; // UTC-8 PST
      const bytes = serializeTimezone(testTz);

      await mockBle.writeCharacteristic(
        targetDeviceId,
        CLOCK_SERVICE_UUID,
        CLOCK_TIMEZONE_CHAR_UUID,
        bytes
      );

      const state = mockBle.getWatchState();
      expect(state.clockTimezone).toBe(testTz);

      const readBack = await mockBle.readCharacteristic(
        targetDeviceId,
        CLOCK_SERVICE_UUID,
        CLOCK_TIMEZONE_CHAR_UUID
      );
      expect(deserializeTimezone(readBack)).toBe(testTz);
    });

    it('should write Time Mode characteristic and update simulated watch state', async () => {
      const mode24h = serializeTimeMode(true);

      await mockBle.writeCharacteristic(
        targetDeviceId,
        CLOCK_SERVICE_UUID,
        CLOCK_TIMEMODE_CHAR_UUID,
        mode24h
      );

      expect(mockBle.getWatchState().clockTimeMode).toBe(1);

      const mode12h = serializeTimeMode(false);
      await mockBle.writeCharacteristic(
        targetDeviceId,
        CLOCK_SERVICE_UUID,
        CLOCK_TIMEMODE_CHAR_UUID,
        mode12h
      );

      expect(mockBle.getWatchState().clockTimeMode).toBe(0);
    });

    it('should write DST characteristic and update simulated watch state', async () => {
      const dstActive = serializeDst(true);

      await mockBle.writeCharacteristic(
        targetDeviceId,
        CLOCK_SERVICE_UUID,
        CLOCK_DST_CHAR_UUID,
        dstActive
      );

      expect(mockBle.getWatchState().clockDst).toBe(1);

      const dstInactive = serializeDst(false);
      await mockBle.writeCharacteristic(
        targetDeviceId,
        CLOCK_SERVICE_UUID,
        CLOCK_DST_CHAR_UUID,
        dstInactive
      );

      expect(mockBle.getWatchState().clockDst).toBe(0);
    });

    it('should execute full 4-step sequential clock synchronization and maintain write history', async () => {
      mockBle.clearWriteHistory();

      const timeBytes = serializeTime(1700000000);
      const tzBytes = serializeTimezone(-300);
      const modeBytes = serializeTimeMode(true);
      const dstBytes = serializeDst(false);

      // Sequential write order
      await mockBle.writeCharacteristic(targetDeviceId, CLOCK_SERVICE_UUID, CLOCK_TIME_CHAR_UUID, timeBytes);
      await mockBle.writeCharacteristic(targetDeviceId, CLOCK_SERVICE_UUID, CLOCK_TIMEZONE_CHAR_UUID, tzBytes);
      await mockBle.writeCharacteristic(targetDeviceId, CLOCK_SERVICE_UUID, CLOCK_TIMEMODE_CHAR_UUID, modeBytes);
      await mockBle.writeCharacteristic(targetDeviceId, CLOCK_SERVICE_UUID, CLOCK_DST_CHAR_UUID, dstBytes);

      const history = mockBle.getWriteHistory();
      expect(history.length).toBe(4);
      expect(history[0].characteristicUuid).toBe(CLOCK_TIME_CHAR_UUID.toLowerCase());
      expect(history[1].characteristicUuid).toBe(CLOCK_TIMEZONE_CHAR_UUID.toLowerCase());
      expect(history[2].characteristicUuid).toBe(CLOCK_TIMEMODE_CHAR_UUID.toLowerCase());
      expect(history[3].characteristicUuid).toBe(CLOCK_DST_CHAR_UUID.toLowerCase());

      const state = mockBle.getWatchState();
      expect(state.clockTime).toBe(1700000000);
      expect(state.clockTimezone).toBe(-300);
      expect(state.clockTimeMode).toBe(1);
      expect(state.clockDst).toBe(0);
    });
  });

  describe('S4: Strict Zephyr RTOS Length Validation Error Handling', () => {
    beforeEach(async () => {
      await mockBle.connect(targetDeviceId);
    });

    it('rejects Time characteristic write with invalid length (not 4 bytes)', async () => {
      // 3 bytes
      await expect(
        mockBle.writeCharacteristic(
          targetDeviceId,
          CLOCK_SERVICE_UUID,
          CLOCK_TIME_CHAR_UUID,
          new Uint8Array([0, 1, 2])
        )
      ).rejects.toThrow(/BT_ATT_ERR_INVALID_ATTRIBUTE_LEN/);

      // 5 bytes
      await expect(
        mockBle.writeCharacteristic(
          targetDeviceId,
          CLOCK_SERVICE_UUID,
          CLOCK_TIME_CHAR_UUID,
          new Uint8Array([0, 1, 2, 3, 4])
        )
      ).rejects.toThrow(/BT_ATT_ERR_INVALID_ATTRIBUTE_LEN/);
    });

    it('rejects Timezone characteristic write with invalid length (not 2 bytes)', async () => {
      // 1 byte
      await expect(
        mockBle.writeCharacteristic(
          targetDeviceId,
          CLOCK_SERVICE_UUID,
          CLOCK_TIMEZONE_CHAR_UUID,
          new Uint8Array([0])
        )
      ).rejects.toThrow(/BT_ATT_ERR_INVALID_ATTRIBUTE_LEN/);

      // 3 bytes
      await expect(
        mockBle.writeCharacteristic(
          targetDeviceId,
          CLOCK_SERVICE_UUID,
          CLOCK_TIMEZONE_CHAR_UUID,
          new Uint8Array([0, 1, 2])
        )
      ).rejects.toThrow(/BT_ATT_ERR_INVALID_ATTRIBUTE_LEN/);
    });

    it('rejects Time Mode characteristic write with invalid length (not 1 byte)', async () => {
      await expect(
        mockBle.writeCharacteristic(
          targetDeviceId,
          CLOCK_SERVICE_UUID,
          CLOCK_TIMEMODE_CHAR_UUID,
          new Uint8Array(0)
        )
      ).rejects.toThrow(/BT_ATT_ERR_INVALID_ATTRIBUTE_LEN/);

      await expect(
        mockBle.writeCharacteristic(
          targetDeviceId,
          CLOCK_SERVICE_UUID,
          CLOCK_TIMEMODE_CHAR_UUID,
          new Uint8Array([1, 2])
        )
      ).rejects.toThrow(/BT_ATT_ERR_INVALID_ATTRIBUTE_LEN/);
    });

    it('rejects DST characteristic write with invalid length (not 1 byte)', async () => {
      await expect(
        mockBle.writeCharacteristic(
          targetDeviceId,
          CLOCK_SERVICE_UUID,
          CLOCK_DST_CHAR_UUID,
          new Uint8Array(0)
        )
      ).rejects.toThrow(/BT_ATT_ERR_INVALID_ATTRIBUTE_LEN/);

      await expect(
        mockBle.writeCharacteristic(
          targetDeviceId,
          CLOCK_SERVICE_UUID,
          CLOCK_DST_CHAR_UUID,
          new Uint8Array([0, 1])
        )
      ).rejects.toThrow(/BT_ATT_ERR_INVALID_ATTRIBUTE_LEN/);
    });

    it('rejects write when disconnected or targeting unknown UUIDs', async () => {
      await mockBle.disconnect(targetDeviceId);

      await expect(
        mockBle.writeCharacteristic(
          targetDeviceId,
          CLOCK_SERVICE_UUID,
          CLOCK_TIME_CHAR_UUID,
          serializeTime(1000)
        )
      ).rejects.toThrow(/not connected/i);

      await mockBle.connect(targetDeviceId);

      await expect(
        mockBle.writeCharacteristic(
          targetDeviceId,
          'fa35b2f9-7989-11eb-9439-0242ac130002', // Invalid service
          CLOCK_TIME_CHAR_UUID,
          serializeTime(1000)
        )
      ).rejects.toThrow(/Unknown service/i);

      await expect(
        mockBle.writeCharacteristic(
          targetDeviceId,
          CLOCK_SERVICE_UUID,
          'fa35b2f9-7989-11eb-9439-0242ac130002', // Invalid characteristic
          serializeTime(1000)
        )
      ).rejects.toThrow(/Unknown characteristic/i);
    });
  });

  describe('S5: Fault Injection & Stress Testing', () => {
    beforeEach(async () => {
      await mockBle.connect(targetDeviceId);
    });

    it('should inject write failure on demand', async () => {
      mockBle.failNextWrite(CLOCK_TIME_CHAR_UUID, 'GATT 133 connection congested');

      await expect(
        mockBle.writeCharacteristic(
          targetDeviceId,
          CLOCK_SERVICE_UUID,
          CLOCK_TIME_CHAR_UUID,
          serializeTime(1700000000)
        )
      ).rejects.toThrow('GATT 133 connection congested');

      // Next write should succeed
      await expect(
        mockBle.writeCharacteristic(
          targetDeviceId,
          CLOCK_SERVICE_UUID,
          CLOCK_TIME_CHAR_UUID,
          serializeTime(1700000000)
        )
      ).resolves.toBeUndefined();
    });

    it('should support simulated write latency', async () => {
      mockBle.setWriteLatency(20);
      const start = Date.now();

      await mockBle.writeCharacteristic(
        targetDeviceId,
        CLOCK_SERVICE_UUID,
        CLOCK_TIME_CHAR_UUID,
        serializeTime(1700000000)
      );

      const elapsed = Date.now() - start;
      expect(elapsed).toBeGreaterThanOrEqual(15);
    });

    it('should reset all state cleanly', () => {
      mockBle.setWatchState({ clockTime: 99999 });
      mockBle.failNextConnection('err');
      mockBle.reset();

      expect(mockBle.getWatchState().clockTime).toBe(0);
      expect(mockBle.getWriteHistory().length).toBe(0);
    });
  });

  describe('S6: CapacitorBleService Production Driver Tests', () => {
    it('should initialize and manage lifecycle with BleClient', async () => {
      const { CapacitorBleService } = await import('../src/ble/capacitorBleService');
      const { BleClient } = await import('@capacitor-community/bluetooth-le');

      const initSpy = vi.spyOn(BleClient, 'initialize').mockResolvedValue(undefined);
      const capService = new CapacitorBleService();

      await expect(capService.initialize()).resolves.toBeUndefined();
      expect(initSpy).toHaveBeenCalled();
      initSpy.mockRestore();
    });

    it('should filter scan results matching F91_Jepler and ignore unrelated devices', async () => {
      const { CapacitorBleService } = await import('../src/ble/capacitorBleService');
      const { BleClient } = await import('@capacitor-community/bluetooth-le');

      let scanHandler: ((result: any) => void) | null = null;
      vi.spyOn(BleClient, 'initialize').mockResolvedValue(undefined);
      vi.spyOn(BleClient, 'requestLEScan').mockImplementation(async (_options, callback) => {
        scanHandler = callback;
      });
      vi.spyOn(BleClient, 'stopLEScan').mockResolvedValue(undefined);

      const capService = new CapacitorBleService();
      const foundDevices: BleDevice[] = [];

      await capService.startScan((dev) => foundDevices.push(dev));
      expect(scanHandler).not.toBeNull();

      // Emit 1 matching device by name
      scanHandler!({
        device: { deviceId: 'CAP-1', name: 'F91_Jepler' },
        localName: 'F91_Jepler',
        rssi: -58,
      });

      // Emit 1 matching device by service UUID
      scanHandler!({
        device: { deviceId: 'CAP-2', name: 'Unknown', uuids: [CLOCK_SERVICE_UUID] },
        rssi: -72,
      });

      // Emit 1 non-matching device
      scanHandler!({
        device: { deviceId: 'CAP-3', name: 'Smart_Bulb' },
        localName: 'Smart_Bulb',
        rssi: -90,
      });

      expect(foundDevices.length).toBe(2);
      expect(foundDevices[0].deviceId).toBe('CAP-1');
      expect(foundDevices[1].deviceId).toBe('CAP-2');

      await capService.stopScan();
      vi.restoreAllMocks();
    });

    it('should manage connect, write, read, and disconnect with DataView conversion', async () => {
      const { CapacitorBleService } = await import('../src/ble/capacitorBleService');
      const { BleClient } = await import('@capacitor-community/bluetooth-le');

      vi.spyOn(BleClient, 'initialize').mockResolvedValue(undefined);
      let disconnectCb: ((id: string) => void) | undefined;
      vi.spyOn(BleClient, 'connect').mockImplementation(async (_id, onDisconnect) => {
        disconnectCb = onDisconnect;
      });
      vi.spyOn(BleClient, 'disconnect').mockResolvedValue(undefined);
      const writeSpy = vi.spyOn(BleClient, 'write').mockResolvedValue(undefined);
      const readSpy = vi.spyOn(BleClient, 'read').mockResolvedValue(
        new DataView(new Uint8Array([0x00, 0xf1, 0x53, 0x65]).buffer)
      );

      const capService = new CapacitorBleService();
      const listener = vi.fn();
      capService.onDisconnect(listener);

      await capService.connect('TEST-CAP-DEV');
      expect(await capService.isConnected('TEST-CAP-DEV')).toBe(true);

      // Write test
      const testBytes = new Uint8Array([0x00, 0xf1, 0x53, 0x65]);
      await capService.writeCharacteristic('TEST-CAP-DEV', CLOCK_SERVICE_UUID, CLOCK_TIME_CHAR_UUID, testBytes);
      expect(writeSpy).toHaveBeenCalled();
      const passedDataView: DataView = writeSpy.mock.calls[0][3];
      expect(passedDataView.getUint32(0, true)).toBe(1700000000);

      // Read test
      const readBytes = await capService.readCharacteristic('TEST-CAP-DEV', CLOCK_SERVICE_UUID, CLOCK_TIME_CHAR_UUID);
      expect(readSpy).toHaveBeenCalled();
      expect(Array.from(readBytes)).toEqual([0x00, 0xf1, 0x53, 0x65]);

      // Trigger disconnect from callback
      disconnectCb?.('TEST-CAP-DEV');
      expect(await capService.isConnected('TEST-CAP-DEV')).toBe(false);
      expect(listener).toHaveBeenCalledWith('TEST-CAP-DEV');

      vi.restoreAllMocks();
    });
  });
});

