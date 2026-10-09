/**
 * GATT Serialization & Deserialization Engine for F91_Jepler Clock Service.
 *
 * Implements strict binary framing conforming directly to Zephyr RTOS clock_service.c:
 * - Time: 4 bytes, uint32 little-endian Unix epoch seconds
 * - Timezone: 2 bytes, signed int16 little-endian minutes from UTC (two's complement)
 * - Time Mode: 1 byte, uint8 (0 = 12h, 1 = 24h)
 * - DST: 1 byte, uint8 (0 = Standard, 1 = Daylight Saving Time)
 */

import {
  CLOCK_PAYLOAD_LENGTHS,
  TIME_MODE,
  DST_MODE,
} from './gattConstants';

export interface ClockSyncData {
  /** Unix epoch timestamp in seconds */
  timestamp: number;
  /** Effective signed timezone offset in minutes from UTC, including DST (e.g., -300 for UTC-5 EST) */
  timezoneOffsetMinutes: number;
  /** Display format: false for 12-hour, true for 24-hour */
  is24Hour: boolean;
  /** Descriptive Daylight Saving Time status (never adds an hour): false for Standard, true for DST */
  isDst: boolean;
}

export interface SerializedClockPayload {
  /** 4-byte little-endian uint32 */
  timeBytes: Uint8Array;
  /** 2-byte little-endian signed int16 (as uint16 bit-pattern) */
  timezoneBytes: Uint8Array;
  /** 1-byte uint8 (0 or 1) */
  timeModeBytes: Uint8Array;
  /** 1-byte uint8 (0 or 1) */
  dstBytes: Uint8Array;
}

/**
 * Serializes a Unix epoch timestamp (seconds) into 4 bytes little-endian uint32.
 * Validates timestamp is an integer between 0 and 0xFFFFFFFF (4,294,967,295).
 */
export function serializeTime(timestamp: number): Uint8Array {
  if (
    typeof timestamp !== 'number' ||
    Number.isNaN(timestamp) ||
    !Number.isFinite(timestamp) ||
    timestamp < 0 ||
    timestamp > 0xffffffff
  ) {
    throw new RangeError(
      `Timestamp out of bounds: expected uint32 between 0 and 4294967295, got ${timestamp}`
    );
  }

  const buffer = new Uint8Array(CLOCK_PAYLOAD_LENGTHS.TIME);
  const view = new DataView(buffer.buffer);
  view.setUint32(0, Math.floor(timestamp), true); // true = Little-Endian
  return buffer;
}

/**
 * Deserializes a 4-byte little-endian uint32 buffer into Unix epoch seconds.
 * Strictly verifies buffer length is 4 bytes, matching Zephyr clock_service.c.
 */
export function deserializeTime(bytes: Uint8Array): number {
  if (bytes.byteLength !== CLOCK_PAYLOAD_LENGTHS.TIME) {
    throw new Error(
      `Invalid Time payload length: expected ${CLOCK_PAYLOAD_LENGTHS.TIME} bytes, got ${bytes.byteLength}`
    );
  }

  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  return view.getUint32(0, true);
}

/**
 * Serializes timezone offset in minutes from UTC into 2 bytes little-endian signed int16.
 * (e.g., -300 minutes -> 0xFED4 -> [0xD4, 0xFE]).
 */
export function serializeTimezone(offsetMinutes: number): Uint8Array {
  if (
    typeof offsetMinutes !== 'number' ||
    Number.isNaN(offsetMinutes) ||
    !Number.isFinite(offsetMinutes) ||
    offsetMinutes < -32768 ||
    offsetMinutes > 32767
  ) {
    throw new RangeError(
      `Timezone offset out of bounds: expected int16 between -32768 and 32767, got ${offsetMinutes}`
    );
  }

  const buffer = new Uint8Array(CLOCK_PAYLOAD_LENGTHS.TIMEZONE);
  const view = new DataView(buffer.buffer);
  view.setInt16(0, Math.round(offsetMinutes), true); // true = Little-Endian
  return buffer;
}

/**
 * Deserializes a 2-byte little-endian signed int16 buffer into minutes offset from UTC.
 * Strictly verifies buffer length is 2 bytes.
 */
export function deserializeTimezone(bytes: Uint8Array): number {
  if (bytes.byteLength !== CLOCK_PAYLOAD_LENGTHS.TIMEZONE) {
    throw new Error(
      `Invalid Timezone payload length: expected ${CLOCK_PAYLOAD_LENGTHS.TIMEZONE} bytes, got ${bytes.byteLength}`
    );
  }

  const view = new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength);
  return view.getInt16(0, true);
}

/**
 * Serializes time format mode into 1-byte uint8.
 * 0 = 12-hour mode, 1 = 24-hour mode.
 */
export function serializeTimeMode(is24Hour: boolean | number): Uint8Array {
  const buffer = new Uint8Array(CLOCK_PAYLOAD_LENGTHS.TIMEMODE);
  if (typeof is24Hour === 'boolean') {
    buffer[0] = is24Hour ? TIME_MODE.MODE_24_HOUR : TIME_MODE.MODE_12_HOUR;
  } else if (typeof is24Hour === 'number') {
    // Sanitize non-zero to 1 or 0
    buffer[0] = is24Hour !== 0 ? TIME_MODE.MODE_24_HOUR : TIME_MODE.MODE_12_HOUR;
  } else {
    buffer[0] = TIME_MODE.MODE_12_HOUR;
  }
  return buffer;
}

