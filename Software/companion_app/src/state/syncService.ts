/**
 * Clock Synchronization Service for F91_Jepler Smartwatch.
 *
 * Implements the sequential GATT write pipeline adhering strictly to Zephyr RTOS clock_service.c:
 * 1. write Time (4 bytes LE uint32) -> await ACK
 * 2. write Timezone (2 bytes LE int16) -> await ACK
 * 3. write TimeMode (1 byte uint8) -> await ACK
 * 4. write DST (1 byte uint8) -> await ACK
 *
 * Features:
 * - Acknowledged GATT writes executed in strict sequence.
 * - Active disconnect detection and mid-sync link loss protection.
 * - Configurable step-level and operation timeouts.
 * - Progress callbacks with percentage and status descriptions.
 * - Structured synchronization summaries with diagnostic hex formatting.
 */

import { BleClientInterface, DisconnectListener } from '../ble/bleClientInterface';
import {
  CLOCK_SERVICE_UUID,
  CLOCK_TIME_CHAR_UUID,
  CLOCK_TIMEZONE_CHAR_UUID,
  CLOCK_TIMEMODE_CHAR_UUID,
  CLOCK_DST_CHAR_UUID,
  CLOCK_STATUS_CHAR_UUID,
} from '../ble/gattConstants';
import {
  ClockSyncData,
  createClockSyncDataFromDate,
  serializeTime,
  serializeTimezone,
  serializeTimeMode,
  serializeDst,
  formatTimezoneOffset,
  bytesToHexString,
  isDateInDst,
} from '../ble/gattSerializer';

/**
 * Sync progress steps.
 */
export type SyncStep = 'IDLE' | 'TIME' | 'TIMEZONE' | 'TIMEMODE' | 'DST' | 'COMPLETED';

export interface SyncProgress {
  step: SyncStep;
  percent: number;
  message: string;
}

/**
 * Options for configuring the clock sync operation.
 */
export interface SyncOptions {
  /** Target date to synchronize; defaults to current system date (new Date()) */
  date?: Date;
  /** 12-hour vs 24-hour format; defaults to false (12-hour) */
  is24Hour?: boolean;
  /** Daylight Saving Time active flag; defaults to auto-detected local DST */
  isDst?: boolean;
  /** Custom timezone offset in minutes from UTC; defaults to local system offset */
  timezoneOffsetMinutes?: number;
  /** Timeout per characteristic write in milliseconds; defaults to 5000ms */
  timeoutMs?: number;
  /** Optional callback invoked on progress updates */
  onProgress?: (progress: SyncProgress) => void;
}

/**
 * Structured summary returned on successful synchronization.
 */
export interface SyncResult {
  success: boolean;
  timestamp: number;
  localTimeIso: string;
  timezoneOffsetMinutes: number;
  timezoneFormatted: string;
  is24Hour: boolean;
  isDst: boolean;
  durationMs: number;
  stepsCompleted: number;
  data: ClockSyncData;
  payloadHex: {
    time: string;
    timezone: string;
    timeMode: string;
    dst: string;
  };
}

/**
 * Base error class for clock synchronization failures.
 */
export class SyncError extends Error {
  stepsCompleted = 0;
  constructor(message: string) {
    super(message);
    this.name = 'SyncError';
    Object.setPrototypeOf(this, SyncError.prototype);
  }
}

/**
 * Thrown when the target peripheral disconnects before or during synchronization.
 */
export class SyncDisconnectedError extends SyncError {
  constructor(message: string = 'Peripheral disconnected during clock synchronization') {
    super(message);
    this.name = 'SyncDisconnectedError';
    Object.setPrototypeOf(this, SyncDisconnectedError.prototype);
  }
}

/**
 * Thrown when a GATT write request exceeds the configured timeout threshold.
 */
export class SyncTimeoutError extends SyncError {
  readonly characteristicUuid?: string;

  constructor(message: string, characteristicUuid?: string) {
    super(message);
    this.name = 'SyncTimeoutError';
    this.characteristicUuid = characteristicUuid;
    Object.setPrototypeOf(this, SyncTimeoutError.prototype);
  }
}

