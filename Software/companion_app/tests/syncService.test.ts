import { describe, it, expect, beforeEach, vi } from 'vitest';
import {
  syncClock,
  ClockSyncService,
  SyncResult,
  SyncProgress,
  SyncDisconnectedError,
  SyncTimeoutError,
  SyncGattError,
} from '../src/state/syncService';
import { MockBleService } from '../src/ble/mockBleService';
import {
  CLOCK_SERVICE_UUID,
  CLOCK_TIME_CHAR_UUID,
  CLOCK_TIMEZONE_CHAR_UUID,
  CLOCK_TIMEMODE_CHAR_UUID,
  CLOCK_DST_CHAR_UUID,
} from '../src/ble/gattConstants';
import { deserializeTime, deserializeTimezone } from '../src/ble/gattSerializer';

describe('Sequential Clock Synchronization Service (Milestone 3)', () => {
  let mockBle: MockBleService;
  const targetDeviceId = 'F91-WATCH-SIM-01';

  beforeEach(async () => {
    mockBle = new MockBleService();
    await mockBle.initialize();
    await mockBle.connect(targetDeviceId);
  });

  describe('SYNC-1: Sequential GATT Write Execution Order & Lengths', () => {
    it('should execute exactly 4 GATT writes in strict sequential order', async () => {
      const fixedDate = new Date('2026-10-05T03:08:48Z');
      const result = await syncClock(targetDeviceId, mockBle, {
        date: fixedDate,
        timezoneOffsetMinutes: -300,
        is24Hour: false,
        isDst: false,
      });

      expect(result.success).toBe(true);
      expect(result.stepsCompleted).toBe(4);

      const history = mockBle.getWriteHistory();
      expect(history).toHaveLength(4);

      // Verify strict sequential ordering: Time -> Timezone -> TimeMode -> DST
      expect(history[0].characteristicUuid.toLowerCase()).toBe(
        CLOCK_TIME_CHAR_UUID.toLowerCase()
      );
      expect(history[1].characteristicUuid.toLowerCase()).toBe(
        CLOCK_TIMEZONE_CHAR_UUID.toLowerCase()
      );
      expect(history[2].characteristicUuid.toLowerCase()).toBe(
        CLOCK_TIMEMODE_CHAR_UUID.toLowerCase()
      );
      expect(history[3].characteristicUuid.toLowerCase()).toBe(
        CLOCK_DST_CHAR_UUID.toLowerCase()
      );

      // Verify all writes targeted Clock Service UUID
      for (const record of history) {
        expect(record.serviceUuid.toLowerCase()).toBe(
          CLOCK_SERVICE_UUID.toLowerCase()
        );
        expect(record.deviceId).toBe(targetDeviceId);
      }

      // Verify payload byte lengths conform strictly to Zephyr clock_service.c
      expect(history[0].data.byteLength).toBe(4); // Time
      expect(history[1].data.byteLength).toBe(2); // Timezone
      expect(history[2].data.byteLength).toBe(1); // Time Mode
      expect(history[3].data.byteLength).toBe(1); // DST

      // Verify deserialized values from actual written bytes
      expect(deserializeTime(history[0].data)).toBe(Math.floor(fixedDate.getTime() / 1000));
      expect(deserializeTimezone(history[1].data)).toBe(-300);
    });

    it('should update the simulated watch internal clock registers', async () => {
      const testEpoch = 1791169728;
      const testDate = new Date(testEpoch * 1000);

      await syncClock(targetDeviceId, mockBle, {
        date: testDate,
        timezoneOffsetMinutes: -300,
        is24Hour: false,
        isDst: false,
      });

      const watchState = mockBle.getWatchState();
      expect(watchState.clockTime).toBe(testEpoch);
      expect(watchState.clockTimezone).toBe(-300);
      expect(watchState.clockTimeMode).toBe(0);
      expect(watchState.clockDst).toBe(0);
    });
  });

  describe('SYNC-2: Structured Sync Summary Output', () => {
    it('should return a complete structured sync summary with diagnostic formatting', async () => {
      const targetDate = new Date('2026-10-05T03:08:48Z');
      const result: SyncResult = await syncClock(targetDeviceId, mockBle, {
        date: targetDate,
        timezoneOffsetMinutes: -300,
        is24Hour: false,
        isDst: false,
      });

      expect(result.success).toBe(true);
      expect(result.timestamp).toBe(Math.floor(targetDate.getTime() / 1000));
      expect(result.localTimeIso).toBe(targetDate.toISOString());
      expect(result.timezoneOffsetMinutes).toBe(-300);
      expect(result.timezoneFormatted).toBe('UTC-05:00');
      expect(result.is24Hour).toBe(false);
      expect(result.isDst).toBe(false);
      expect(result.durationMs).toBeGreaterThanOrEqual(0);
      expect(result.stepsCompleted).toBe(4);

      // Verify diagnostic payload hex strings
      expect(result.payloadHex.time).toBe('C0 14 C3 6A');
      expect(result.payloadHex.timezone).toBe('D4 FE');
      expect(result.payloadHex.timeMode).toBe('00');
      expect(result.payloadHex.dst).toBe('00');

      // Verify underlying ClockSyncData object
      expect(result.data.timestamp).toBe(Math.floor(targetDate.getTime() / 1000));
      expect(result.data.timezoneOffsetMinutes).toBe(-300);
      expect(result.data.is24Hour).toBe(false);
      expect(result.data.isDst).toBe(false);
    });

    it('should format positive timezone offset correctly (Tokyo UTC+9)', async () => {
      const result = await syncClock(targetDeviceId, mockBle, {
        timezoneOffsetMinutes: 540,
        is24Hour: true,
        isDst: false,
      });

      expect(result.timezoneOffsetMinutes).toBe(540);
      expect(result.timezoneFormatted).toBe('UTC+09:00');
      expect(result.payloadHex.timezone).toBe('1C 02');
      expect(result.payloadHex.timeMode).toBe('01');
    });

    it('should format fractional timezone offset correctly (Kathmandu UTC+5:45)', async () => {
      const result = await syncClock(targetDeviceId, mockBle, {
        timezoneOffsetMinutes: 345,
        is24Hour: false,
        isDst: false,
      });

      expect(result.timezoneOffsetMinutes).toBe(345);
      expect(result.timezoneFormatted).toBe('UTC+05:45');
      expect(result.payloadHex.timezone).toBe('59 01');
    });
  });

  describe('SYNC-3: Progress Reporting & Step Callbacks', () => {
    it('should invoke onProgress callback for each step from 0% to 100%', async () => {
      const progressHistory: SyncProgress[] = [];

      await syncClock(targetDeviceId, mockBle, {
        onProgress: (prog) => {
          progressHistory.push({ ...prog });
        },
      });

      expect(progressHistory.length).toBeGreaterThanOrEqual(5);

      const steps = progressHistory.map((p) => p.step);
      expect(steps).toEqual(['IDLE', 'TIME', 'TIMEZONE', 'TIMEMODE', 'DST', 'COMPLETED']);

      const percentages = progressHistory.map((p) => p.percent);
      expect(percentages).toEqual([0, 25, 50, 75, 100, 100]);

      // Verify progress messages are informative
      expect(progressHistory[1].message).toContain('Writing Time');
      expect(progressHistory[2].message).toContain('Writing Timezone');
      expect(progressHistory[3].message).toContain('Writing Time Mode');
      expect(progressHistory[4].message).toContain('Writing DST');
    });
  });

  describe('SYNC-4: Disconnection & Link Loss Guards', () => {
    it('should reject immediately if target peripheral is not connected', async () => {
      await mockBle.disconnect(targetDeviceId);

      await expect(
        syncClock(targetDeviceId, mockBle)
      ).rejects.toThrow(SyncDisconnectedError);

      expect(mockBle.getWriteHistory()).toHaveLength(0);
    });

    it('should catch mid-sync link loss and abort subsequent writes', async () => {
      // Configure mock to simulate sudden disconnect when writing Timezone
      const origWrite = mockBle.writeCharacteristic.bind(mockBle);
      mockBle.writeCharacteristic = async (devId, sId, cId, data) => {
        if (cId.toLowerCase() === CLOCK_TIMEZONE_CHAR_UUID.toLowerCase()) {
          // Peripheral drops connection right before timezone write
          await mockBle.disconnect(devId);
        }
        return origWrite(devId, sId, cId, data);
      };

      await expect(
        syncClock(targetDeviceId, mockBle)
      ).rejects.toThrow(SyncDisconnectedError);

      const history = mockBle.getWriteHistory();
      // Time write should have completed, but subsequent writes must not have run
      expect(history.length).toBeLessThan(4);
      expect(
        history.some((h) => h.characteristicUuid.toLowerCase() === CLOCK_DST_CHAR_UUID.toLowerCase())
      ).toBe(false);
    });

    it('should clean up temporary disconnect listeners even on failure', async () => {
      const removeSpy = vi.spyOn(mockBle, 'removeDisconnectListener');

      mockBle.failNextWrite(CLOCK_TIMEZONE_CHAR_UUID, 'GATT Link Lost');

      await expect(
        syncClock(targetDeviceId, mockBle)
      ).rejects.toThrow();

      expect(removeSpy).toHaveBeenCalled();
    });
  });

  describe('SYNC-5: Timeout & GATT Error Handling', () => {
    it('should throw SyncTimeoutError if a characteristic write hangs', async () => {
      // Simulate hanging write with latency longer than timeout
      mockBle.setWriteLatency(100);

      await expect(
        syncClock(targetDeviceId, mockBle, {
          timeoutMs: 20, // Strict 20ms timeout
        })
      ).rejects.toThrow(SyncTimeoutError);
    });

    it('should throw SyncGattError on write rejection and identify characteristic', async () => {
      mockBle.failNextWrite(CLOCK_TIMEMODE_CHAR_UUID, 'Simulated ATT write error');

      try {
        await syncClock(targetDeviceId, mockBle);
        expect.unreachable('Should have thrown SyncGattError');
      } catch (err) {
        expect(err).toBeInstanceOf(SyncGattError);
        const gattErr = err as SyncGattError;
        expect(gattErr.characteristicUuid.toLowerCase()).toBe(
          CLOCK_TIMEMODE_CHAR_UUID.toLowerCase()
        );
        expect(gattErr.message).toContain('Failed to write Time Mode characteristic');
      }
    });
  });

  describe('SYNC-6: Parity with ClockSyncService Class Methods', () => {
    it('should execute identically via ClockSyncService instance', async () => {
      const service = new ClockSyncService(mockBle);
      const testDate = new Date('2026-10-05T04:00:00Z');

      const result = await service.sync(targetDeviceId, {
        date: testDate,
        is24Hour: true,
      });

      expect(result.success).toBe(true);
      expect(result.is24Hour).toBe(true);
      expect(mockBle.getWriteHistory()).toHaveLength(4);
    });

    it('should execute identically via ClockSyncService static method', async () => {
      const testDate = new Date('2026-10-05T04:00:00Z');

      const result = await ClockSyncService.sync(targetDeviceId, mockBle, {
        date: testDate,
        is24Hour: true,
      });

      expect(result.success).toBe(true);
      expect(result.is24Hour).toBe(true);
      expect(mockBle.getWriteHistory()).toHaveLength(4);
    });
  });

  describe('SYNC-7: Multiple Successive Syncs (Stress & Stability)', () => {
    it('should execute 5 consecutive syncs without resource leakage', async () => {
      for (let i = 0; i < 5; i++) {
        const res = await syncClock(targetDeviceId, mockBle, {
          is24Hour: i % 2 === 0,
        });
        expect(res.success).toBe(true);
      }

      // 5 syncs × 4 writes = 20 total writes recorded
      expect(mockBle.getWriteHistory()).toHaveLength(20);
    });
  });
});