/**
 * Deserializes a 1-byte buffer into 12h/24h mode flag.
 * Strictly verifies buffer length is 1 byte.
 */
export function deserializeTimeMode(bytes: Uint8Array): boolean {
  if (bytes.byteLength !== CLOCK_PAYLOAD_LENGTHS.TIMEMODE) {
    throw new Error(
      `Invalid Time Mode payload length: expected ${CLOCK_PAYLOAD_LENGTHS.TIMEMODE} byte, got ${bytes.byteLength}`
    );
  }

  return bytes[0] === TIME_MODE.MODE_24_HOUR;
}

/**
 * Serializes Daylight Saving Time status into 1-byte uint8.
 * 0 = Standard Time, 1 = Daylight Saving Time active.
 */
export function serializeDst(isDst: boolean | number): Uint8Array {
  const buffer = new Uint8Array(CLOCK_PAYLOAD_LENGTHS.DST);
  if (typeof isDst === 'boolean') {
    buffer[0] = isDst ? DST_MODE.DAYLIGHT_SAVING : DST_MODE.STANDARD;
  } else if (typeof isDst === 'number') {
    buffer[0] = isDst !== 0 ? DST_MODE.DAYLIGHT_SAVING : DST_MODE.STANDARD;
  } else {
    buffer[0] = DST_MODE.STANDARD;
  }
  return buffer;
}

/**
 * Deserializes a 1-byte buffer into DST active flag.
 * Strictly verifies buffer length is 1 byte.
 */
export function deserializeDst(bytes: Uint8Array): boolean {
  if (bytes.byteLength !== CLOCK_PAYLOAD_LENGTHS.DST) {
    throw new Error(
      `Invalid DST payload length: expected ${CLOCK_PAYLOAD_LENGTHS.DST} byte, got ${bytes.byteLength}`
    );
  }

  return bytes[0] === DST_MODE.DAYLIGHT_SAVING;
}

/**
 * Serializes complete ClockSyncData into 4 distinct GATT payload byte arrays.
 */
export function serializeClockSyncData(data: ClockSyncData): SerializedClockPayload {
  return {
    timeBytes: serializeTime(data.timestamp),
    timezoneBytes: serializeTimezone(data.timezoneOffsetMinutes),
    timeModeBytes: serializeTimeMode(data.is24Hour),
    dstBytes: serializeDst(data.isDst),
  };
}

/**
 * Deserializes a complete SerializedClockPayload back into structured ClockSyncData.
 */
export function deserializeClockSyncPayload(payload: SerializedClockPayload): ClockSyncData {
  return {
    timestamp: deserializeTime(payload.timeBytes),
    timezoneOffsetMinutes: deserializeTimezone(payload.timezoneBytes),
    is24Hour: deserializeTimeMode(payload.timeModeBytes),
    isDst: deserializeDst(payload.dstBytes),
  };
}

/**
 * Determines whether a given Date is currently in Daylight Saving Time in the local timezone.
 */
export function isDateInDst(date: Date = new Date()): boolean {
  const jan = new Date(date.getFullYear(), 0, 1).getTimezoneOffset();
  const jul = new Date(date.getFullYear(), 6, 1).getTimezoneOffset();
  const standardOffset = Math.max(jan, jul);
  return date.getTimezoneOffset() < standardOffset;
}

/**
 * Factory creating ClockSyncData from a JavaScript Date object and local system timezone.
 */
export function createClockSyncDataFromDate(
  date: Date = new Date(),
  is24Hour: boolean = false
): ClockSyncData {
  const timestamp = Math.floor(date.getTime() / 1000);
  // In JS, getTimezoneOffset() returns minutes UTC - Local (e.g. +300 for EST).
  // Standard UTC offset is Local - UTC (e.g. -300 for EST).
  const timezoneOffsetMinutes = -date.getTimezoneOffset();
  const isDst = isDateInDst(date);

  return {
    timestamp,
    timezoneOffsetMinutes,
    is24Hour,
    isDst,
  };
}

/**
 * Formats a timezone offset in minutes into a human-readable UTC string (e.g. "UTC-05:00", "UTC+05:30").
 */
export function formatTimezoneOffset(offsetMinutes: number): string {
  const sign = offsetMinutes >= 0 ? '+' : '-';
  const totalMinutes = Math.abs(offsetMinutes);
  const hours = Math.floor(totalMinutes / 60);
  const minutes = totalMinutes % 60;
  return `UTC${sign}${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}`;
}

/**
 * Formats a byte array into hexadecimal string for logging and verification (e.g. "C0 6A C6 6A").
 */
export function bytesToHexString(bytes: Uint8Array): string {
  return Array.from(bytes)
    .map((b) => b.toString(16).toUpperCase().padStart(2, '0'))
    .join(' ');
}