/**
 * Thrown when an underlying GATT protocol error occurs during characteristic write.
 */
export class SyncGattError extends SyncError {
  readonly characteristicUuid: string;
  readonly originalError?: unknown;

  constructor(message: string, characteristicUuid: string, originalError?: unknown) {
    super(message);
    this.name = 'SyncGattError';
    this.characteristicUuid = characteristicUuid;
    this.originalError = originalError;
    Object.setPrototypeOf(this, SyncGattError.prototype);
  }
}

/**
 * Executes a promise with an enforced timeout threshold.
 */
function withTimeout<T>(
  promise: Promise<T>,
  ms: number,
  timeoutMessage: string,
  characteristicUuid?: string
): Promise<T> {
  return new Promise<T>((resolve, reject) => {
    let timer: ReturnType<typeof setTimeout> | null = setTimeout(() => {
      timer = null;
      reject(new SyncTimeoutError(timeoutMessage, characteristicUuid));
    }, ms);

    promise
      .then((val) => {
        if (timer !== null) {
          clearTimeout(timer);
          resolve(val);
        }
      })
      .catch((err) => {
        if (timer !== null) {
          clearTimeout(timer);
          reject(err);
        }
      });
  });
}

/**
 * Primary function executing the 4-step sequential clock synchronization.
 */
