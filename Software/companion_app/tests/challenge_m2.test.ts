import { describe, it, expect, vi, beforeEach } from 'vitest';
import {
  serializeTime,
  deserializeTime,
  serializeTimezone,
  deserializeTimezone,
  serializeTimeMode,
  deserializeTimeMode,
  serializeDst,
  deserializeDst,
  serializeClockSyncData,
  deserializeClockSyncPayload,
  formatTimezoneOffset,
  bytesToHexString,
  ClockSyncData,
} from '../src/ble/gattSerializer';
import {
  CLOCK_SERVICE_UUID,
  CLOCK_TIME_CHAR_UUID,
  CLOCK_TIMEZONE_CHAR_UUID,
  CLOCK_TIMEMODE_CHAR_UUID,
  CLOCK_DST_CHAR_UUID,
  CLOCK_PAYLOAD_LENGTHS,
  BT_ATT_ERR_INVALID_OFFSET,
  TIME_MODE,
  DST_MODE,
  F91_DEVICE_NAME,
} from '../src/ble/gattConstants';
import { MockBleService } from '../src/ble/mockBleService';
import { CapacitorBleService } from '../src/ble/capacitorBleService';
import { BleDevice } from '../src/ble/bleClientInterface';
import { BleClient, ScanResult } from '@capacitor-community/bluetooth-le';

