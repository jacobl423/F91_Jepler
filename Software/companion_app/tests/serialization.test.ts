import { describe, it, expect } from 'vitest';
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
  createClockSyncDataFromDate,
  formatTimezoneOffset,
  bytesToHexString,
  ClockSyncData,
} from '../src/ble/gattSerializer';
import {
  CLOCK_PAYLOAD_LENGTHS,
  TIME_MODE,
  DST_MODE,
} from '../src/ble/gattConstants';

describe('GATT Serialization Core Tests', () => {
  describe('T1: Fixed Test Vectors from Specification', () => {
    it('Vector 1: US EST, 12h, Standard Time (1700000000, -300 min, 12h, Standard)', () => {
      const timestamp = 1700000000;
      const tzOffset = -300;
      const is24H = false;
      const isDst = false;

      const timeBytes = serializeTime(timestamp);
      expect(Array.from(timeBytes)).toEqual([0x00, 0xf1, 0x53, 0x65]);
      expect(timeBytes.byteLength).toBe(4);
      expect(deserializeTime(timeBytes)).toBe(timestamp);

      const tzBytes = serializeTimezone(tzOffset);
      expect(Array.from(tzBytes)).toEqual([0xd4, 0xfe]);
      expect(tzBytes.byteLength).toBe(2);
      expect(deserializeTimezone(tzBytes)).toBe(tzOffset);

      const modeBytes = serializeTimeMode(is24H);
      expect(Array.from(modeBytes)).toEqual([0x00]);
      expect(modeBytes.byteLength).toBe(1);
      expect(deserializeTimeMode(modeBytes)).toBe(false);

      const dstBytes = serializeDst(isDst);
      expect(Array.from(dstBytes)).toEqual([0x00]);
      expect(dstBytes.byteLength).toBe(1);
      expect(deserializeDst(dstBytes)).toBe(false);
    });

    it('Vector 2: US PDT, 24h, DST Active (1728000000, -420 min, 24h, DST)', () => {
      const timestamp = 1728000000;
      const tzOffset = -420;
      const is24H = true;
      const isDst = true;

      const timeBytes = serializeTime(timestamp);
      expect(Array.from(timeBytes)).toEqual([0x00, 0x30, 0xff, 0x66]);
      expect(timeBytes.byteLength).toBe(4);
      expect(deserializeTime(timeBytes)).toBe(timestamp);

      const tzBytes = serializeTimezone(tzOffset);
      expect(Array.from(tzBytes)).toEqual([0x5c, 0xfe]);
      expect(tzBytes.byteLength).toBe(2);
      expect(deserializeTimezone(tzBytes)).toBe(tzOffset);

      const modeBytes = serializeTimeMode(is24H);
      expect(Array.from(modeBytes)).toEqual([0x01]);
      expect(modeBytes.byteLength).toBe(1);
      expect(deserializeTimeMode(modeBytes)).toBe(true);

      const dstBytes = serializeDst(isDst);
      expect(Array.from(dstBytes)).toEqual([0x01]);
      expect(dstBytes.byteLength).toBe(1);
      expect(deserializeDst(dstBytes)).toBe(true);
    });

    it('Vector 3: Epoch Zero & UTC Reference (0, 0 min, 12h, Standard)', () => {
      const timestamp = 0;
      const tzOffset = 0;
      const is24H = false;
      const isDst = false;

      const timeBytes = serializeTime(timestamp);
      expect(Array.from(timeBytes)).toEqual([0x00, 0x00, 0x00, 0x00]);
      expect(deserializeTime(timeBytes)).toBe(0);

      const tzBytes = serializeTimezone(tzOffset);
      expect(Array.from(tzBytes)).toEqual([0x00, 0x00]);
      expect(deserializeTimezone(tzBytes)).toBe(0);

      const modeBytes = serializeTimeMode(is24H);
      expect(Array.from(modeBytes)).toEqual([0x00]);
      expect(deserializeTimeMode(modeBytes)).toBe(false);

      const dstBytes = serializeDst(isDst);
      expect(Array.from(dstBytes)).toEqual([0x00]);
      expect(deserializeDst(dstBytes)).toBe(false);
    });

    it('Vector 4: India Standard Time / IST (1700000000, +330 min, 24h, Standard)', () => {
      const timestamp = 1700000000;
      const tzOffset = 330; // +5:30
      const is24H = true;
      const isDst = false;

      const timeBytes = serializeTime(timestamp);
      expect(Array.from(timeBytes)).toEqual([0x00, 0xf1, 0x53, 0x65]);

      const tzBytes = serializeTimezone(tzOffset);
      expect(Array.from(tzBytes)).toEqual([0x4a, 0x01]);
      expect(deserializeTimezone(tzBytes)).toBe(330);

      const modeBytes = serializeTimeMode(is24H);
      expect(Array.from(modeBytes)).toEqual([0x01]);

      const dstBytes = serializeDst(isDst);
      expect(Array.from(dstBytes)).toEqual([0x00]);
    });

    it('Vector 5: Maximum uint32 Timestamp (4294967295, 0 min, 24h, Standard)', () => {
      const timestamp = 0xffffffff; // 4294967295
      const timeBytes = serializeTime(timestamp);
      expect(Array.from(timeBytes)).toEqual([0xff, 0xff, 0xff, 0xff]);
      expect(deserializeTime(timeBytes)).toBe(4294967295);
    });

    it('Vector 6: Dispatch Specific Timestamp (1791169728, -300 min)', () => {
      // 1791169728 is 0x6AC314C0 -> LE: C0 14 C3 6A ([192, 20, 195, 106])
      const timestamp = 1791169728;
      const timeBytes = serializeTime(timestamp);
      expect(Array.from(timeBytes)).toEqual([0xc0, 0x14, 0xc3, 0x6a]);
      expect(deserializeTime(timeBytes)).toBe(1791169728);
    });

    it('Vector 7: Historical Firmware Default (758505600, -480 min PST)', () => {
      // 758505600 is 0x2D35E080 -> LE: 80 E0 35 2D ([128, 224, 53, 45])
      const timestamp = 758505600;
      const timeBytes = serializeTime(timestamp);
      expect(Array.from(timeBytes)).toEqual([0x80, 0xe0, 0x35, 0x2d]);
      expect(deserializeTime(timeBytes)).toBe(758505600);

      // PST -480 min is 65056 (0xFE20) -> LE: 20 FE
      const tzBytes = serializeTimezone(-480);
      expect(Array.from(tzBytes)).toEqual([0x20, 0xfe]);
      expect(deserializeTimezone(tzBytes)).toBe(-480);
    });

    it('Vector 8: Additional Global Timezones (Tokyo +540, Kathmandu +345, Baker Island -720, Kiritimati +840)', () => {
      // Tokyo +540 (0x021C) -> 1C 02
      expect(Array.from(serializeTimezone(540))).toEqual([0x1c, 0x02]);
      expect(deserializeTimezone(serializeTimezone(540))).toBe(540);

      // Kathmandu +345 (0x0159) -> 59 01
      expect(Array.from(serializeTimezone(345))).toEqual([0x59, 0x01]);
      expect(deserializeTimezone(serializeTimezone(345))).toBe(345);

      // Baker Island -720 (0xFD30) -> 30 FD
      expect(Array.from(serializeTimezone(-720))).toEqual([0x30, 0xfd]);
      expect(deserializeTimezone(serializeTimezone(-720))).toBe(-720);

      // Kiritimati +840 (0x0348) -> 48 03
      expect(Array.from(serializeTimezone(840))).toEqual([0x48, 0x03]);
      expect(deserializeTimezone(serializeTimezone(840))).toBe(840);
    });

    it('Vector 9: Y2038 Rollover (2147483647 -> 0x7FFFFFFF)', () => {
      const y2038 = 2147483647;
      const timeBytes = serializeTime(y2038);
      expect(Array.from(timeBytes)).toEqual([0xff, 0xff, 0xff, 0x7f]);
      expect(deserializeTime(timeBytes)).toBe(y2038);
    });
  });

  describe('T2: Complete Payload Serialization & Deserialization', () => {
    it('should serialize and deserialize a complete ClockSyncData bundle faithfully', () => {
      const syncData: ClockSyncData = {
        timestamp: 1735689600, // 2025-01-01 00:00:00 UTC
        timezoneOffsetMinutes: -300,
        is24Hour: true,
        isDst: false,
      };

      const payload = serializeClockSyncData(syncData);
      expect(payload.timeBytes.byteLength).toBe(CLOCK_PAYLOAD_LENGTHS.TIME);
      expect(payload.timezoneBytes.byteLength).toBe(CLOCK_PAYLOAD_LENGTHS.TIMEZONE);
      expect(payload.timeModeBytes.byteLength).toBe(CLOCK_PAYLOAD_LENGTHS.TIMEMODE);
      expect(payload.dstBytes.byteLength).toBe(CLOCK_PAYLOAD_LENGTHS.DST);

      const restored = deserializeClockSyncPayload(payload);
      expect(restored).toEqual(syncData);
    });

    it('should handle number inputs for time mode and dst serialization', () => {
      expect(serializeTimeMode(1)[0]).toBe(TIME_MODE.MODE_24_HOUR);
      expect(serializeTimeMode(0)[0]).toBe(TIME_MODE.MODE_12_HOUR);
      expect(serializeTimeMode(42)[0]).toBe(TIME_MODE.MODE_24_HOUR);

      expect(serializeDst(1)[0]).toBe(DST_MODE.DAYLIGHT_SAVING);
      expect(serializeDst(0)[0]).toBe(DST_MODE.STANDARD);
      expect(serializeDst(99)[0]).toBe(DST_MODE.DAYLIGHT_SAVING);
    });
  });

  describe('T3: Strict Payload Length and Validation Checks (Zephyr Conformance)', () => {
    it('deserializeTime should throw when buffer length is not exactly 4 bytes', () => {
      expect(() => deserializeTime(new Uint8Array(0))).toThrow(/expected 4 bytes/i);
      expect(() => deserializeTime(new Uint8Array(3))).toThrow(/expected 4 bytes/i);
      expect(() => deserializeTime(new Uint8Array(5))).toThrow(/expected 4 bytes/i);
    });

    it('deserializeTimezone should throw when buffer length is not exactly 2 bytes', () => {
      expect(() => deserializeTimezone(new Uint8Array(0))).toThrow(/expected 2 bytes/i);
      expect(() => deserializeTimezone(new Uint8Array(1))).toThrow(/expected 2 bytes/i);
      expect(() => deserializeTimezone(new Uint8Array(3))).toThrow(/expected 2 bytes/i);
    });

    it('deserializeTimeMode should throw when buffer length is not exactly 1 byte', () => {
      expect(() => deserializeTimeMode(new Uint8Array(0))).toThrow(/expected 1 byte/i);
      expect(() => deserializeTimeMode(new Uint8Array(2))).toThrow(/expected 1 byte/i);
    });

    it('deserializeDst should throw when buffer length is not exactly 1 byte', () => {
      expect(() => deserializeDst(new Uint8Array(0))).toThrow(/expected 1 byte/i);
      expect(() => deserializeDst(new Uint8Array(2))).toThrow(/expected 1 byte/i);
    });

    it('serializeTime should throw RangeError for negative timestamps or out-of-range values', () => {
      expect(() => serializeTime(-1)).toThrow(RangeError);
      expect(() => serializeTime(4294967296)).toThrow(RangeError); // 0x100000000
      expect(() => serializeTime(NaN)).toThrow(RangeError);
      expect(() => serializeTime(Infinity)).toThrow(RangeError);
    });

    it('serializeTimezone should throw RangeError for values exceeding int16 bounds', () => {
      expect(() => serializeTimezone(-32769)).toThrow(RangeError);
      expect(() => serializeTimezone(32768)).toThrow(RangeError);
      expect(() => serializeTimezone(NaN)).toThrow(RangeError);
    });
  });

  describe('T4: Date and Formatting Helper Functions', () => {
    it('createClockSyncDataFromDate creates coherent ClockSyncData from a JS Date', () => {
      const now = new Date('2026-10-05T03:00:00Z');
      const data = createClockSyncDataFromDate(now, true);

      expect(data.timestamp).toBe(Math.floor(now.getTime() / 1000));
      expect(typeof data.timezoneOffsetMinutes).toBe('number');
      expect(data.is24Hour).toBe(true);
      expect(typeof data.isDst).toBe('boolean');
    });

    it('formatTimezoneOffset formats minutes into ISO-style UTC offset string', () => {
      expect(formatTimezoneOffset(-300)).toBe('UTC-05:00');
      expect(formatTimezoneOffset(-480)).toBe('UTC-08:00');
      expect(formatTimezoneOffset(0)).toBe('UTC+00:00');
      expect(formatTimezoneOffset(330)).toBe('UTC+05:30');
      expect(formatTimezoneOffset(540)).toBe('UTC+09:00');
      expect(formatTimezoneOffset(345)).toBe('UTC+05:45');
    });

    it('bytesToHexString formats binary buffers into clean hex sequences', () => {
      const bytes = new Uint8Array([0xc0, 0x6a, 0xc6, 0x6a]);
      expect(bytesToHexString(bytes)).toBe('C0 6A C6 6A');

      const single = new Uint8Array([0x01]);
      expect(bytesToHexString(single)).toBe('01');
    });
  });
});