export async function syncClock(
  deviceId: string,
  bleClient: BleClientInterface,
  options: SyncOptions = {}
): Promise<SyncResult> {
  const startTime = Date.now();
  const timeoutMs = options.timeoutMs ?? 5000;
  const targetDate = options.date ?? new Date();

  // 1. Initial connection verification
  const isCurrentlyConnected = await bleClient.isConnected(deviceId);
  if (!isCurrentlyConnected) {
    throw new SyncDisconnectedError(
      `Cannot synchronize clock: peripheral ${deviceId} is not connected`
    );
  }

  // 2. Prepare payload data
  const baseData = createClockSyncDataFromDate(
    targetDate,
    options.is24Hour ?? false
  );

  const syncData: ClockSyncData = {
    timestamp: Math.floor(targetDate.getTime() / 1000),
    timezoneOffsetMinutes:
      options.timezoneOffsetMinutes !== undefined
        ? options.timezoneOffsetMinutes
        : baseData.timezoneOffsetMinutes,
    is24Hour: options.is24Hour !== undefined ? options.is24Hour : baseData.is24Hour,
    isDst: options.isDst !== undefined ? options.isDst : isDateInDst(targetDate),
  };

  const timeBytes = serializeTime(syncData.timestamp);
  const tzBytes = serializeTimezone(syncData.timezoneOffsetMinutes);
  const modeBytes = serializeTimeMode(syncData.is24Hour);
  const dstBytes = serializeDst(syncData.isDst);

  // 3. Setup link loss listener to catch mid-sync disconnections immediately
  let disconnectedDuringSync = false;
  let disconnectListener: DisconnectListener | null = null;

  if (typeof bleClient.onDisconnect === 'function') {
    disconnectListener = (discId: string) => {
      if (discId === deviceId) {
        disconnectedDuringSync = true;
      }
    };
    bleClient.onDisconnect(disconnectListener);
  }

  // Helper verifying link liveness before and after each write
  const verifyLinkAlive = async (phaseName: string): Promise<void> => {
    if (disconnectedDuringSync) {
      throw new SyncDisconnectedError(
        `Peripheral ${deviceId} disconnected during clock synchronization (${phaseName})`
      );
    }
    const connected = await bleClient.isConnected(deviceId);
    if (!connected) {
      disconnectedDuringSync = true;
      throw new SyncDisconnectedError(
        `Peripheral ${deviceId} connection lost during clock synchronization (${phaseName})`
      );
    }
  };

  let stepsCompleted = 0;
  try {
    // Reading the new status characteristic gates the effective-offset protocol.
    if (!bleClient.readCharacteristic) throw new SyncError("BLE driver must support reading clock status before synchronization.");
    let clockStatus: Uint8Array;
    try {
      clockStatus = await withTimeout(
        bleClient.readCharacteristic(deviceId, CLOCK_SERVICE_UUID, CLOCK_STATUS_CHAR_UUID),
        timeoutMs, 'Timed out checking clock protocol', CLOCK_STATUS_CHAR_UUID);
    } catch (err) {
      await verifyLinkAlive('checking clock protocol');
      if (err instanceof SyncTimeoutError) throw err;
      const reason = err instanceof Error ? err.message : String(err);
      // Do not label transport/permission failures as unsupported firmware.
      if (/not found|unknown characteristic|unsupported|does not exist/i.test(reason)) {
        throw new SyncError('Watch firmware update required: clock status is unavailable. No clock fields were written.');
      }
      throw new SyncGattError(`Could not verify clock compatibility: ${reason}. No clock fields were written.`, CLOCK_STATUS_CHAR_UUID, err);
    }
    if (clockStatus.length !== 1 || (clockStatus[0] & 0xfe) !== 0) {
      throw new SyncError('Watch firmware update required: unsupported clock status format. No clock fields were written.');
    }
    await verifyLinkAlive('after checking clock protocol');
    options.onProgress?.({
      step: 'IDLE',
      percent: 0,
      message: 'Starting clock synchronization...',
    });

    // --- STEP 1: Write Time (4 bytes LE uint32) ---
    await verifyLinkAlive('before Time write');
    options.onProgress?.({
      step: 'TIME',
      percent: 25,
      message: `Writing Time (${syncData.timestamp}s)...`,
    });

    try {
      await withTimeout(
        bleClient.writeCharacteristic(
          deviceId,
          CLOCK_SERVICE_UUID,
          CLOCK_TIME_CHAR_UUID,
          timeBytes
        ),
        timeoutMs,
        `Timed out writing Time characteristic to ${deviceId}`,
        CLOCK_TIME_CHAR_UUID
      );
    } catch (err) {
      if (disconnectedDuringSync || !(await bleClient.isConnected(deviceId))) {
        throw new SyncDisconnectedError(
          `Peripheral ${deviceId} disconnected while writing Time`
        );
      }
      if (err instanceof SyncTimeoutError) throw err;
      throw new SyncGattError(
        `Failed to write Time characteristic: ${err instanceof Error ? err.message : String(err)}`,
        CLOCK_TIME_CHAR_UUID,
        err
      );
    }

    stepsCompleted++;

    // --- STEP 2: Write Timezone (2 bytes LE int16) ---
    await verifyLinkAlive('before Timezone write');
    options.onProgress?.({
      step: 'TIMEZONE',
      percent: 50,
      message: `Writing Timezone (${syncData.timezoneOffsetMinutes}m)...`,
    });

    try {
      await withTimeout(
        bleClient.writeCharacteristic(
          deviceId,
          CLOCK_SERVICE_UUID,
          CLOCK_TIMEZONE_CHAR_UUID,
          tzBytes
        ),
        timeoutMs,
        `Timed out writing Timezone characteristic to ${deviceId}`,
        CLOCK_TIMEZONE_CHAR_UUID
      );
    } catch (err) {
      if (disconnectedDuringSync || !(await bleClient.isConnected(deviceId))) {
        throw new SyncDisconnectedError(
          `Peripheral ${deviceId} disconnected while writing Timezone`
        );
      }
      if (err instanceof SyncTimeoutError) throw err;
      throw new SyncGattError(
        `Failed to write Timezone characteristic: ${err instanceof Error ? err.message : String(err)}`,
        CLOCK_TIMEZONE_CHAR_UUID,
        err
      );
    }

    stepsCompleted++;

    // --- STEP 3: Write Time Mode (1 byte uint8) ---
    await verifyLinkAlive('before Time Mode write');
    options.onProgress?.({
      step: 'TIMEMODE',
      percent: 75,
      message: `Writing Time Mode (${syncData.is24Hour ? '24h' : '12h'})...`,
    });

    try {
      await withTimeout(
        bleClient.writeCharacteristic(
          deviceId,
          CLOCK_SERVICE_UUID,
          CLOCK_TIMEMODE_CHAR_UUID,
          modeBytes
        ),
        timeoutMs,
        `Timed out writing Time Mode characteristic to ${deviceId}`,
        CLOCK_TIMEMODE_CHAR_UUID
      );
    } catch (err) {
      if (disconnectedDuringSync || !(await bleClient.isConnected(deviceId))) {
        throw new SyncDisconnectedError(
          `Peripheral ${deviceId} disconnected while writing Time Mode`
        );
      }
      if (err instanceof SyncTimeoutError) throw err;
      throw new SyncGattError(
        `Failed to write Time Mode characteristic: ${err instanceof Error ? err.message : String(err)}`,
        CLOCK_TIMEMODE_CHAR_UUID,
        err
      );
    }

    stepsCompleted++;

    // --- STEP 4: Write DST (1 byte uint8) ---
    await verifyLinkAlive('before DST write');
    options.onProgress?.({
      step: 'DST',
      percent: 100,
      message: `Writing DST (${syncData.isDst ? 'Active' : 'Standard'})...`,
    });

    try {
      await withTimeout(
        bleClient.writeCharacteristic(
          deviceId,
          CLOCK_SERVICE_UUID,
          CLOCK_DST_CHAR_UUID,
          dstBytes
        ),
        timeoutMs,
        `Timed out writing DST characteristic to ${deviceId}`,
        CLOCK_DST_CHAR_UUID
      );
    } catch (err) {
      if (disconnectedDuringSync || !(await bleClient.isConnected(deviceId))) {
        throw new SyncDisconnectedError(
          `Peripheral ${deviceId} disconnected while writing DST`
        );
      }
      if (err instanceof SyncTimeoutError) throw err;
      throw new SyncGattError(
        `Failed to write DST characteristic: ${err instanceof Error ? err.message : String(err)}`,
        CLOCK_DST_CHAR_UUID,
        err
      );
    }

    stepsCompleted++;

    // Final link verification
    await verifyLinkAlive('after completing all writes');

    options.onProgress?.({
      step: 'COMPLETED',
      percent: 100,
      message: 'Clock synchronization complete.',
    });

    const durationMs = Date.now() - startTime;

    return {
      success: true,
      timestamp: syncData.timestamp,
      localTimeIso: targetDate.toISOString(),
      timezoneOffsetMinutes: syncData.timezoneOffsetMinutes,
      timezoneFormatted: formatTimezoneOffset(syncData.timezoneOffsetMinutes),
      is24Hour: syncData.is24Hour,
      isDst: syncData.isDst,
      durationMs,
      stepsCompleted: 4,
      data: syncData,
      payloadHex: {
        time: bytesToHexString(timeBytes),
        timezone: bytesToHexString(tzBytes),
        timeMode: bytesToHexString(modeBytes),
        dst: bytesToHexString(dstBytes),
      },
    };
  } catch (err) {
    if (err instanceof SyncError) {
      err.stepsCompleted = stepsCompleted;
      if (stepsCompleted > 0) err.message += ` ${stepsCompleted} of 4 writes acknowledged; the watch may be partially updated. Retry sends all four fields.`;
      else if (err instanceof SyncTimeoutError && err.characteristicUuid !== CLOCK_STATUS_CHAR_UUID) err.message += ' Write outcome may be unknown; retry sends all four fields.';
    }
    throw err;
  } finally {
    // Teardown temporary disconnect listener
    if (
      disconnectListener &&
      typeof bleClient.removeDisconnectListener === 'function'
    ) {
      bleClient.removeDisconnectListener(disconnectListener);
    }
  }
}

/**
 * ClockSyncService class wrapper providing both static and instance execution methods.
 */
export class ClockSyncService {
  constructor(private bleClient: BleClientInterface) {}

  /**
   * Synchronizes the target peripheral using this instance's BLE client.
   */
  async sync(deviceId: string, options?: SyncOptions): Promise<SyncResult> {
    return syncClock(deviceId, this.bleClient, options);
  }

  /**
   * Static helper for direct invocation.
   */
  static async sync(
    deviceId: string,
    bleClient: BleClientInterface,
    options?: SyncOptions
  ): Promise<SyncResult> {
    return syncClock(deviceId, bleClient, options);
  }
}
