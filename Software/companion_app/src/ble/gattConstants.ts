/**
 * GATT Service and Characteristic UUIDs, device constants, and protocol definitions
 * for the F91_Jepler smartwatch.
 *
 * Conforms strictly to Zephyr RTOS firmware:
 * - Firmware/zephyr/src/services/clock_service.h
 * - Firmware/zephyr/src/services/clock_service.c
 * - Firmware/zephyr/prj.conf
 */

/** Target peripheral local name broadcast in primary BLE advertisements */
export const F91_DEVICE_NAME = 'F91_Jepler';

/**
 * F91 Clock Service UUID (128-bit)
 * Base: fa35b2f0-7989-11eb-9439-0242ac130002
 */
export const CLOCK_SERVICE_UUID = 'fa35b2f0-7989-11eb-9439-0242ac130002';

/**
 * Clock Time Characteristic UUID (128-bit)
 * 4-byte uint32 little-endian Unix epoch seconds.
 * Readable & Writable.
 */
export const CLOCK_TIME_CHAR_UUID = 'fa35b2f1-7989-11eb-9439-0242ac130002';

/**
 * Clock Timezone Characteristic UUID (128-bit)
 * 2-byte signed int16 little-endian offset in minutes from UTC (two's complement).
 * Readable & Writable.
 */
export const CLOCK_TIMEZONE_CHAR_UUID = 'fa35b2f2-7989-11eb-9439-0242ac130002';

/**
 * Clock Time Mode Characteristic UUID (128-bit)
 * 1-byte uint8: 0 = 12-hour format, 1 = 24-hour format.
 * Readable & Writable.
 */
export const CLOCK_TIMEMODE_CHAR_UUID = 'fa35b2f3-7989-11eb-9439-0242ac130002';

/**
 * Clock Daylight Saving Time (DST) Characteristic UUID (128-bit)
 * 1-byte uint8: 0 = Standard Time, 1 = Daylight Saving Time active.
 * Readable & Writable.
 */
export const CLOCK_DST_CHAR_UUID = 'fa35b2f4-7989-11eb-9439-0242ac130002';

/**
 * F91 Notification Service UUID (128-bit, advertised in scan response)
 * Base: fa35a2f0-7989-11eb-9439-0242ac130002
 */
export const NOTIFICATION_SERVICE_UUID = 'fa35a2f0-7989-11eb-9439-0242ac130002';

/** Strict byte lengths expected by Zephyr clock_service.c write handlers */
export const CLOCK_PAYLOAD_LENGTHS = {
  TIME: 4,     // sizeof(uint32_t)
  TIMEZONE: 2, // sizeof(uint16_t)
  TIMEMODE: 1, // sizeof(uint8_t)
  DST: 1,      // sizeof(uint8_t)
} as const;

/** Permitted values for Clock Time Mode */
export const TIME_MODE = {
  MODE_12_HOUR: 0,
  MODE_24_HOUR: 1,
} as const;

/** Permitted values for Clock DST */
export const DST_MODE = {
  STANDARD: 0,
  DAYLIGHT_SAVING: 1,
} as const;

/** Zephyr ATT Protocol Error Code returned on invalid payload size or offset */
export const BT_ATT_ERR_INVALID_OFFSET = 0x07;