describe('Challenger M2 Empirical Adversarial Stress Suite', () => {
  describe('C0: Protocol Constants and GATT Specification Conformance', () => {
    it('matches Zephyr firmware payload length constraints', () => {
      expect(CLOCK_PAYLOAD_LENGTHS.TIME).toBe(4);
      expect(CLOCK_PAYLOAD_LENGTHS.TIMEZONE).toBe(2);
      expect(CLOCK_PAYLOAD_LENGTHS.TIMEMODE).toBe(1);
      expect(CLOCK_PAYLOAD_LENGTHS.DST).toBe(1);
      expect(BT_ATT_ERR_INVALID_OFFSET).toBe(0x07);
    });

    it('matches Zephyr firmware mode enumerations', () => {
      expect(TIME_MODE.MODE_12_HOUR).toBe(0);
      expect(TIME_MODE.MODE_24_HOUR).toBe(1);
      expect(DST_MODE.STANDARD).toBe(0);
      expect(DST_MODE.DAYLIGHT_SAVING).toBe(1);
    });
  });

  describe('C1: Serialization Boundary Conditions & Little-Endian Oracles', () => {
    it('accurately encodes and decodes Epoch 0 (0x00000000)', () => {
      const bytes = serializeTime(0);
      expect(bytes.byteLength).toBe(CLOCK_PAYLOAD_LENGTHS.TIME);
      expect(Array.from(bytes)).toEqual([0x00, 0x00, 0x00, 0x00]);
      expect(deserializeTime(bytes)).toBe(0);
      expect(bytesToHexString(bytes)).toBe('00 00 00 00');
    });

    it('accurately encodes and decodes maximum uint32 (0xFFFFFFFF = 4294967295)', () => {
      const maxUint32 = 0xffffffff;
      const bytes = serializeTime(maxUint32);
      expect(bytes.byteLength).toBe(CLOCK_PAYLOAD_LENGTHS.TIME);
      expect(Array.from(bytes)).toEqual([0xff, 0xff, 0xff, 0xff]);
      expect(deserializeTime(bytes)).toBe(maxUint32);
      expect(bytesToHexString(bytes)).toBe('FF FF FF FF');
    });

    it('accurately encodes and decodes 32-bit signed overflow boundary (0x80000000 = 2147483648)', () => {
      const val = 0x80000000;
      const bytes = serializeTime(val);
      expect(bytes.byteLength).toBe(4);
      // In little-endian: low byte first -> 0x00, 0x00, 0x00, 0x80
      expect(Array.from(bytes)).toEqual([0x00, 0x00, 0x00, 0x80]);
      expect(deserializeTime(bytes)).toBe(val);
      expect(bytesToHexString(bytes)).toBe('00 00 00 80');
    });

    it('accurately encodes and decodes Y2038 boundary (0x7FFFFFFF = 2147483647)', () => {
      const val = 0x7fffffff;
      const bytes = serializeTime(val);
      expect(bytes.byteLength).toBe(4);
      // In little-endian: 0xFF, 0xFF, 0xFF, 0x7F
      expect(Array.from(bytes)).toEqual([0xff, 0xff, 0xff, 0x7f]);
      expect(deserializeTime(bytes)).toBe(val);
      expect(bytesToHexString(bytes)).toBe('FF FF FF 7F');
    });

    it('truncates floating-point timestamps using Math.floor', () => {
      const floatTime = 1700000000.875;
      const bytes = serializeTime(floatTime);
      expect(deserializeTime(bytes)).toBe(1700000000);
    });

    it('rejects invalid or out-of-range timestamps with RangeError', () => {
      const invalidValues = [-1, -100, 4294967296, 5000000000, NaN, Infinity, -Infinity];
      for (const val of invalidValues) {
        expect(() => serializeTime(val), `Should reject ${val}`).toThrow(RangeError);
      }
    });

    it('empirically verifies Little-Endian byte decomposition for arbitrary uint32 test vectors', () => {
      const testCases = [
        { val: 0x12345678, expected: [0x78, 0x56, 0x34, 0x12] },
        { val: 0xaabbccdd, expected: [0xdd, 0xcc, 0xbb, 0xaa] },
        { val: 0x00010203, expected: [0x03, 0x02, 0x01, 0x00] },
        { val: 0xdeadbeef, expected: [0xef, 0xbe, 0xad, 0xde] },
      ];

      for (const { val, expected } of testCases) {
        const bytes = serializeTime(val);
        expect(Array.from(bytes)).toEqual(expected);
        expect(bytes[0]).toBe(val & 0xff);
        expect(bytes[1]).toBe((val >>> 8) & 0xff);
        expect(bytes[2]).toBe((val >>> 16) & 0xff);
        expect(bytes[3]).toBe((val >>> 24) & 0xff);
        expect(deserializeTime(bytes)).toBe(val);
      }
    });

    it('fuzzes 10,000 randomized uint32 timestamps through serializeTime and deserializeTime', () => {
      for (let i = 0; i < 10000; i++) {
        const sample = Math.floor(Math.random() * 4294967296);
        const encoded = serializeTime(sample);
        const decoded = deserializeTime(encoded);
        expect(decoded).toBe(sample);
      }
    });

    it('exhaustively verifies all 65,536 int16 timezone offsets against signed two-complement Little-Endian oracle', () => {
      // Sweep every valid int16 value from -32768 to +32767
      for (let offset = -32768; offset <= 32767; offset++) {
        const bytes = serializeTimezone(offset);
        expect(bytes.byteLength).toBe(CLOCK_PAYLOAD_LENGTHS.TIMEZONE);

        // Compute expected signed 16-bit two's complement bit pattern
        const bitPattern = offset < 0 ? (65536 + offset) : offset;
        const expectedLow = bitPattern & 0xff;
        const expectedHigh = (bitPattern >> 8) & 0xff;

        expect(bytes[0]).toBe(expectedLow);
        expect(bytes[1]).toBe(expectedHigh);

        const decoded = deserializeTimezone(bytes);
        expect(decoded).toBe(offset);
      }
    });

    it('verifies fractional and negative timezone offsets across real-world global boundaries', () => {
      const timezones = [
        // Fractional positive
        { name: 'India (IST +5:30)', minutes: 330, expectedBytes: [0x4a, 0x01], str: 'UTC+05:30' },
        { name: 'Nepal (NPT +5:45)', minutes: 345, expectedBytes: [0x59, 0x01], str: 'UTC+05:45' },
        { name: 'Eucla (CWST +8:45)', minutes: 525, expectedBytes: [0x0d, 0x02], str: 'UTC+08:45' },
        { name: 'Adelaide (ACST +9:30)', minutes: 570, expectedBytes: [0x3a, 0x02], str: 'UTC+09:30' },
        { name: 'Chatham (CHAST +12:45)', minutes: 765, expectedBytes: [0xfd, 0x02], str: 'UTC+12:45' },
        { name: 'Kiritimati (LINT +14:00)', minutes: 840, expectedBytes: [0x48, 0x03], str: 'UTC+14:00' },

        // Fractional negative
        { name: 'Newfoundland (NST -3:30)', minutes: -210, expectedBytes: [0x2e, 0xff], str: 'UTC-03:30' },
        { name: 'Marquesas Islands (MART -9:30)', minutes: -570, expectedBytes: [0xc6, 0xfd], str: 'UTC-09:30' },

        // Whole hour extremes
        { name: 'Baker Island (-12:00)', minutes: -720, expectedBytes: [0x30, 0xfd], str: 'UTC-12:00' },
        { name: 'UTC Zero (GMT 0:00)', minutes: 0, expectedBytes: [0x00, 0x00], str: 'UTC+00:00' },
        { name: 'US EST (-5:00)', minutes: -300, expectedBytes: [0xd4, 0xfe], str: 'UTC-05:00' },
        { name: 'US PST (-8:00)', minutes: -480, expectedBytes: [0x20, 0xfe], str: 'UTC-08:00' },

        // Int16 Limits
        { name: 'Int16 Minimum (-32768 min)', minutes: -32768, expectedBytes: [0x00, 0x80], str: 'UTC-546:08' },
        { name: 'Int16 Maximum (+32767 min)', minutes: 32767, expectedBytes: [0xff, 0x7f], str: 'UTC+546:07' },
      ];

      for (const tz of timezones) {
        const bytes = serializeTimezone(tz.minutes);
        expect(Array.from(bytes), `Failed on ${tz.name}`).toEqual(tz.expectedBytes);
        expect(deserializeTimezone(bytes)).toBe(tz.minutes);
        expect(formatTimezoneOffset(tz.minutes)).toBe(tz.str);
      }
    });

    it('rejects timezone offsets outside int16 range [-32768, 32767] with RangeError', () => {
      const invalidOffsets = [-32769, -50000, 32768, 65536, NaN, Infinity, -Infinity];
      for (const off of invalidOffsets) {
        expect(() => serializeTimezone(off), `Should reject ${off}`).toThrow(RangeError);
      }
    });

    it('correctly handles Uint8Array slices with non-zero byteOffsets (subarrays)', () => {
      // Pack composite payload: 2 padding + 4 Time + 2 TZ + 1 Mode + 1 DST + 2 padding
      const raw = new Uint8Array(12);
      raw.set([0xaa, 0xbb], 0); // padding
      raw.set([0x00, 0xf1, 0x53, 0x65], 2); // Time: 1700000000
      raw.set([0xd4, 0xfe], 6); // TZ: -300
      raw.set([0x01], 8); // Mode: 24h
      raw.set([0x01], 9); // DST: true
      raw.set([0xcc, 0xdd], 10); // padding

      const timeSlice = raw.subarray(2, 6);
      const tzSlice = raw.subarray(6, 8);
      const modeSlice = raw.subarray(8, 9);
      const dstSlice = raw.subarray(9, 10);

      expect(timeSlice.byteOffset).toBe(2);
      expect(tzSlice.byteOffset).toBe(6);
      expect(modeSlice.byteOffset).toBe(8);
      expect(dstSlice.byteOffset).toBe(9);

      expect(deserializeTime(timeSlice)).toBe(1700000000);
      expect(deserializeTimezone(tzSlice)).toBe(-300);
      expect(deserializeTimeMode(modeSlice)).toBe(true);
      expect(deserializeDst(dstSlice)).toBe(true);
    });

    it('faithfully serializes and deserializes extreme composite ClockSyncData structures', () => {
      const extremeVectors: ClockSyncData[] = [
        { timestamp: 0, timezoneOffsetMinutes: -32768, is24Hour: false, isDst: false },
        { timestamp: 0xffffffff, timezoneOffsetMinutes: 32767, is24Hour: true, isDst: true },
        { timestamp: 1791169728, timezoneOffsetMinutes: 330, is24Hour: true, isDst: false },
        { timestamp: 758505600, timezoneOffsetMinutes: -210, is24Hour: false, isDst: true },
      ];

      for (const vector of extremeVectors) {
        const payload = serializeClockSyncData(vector);
        expect(payload.timeBytes.byteLength).toBe(CLOCK_PAYLOAD_LENGTHS.TIME);
        expect(payload.timezoneBytes.byteLength).toBe(CLOCK_PAYLOAD_LENGTHS.TIMEZONE);
        expect(payload.timeModeBytes.byteLength).toBe(CLOCK_PAYLOAD_LENGTHS.TIMEMODE);
        expect(payload.dstBytes.byteLength).toBe(CLOCK_PAYLOAD_LENGTHS.DST);

        const restored = deserializeClockSyncPayload(payload);
        expect(restored).toEqual(vector);
      }
    });
  });

  describe('C2: Strict Zephyr RTOS GATT Length Enforcement', () => {
    it('rejects Time characteristic write buffers of any length other than 4', () => {
      const invalidLengths = [0, 1, 2, 3, 5, 6, 7, 8, 16, 64];
      for (const len of invalidLengths) {
        const buf = new Uint8Array(len);
        expect(() => deserializeTime(buf), `Should reject len ${len}`).toThrow(/Invalid Time payload length/);
      }
    });

    it('rejects Timezone characteristic write buffers of any length other than 2', () => {
      const invalidLengths = [0, 1, 3, 4, 5, 8];
      for (const len of invalidLengths) {
        const buf = new Uint8Array(len);
        expect(() => deserializeTimezone(buf), `Should reject len ${len}`).toThrow(/Invalid Timezone payload length/);
      }
    });

    it('rejects Time Mode characteristic write buffers of any length other than 1', () => {
      const invalidLengths = [0, 2, 3, 4, 8];
      for (const len of invalidLengths) {
        const buf = new Uint8Array(len);
        expect(() => deserializeTimeMode(buf), `Should reject len ${len}`).toThrow(/Invalid Time Mode payload length/);
      }
    });

    it('rejects DST characteristic write buffers of any length other than 1', () => {
      const invalidLengths = [0, 2, 3, 4, 8];
      for (const len of invalidLengths) {
        const buf = new Uint8Array(len);
        expect(() => deserializeDst(buf), `Should reject len ${len}`).toThrow(/Invalid DST payload length/);
      }
    });
  });

  describe('C3: MockBleService Fault Injection, Write Sequence & Memory Isolation', () => {
    let mock: MockBleService;
    const deviceId = 'F91-WATCH-SIM-01';

    beforeEach(async () => {
      mock = new MockBleService();
      await mock.connect(deviceId);
    });

    it('strictly validates write lengths conforming to Zephyr BT_ATT_ERR_INVALID_OFFSET (0x07)', async () => {
      // 0 bytes, 3 bytes, 5 bytes for Time
      await expect(
        mock.writeCharacteristic(deviceId, CLOCK_SERVICE_UUID, CLOCK_TIME_CHAR_UUID, new Uint8Array(0))
      ).rejects.toThrow(new RegExp(`0x${BT_ATT_ERR_INVALID_OFFSET.toString(16)}`));

      await expect(
        mock.writeCharacteristic(deviceId, CLOCK_SERVICE_UUID, CLOCK_TIME_CHAR_UUID, new Uint8Array([1, 2, 3]))
      ).rejects.toThrow(new RegExp(`0x${BT_ATT_ERR_INVALID_OFFSET.toString(16)}`));

      await expect(
        mock.writeCharacteristic(deviceId, CLOCK_SERVICE_UUID, CLOCK_TIME_CHAR_UUID, new Uint8Array([1, 2, 3, 4, 5]))
      ).rejects.toThrow(new RegExp(`0x${BT_ATT_ERR_INVALID_OFFSET.toString(16)}`));

      // 0 bytes, 1 byte, 3 bytes for Timezone
      await expect(
        mock.writeCharacteristic(deviceId, CLOCK_SERVICE_UUID, CLOCK_TIMEZONE_CHAR_UUID, new Uint8Array(0))
      ).rejects.toThrow(new RegExp(`0x${BT_ATT_ERR_INVALID_OFFSET.toString(16)}`));

      await expect(
        mock.writeCharacteristic(deviceId, CLOCK_SERVICE_UUID, CLOCK_TIMEZONE_CHAR_UUID, new Uint8Array([1]))
      ).rejects.toThrow(new RegExp(`0x${BT_ATT_ERR_INVALID_OFFSET.toString(16)}`));

      await expect(
        mock.writeCharacteristic(deviceId, CLOCK_SERVICE_UUID, CLOCK_TIMEZONE_CHAR_UUID, new Uint8Array([1, 2, 3]))
      ).rejects.toThrow(new RegExp(`0x${BT_ATT_ERR_INVALID_OFFSET.toString(16)}`));

      // 0 bytes, 2 bytes for Time Mode
      await expect(
        mock.writeCharacteristic(deviceId, CLOCK_SERVICE_UUID, CLOCK_TIMEMODE_CHAR_UUID, new Uint8Array(0))
      ).rejects.toThrow(new RegExp(`0x${BT_ATT_ERR_INVALID_OFFSET.toString(16)}`));

      await expect(
        mock.writeCharacteristic(deviceId, CLOCK_SERVICE_UUID, CLOCK_TIMEMODE_CHAR_UUID, new Uint8Array([1, 2]))
      ).rejects.toThrow(new RegExp(`0x${BT_ATT_ERR_INVALID_OFFSET.toString(16)}`));

      // 0 bytes, 2 bytes for DST
      await expect(
        mock.writeCharacteristic(deviceId, CLOCK_SERVICE_UUID, CLOCK_DST_CHAR_UUID, new Uint8Array(0))
      ).rejects.toThrow(new RegExp(`0x${BT_ATT_ERR_INVALID_OFFSET.toString(16)}`));

      await expect(
        mock.writeCharacteristic(deviceId, CLOCK_SERVICE_UUID, CLOCK_DST_CHAR_UUID, new Uint8Array([1, 2]))
      ).rejects.toThrow(new RegExp(`0x${BT_ATT_ERR_INVALID_OFFSET.toString(16)}`));
    });

    it('enforces memory isolation: mutating caller buffers after write does not corrupt GATT database or writeHistory', async () => {
      mock.clearWriteHistory();
      const mutableBuffer = new Uint8Array([0x00, 0xf1, 0x53, 0x65]); // 1700000000

      await mock.writeCharacteristic(deviceId, CLOCK_SERVICE_UUID, CLOCK_TIME_CHAR_UUID, mutableBuffer);

      // Mutate original buffer
      mutableBuffer[0] = 0xff;
      mutableBuffer[1] = 0xff;
      mutableBuffer[2] = 0xff;
      mutableBuffer[3] = 0xff;

      // Verify writeHistory was defensively copied
      const history = mock.getWriteHistory();
      expect(Array.from(history[0].data)).toEqual([0x00, 0xf1, 0x53, 0x65]);

      // Verify GATT database was defensively copied
      const charVal = mock.getCharacteristicValue(CLOCK_TIME_CHAR_UUID);
      expect(Array.from(charVal!)).toEqual([0x00, 0xf1, 0x53, 0x65]);

      // Verify readCharacteristic was defensively copied
      const readVal = await mock.readCharacteristic(deviceId, CLOCK_SERVICE_UUID, CLOCK_TIME_CHAR_UUID);
      expect(Array.from(readVal)).toEqual([0x00, 0xf1, 0x53, 0x65]);

      // Mutating readVal does not corrupt internal database
      readVal[0] = 0x99;
      const reReadVal = await mock.readCharacteristic(deviceId, CLOCK_SERVICE_UUID, CLOCK_TIME_CHAR_UUID);
      expect(reReadVal[0]).toBe(0x00);
    });

    it('verifies targeted characteristic fault injection: only the specified characteristic fails', async () => {
      mock.clearWriteHistory();
      // Inject failure specifically for Timezone write
      mock.failNextWrite(CLOCK_TIMEZONE_CHAR_UUID, 'Targeted GATT Error 133 on Timezone');

      // Writing Time should succeed
      await expect(
        mock.writeCharacteristic(deviceId, CLOCK_SERVICE_UUID, CLOCK_TIME_CHAR_UUID, serializeTime(1700000000))
      ).resolves.toBeUndefined();

      // Writing Timezone must fail
      await expect(
        mock.writeCharacteristic(deviceId, CLOCK_SERVICE_UUID, CLOCK_TIMEZONE_CHAR_UUID, serializeTimezone(-300))
      ).rejects.toThrow('Targeted GATT Error 133 on Timezone');

      // Subsequent write to Timezone should now succeed (fault was consumed)
      await expect(
        mock.writeCharacteristic(deviceId, CLOCK_SERVICE_UUID, CLOCK_TIMEZONE_CHAR_UUID, serializeTimezone(-300))
      ).resolves.toBeUndefined();

      expect(mock.getWatchState().clockTimezone).toBe(-300);
    });

    it('handles unexpected disconnection during active session and rejects subsequent writes', async () => {
      expect(await mock.isConnected(deviceId)).toBe(true);

      const disconnectSpy = vi.fn();
      mock.onDisconnect(disconnectSpy);

      // Simulate abrupt link loss
      mock.simulateDisconnect(deviceId);

      expect(await mock.isConnected(deviceId)).toBe(false);
      expect(disconnectSpy).toHaveBeenCalledWith(deviceId);

      // Attempting to write while disconnected must fail
      await expect(
        mock.writeCharacteristic(deviceId, CLOCK_SERVICE_UUID, CLOCK_TIME_CHAR_UUID, serializeTime(1700000000))
      ).rejects.toThrow(/Device is not connected/i);

      // Attempting to read while disconnected must fail
      await expect(
        mock.readCharacteristic(deviceId, CLOCK_SERVICE_UUID, CLOCK_TIME_CHAR_UUID)
      ).rejects.toThrow(/Device is not connected/i);
    });

    it('survives throwing disconnect listeners without breaking other listeners', async () => {
      const consoleErrorSpy = vi.spyOn(console, 'error').mockImplementation(() => {});
      const brokenListener = vi.fn().mockImplementation(() => {
        throw new Error('Exploding disconnect listener');
      });
      const healthyListener = vi.fn();

      mock.onDisconnect(brokenListener);
      mock.onDisconnect(healthyListener);

      // Trigger disconnect
      mock.simulateDisconnect(deviceId);

      expect(brokenListener).toHaveBeenCalledWith(deviceId);
      expect(healthyListener).toHaveBeenCalledWith(deviceId);
      expect(consoleErrorSpy).toHaveBeenCalled();

      // Clean up
      mock.removeDisconnectListener(brokenListener);
      mock.removeDisconnectListener(healthyListener);
      consoleErrorSpy.mockRestore();
    });

    it('preserves chronological write sequence and payload fidelity across rapid multi-characteristic writes', async () => {
      mock.clearWriteHistory();

      const writes = [
        { char: CLOCK_TIME_CHAR_UUID, data: serializeTime(1700000000) },
        { char: CLOCK_TIMEZONE_CHAR_UUID, data: serializeTimezone(-300) },
        { char: CLOCK_TIMEMODE_CHAR_UUID, data: serializeTimeMode(true) },
        { char: CLOCK_DST_CHAR_UUID, data: serializeDst(false) },
        { char: CLOCK_TIME_CHAR_UUID, data: serializeTime(1700000001) },
      ];

      for (const w of writes) {
        await mock.writeCharacteristic(deviceId, CLOCK_SERVICE_UUID, w.char, w.data);
      }

      const history = mock.getWriteHistory();
      expect(history.length).toBe(5);
      expect(history.map((h) => h.characteristicUuid)).toEqual([
        CLOCK_TIME_CHAR_UUID.toLowerCase(),
        CLOCK_TIMEZONE_CHAR_UUID.toLowerCase(),
        CLOCK_TIMEMODE_CHAR_UUID.toLowerCase(),
        CLOCK_DST_CHAR_UUID.toLowerCase(),
        CLOCK_TIME_CHAR_UUID.toLowerCase(),
      ]);

      expect(mock.getWatchState().clockTime).toBe(1700000001);
      expect(mock.getWatchState().clockTimezone).toBe(-300);
      expect(mock.getWatchState().clockTimeMode).toBe(1);
      expect(mock.getWatchState().clockDst).toBe(0);
    });
  });

  describe('C4: Dual-Criteria Peripheral Discovery & Case-Insensitive Matching', () => {
    let mock: MockBleService;

    beforeEach(() => {
      mock = new MockBleService();
    });

    it('matches peripherals by localName F91_Jepler regardless of service list in MockBleService', async () => {
      mock.setAvailableDevices([
        { deviceId: 'DEV-NAME-ONLY', name: F91_DEVICE_NAME, rssi: -60 },
      ]);

      const found: BleDevice[] = [];
      await mock.startScan((dev) => found.push(dev));

      expect(found.length).toBe(1);
      expect(found[0].deviceId).toBe('DEV-NAME-ONLY');
      await mock.stopScan();
    });

    it('matches peripherals by Clock Service UUID with uppercase or lowercase letters in MockBleService', async () => {
      mock.setAvailableDevices([
        {
          deviceId: 'DEV-LOWER-UUID',
          name: 'Watch_A',
          services: ['fa35b2f0-7989-11eb-9439-0242ac130002'],
          rssi: -65,
        },
        {
          deviceId: 'DEV-UPPER-UUID',
          name: 'Watch_B',
          services: ['FA35B2F0-7989-11EB-9439-0242AC130002'],
          rssi: -70,
        },
        {
          deviceId: 'DEV-IRRELEVANT',
          name: 'Smart_Lamp',
          services: ['0000180a-0000-1000-8000-00805f9b34fb'],
          rssi: -80,
        },
      ]);

      const found: BleDevice[] = [];
      await mock.startScan((dev) => found.push(dev));

      expect(found.length).toBe(2);
      expect(found.map((d) => d.deviceId)).toEqual(['DEV-LOWER-UUID', 'DEV-UPPER-UUID']);
      await mock.stopScan();
    });

    it('matches peripherals by uppercase Clock Service UUID in CapacitorBleService scan callback', async () => {
      const capService = new CapacitorBleService();
      let capturedCallback: ((result: ScanResult) => void) | undefined;

      vi.spyOn(BleClient, 'initialize').mockResolvedValue(undefined);
      vi.spyOn(BleClient, 'requestLEScan').mockImplementation(async (_options, callback) => {
        capturedCallback = callback;
      });
      vi.spyOn(BleClient, 'stopLEScan').mockResolvedValue(undefined);

      const discovered: BleDevice[] = [];
      await capService.startScan((dev) => discovered.push(dev));

      expect(capturedCallback).toBeDefined();

      // Emit scan result with uppercase UUID
      capturedCallback!({
        device: {
          deviceId: 'NATIVE-DEV-UPPER',
          name: 'Anonymous Watch',
          uuids: ['FA35B2F0-7989-11EB-9439-0242AC130002'],
        },
        rssi: -66,
      });

      expect(discovered.length).toBe(1);
      expect(discovered[0].deviceId).toBe('NATIVE-DEV-UPPER');

      await capService.stopScan();
      vi.restoreAllMocks();
    });
  });
});
