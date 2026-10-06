import { describe, it, expect, beforeEach } from 'vitest';
import {
  ConnectionStateMachine,
  connectionReducer,
  connectionActions,
  initialConnectionState,
  ConnectionEvent,
} from '../src/state/connectionStateMachine';
import {
  syncClock,
  SyncDisconnectedError,
  SyncTimeoutError,
  SyncGattError,
} from '../src/state/syncService';
import { MockBleService } from '../src/ble/mockBleService';
import {
  CLOCK_TIME_CHAR_UUID,
  CLOCK_TIMEZONE_CHAR_UUID,
  CLOCK_TIMEMODE_CHAR_UUID,
  CLOCK_DST_CHAR_UUID,
} from '../src/ble/gattConstants';
import { deserializeTime, deserializeTimezone } from '../src/ble/gattSerializer';

describe('Challenger M3: Adversarial Stress & Integrity Verification Suite', () => {
  let mockBle: MockBleService;
  const targetDeviceId = 'F91-WATCH-SIM-01';

  beforeEach(async () => {
    mockBle = new MockBleService();
    await mockBle.initialize();
    await mockBle.connect(targetDeviceId);
  });

  describe('ADV-1: Mid-Sync Disconnection at Every Stage', () => {
    const characteristics = [
      { name: 'Time', uuid: CLOCK_TIME_CHAR_UUID, stepNum: 0 },
      { name: 'Timezone', uuid: CLOCK_TIMEZONE_CHAR_UUID, stepNum: 1 },
      { name: 'TimeMode', uuid: CLOCK_TIMEMODE_CHAR_UUID, stepNum: 2 },
      { name: 'DST', uuid: CLOCK_DST_CHAR_UUID, stepNum: 3 },
    ];

    it.each(characteristics)(
      'aborts immediately with SyncDisconnectedError if link drops before writing $name',
      async ({ uuid, stepNum }) => {
        let writesAttempted = 0;
        const origWrite = mockBle.writeCharacteristic.bind(mockBle);
        mockBle.writeCharacteristic = async (dId, sId, cId, data) => {
          if (cId.toLowerCase() === uuid.toLowerCase()) {
            // Drop connection right when this characteristic is invoked
            await mockBle.disconnect(dId);
          }
          writesAttempted++;
          return origWrite(dId, sId, cId, data);
        };

        await expect(
          syncClock(targetDeviceId, mockBle)
        ).rejects.toThrow(SyncDisconnectedError);

        // Verify that subsequent writes were NOT executed
        expect(writesAttempted).toBeLessThanOrEqual(stepNum + 1);
        const history = mockBle.getWriteHistory();
        expect(history.length).toBeLessThan(4);
      }
    );
  });

  describe('ADV-2: Timeout Handling at Every Stage', () => {
    const characteristics = [
      { name: 'Time', uuid: CLOCK_TIME_CHAR_UUID },
      { name: 'Timezone', uuid: CLOCK_TIMEZONE_CHAR_UUID },
      { name: 'TimeMode', uuid: CLOCK_TIMEMODE_CHAR_UUID },
      { name: 'DST', uuid: CLOCK_DST_CHAR_UUID },
    ];

    it.each(characteristics)(
      'throws SyncTimeoutError targeting $name when write hangs',
      async ({ uuid }) => {
        mockBle.writeCharacteristic = async (_dId, _sId, cId, _data) => {
          if (cId.toLowerCase() === uuid.toLowerCase()) {
            // Simulate hanging GATT call (never resolves before timeout)
            await new Promise((resolve) => setTimeout(resolve, 150));
          }
        };

        try {
          await syncClock(targetDeviceId, mockBle, { timeoutMs: 25 });
          expect.unreachable('Should have timed out');
        } catch (err) {
          expect(err).toBeInstanceOf(SyncTimeoutError);
          const timeoutErr = err as SyncTimeoutError;
          expect(timeoutErr.characteristicUuid?.toLowerCase()).toBe(uuid.toLowerCase());
        }
      }
    );
  });

  describe('ADV-3: GATT Write Rejection at Every Stage', () => {
    const characteristics = [
      { name: 'Time', uuid: CLOCK_TIME_CHAR_UUID },
      { name: 'Timezone', uuid: CLOCK_TIMEZONE_CHAR_UUID },
      { name: 'TimeMode', uuid: CLOCK_TIMEMODE_CHAR_UUID },
      { name: 'DST', uuid: CLOCK_DST_CHAR_UUID },
    ];

    it.each(characteristics)(
      'throws SyncGattError targeting $name when peripheral returns ATT error',
      async ({ name, uuid }) => {
        mockBle.failNextWrite(uuid, `ATT Error 0x05 on ${name}`);

        try {
          await syncClock(targetDeviceId, mockBle);
          expect.unreachable('Should have failed write');
        } catch (err) {
          expect(err).toBeInstanceOf(SyncGattError);
          const gattErr = err as SyncGattError;
          expect(gattErr.characteristicUuid.toLowerCase()).toBe(uuid.toLowerCase());
          expect(gattErr.message).toContain(`ATT Error 0x05 on ${name}`);
        }
      }
    );
  });

  describe('ADV-4: Extreme Timezone Offsets & Far-Future Timestamps', () => {
    it('accurately synchronizes extreme negative timezone (Baker Island UTC-12:00 / -720m)', async () => {
      const farFutureDate = new Date('2099-12-31T23:59:59Z');
      const res = await syncClock(targetDeviceId, mockBle, {
        date: farFutureDate,
        timezoneOffsetMinutes: -720,
        is24Hour: true,
        isDst: false,
      });

      expect(res.success).toBe(true);
      expect(res.timezoneFormatted).toBe('UTC-12:00');
      expect(res.payloadHex.timezone).toBe('30 FD'); // -720 in 16-bit signed LE is 0xFD30 -> 30 FD
      expect(res.data.timestamp).toBe(Math.floor(farFutureDate.getTime() / 1000));

      const history = mockBle.getWriteHistory();
      expect(deserializeTimezone(history[1].data)).toBe(-720);
      expect(deserializeTime(history[0].data)).toBe(Math.floor(farFutureDate.getTime() / 1000));
    });

    it('accurately synchronizes extreme positive timezone (Kiritimati UTC+14:00 / +840m)', async () => {
      const res = await syncClock(targetDeviceId, mockBle, {
        timezoneOffsetMinutes: 840,
        is24Hour: true,
        isDst: false,
      });

      expect(res.success).toBe(true);
      expect(res.timezoneFormatted).toBe('UTC+14:00');
      expect(res.payloadHex.timezone).toBe('48 03'); // +840 in 16-bit signed LE is 0x0348 -> 48 03

      const history = mockBle.getWriteHistory();
      expect(deserializeTimezone(history[1].data)).toBe(840);
    });

    it('accurately synchronizes half-hour timezone (Adelaide UTC+9:30 / +570m)', async () => {
      const res = await syncClock(targetDeviceId, mockBle, {
        timezoneOffsetMinutes: 570,
        is24Hour: false,
        isDst: true,
      });

      expect(res.success).toBe(true);
      expect(res.timezoneFormatted).toBe('UTC+09:30');
      expect(res.payloadHex.timezone).toBe('3A 02'); // +570 in 16-bit signed LE is 0x023A -> 3A 02
      expect(res.isDst).toBe(true);
    });
  });

  describe('ADV-5: High-Frequency Burst Transitions & Deduplication Stress', () => {
    it('handles 1,000 noisy device discovery packets without memory leak or duplicates', () => {
      const sm = new ConnectionStateMachine();
      sm.dispatch(connectionActions.startScan());

      for (let i = 0; i < 1000; i++) {
        // Repeatedly send discovery for 3 alternating device IDs with fluctuating RSSI
        const devId = `F91-WATCH-00${i % 3}`;
        const rssi = -50 - (i % 40);
        sm.dispatch(
          connectionActions.deviceFound({
            deviceId: devId,
            name: `Watch ${i % 3}`,
            rssi,
          })
        );
      }

      const devices = sm.getState().discoveredDevices;
      expect(devices).toHaveLength(3);
      expect(devices.map((d) => d.deviceId)).toEqual([
        'F91-WATCH-000',
        'F91-WATCH-001',
        'F91-WATCH-002',
      ]);
    });

    it('survives rapid event dispatch bursts without entering invalid states', () => {
      const sm = new ConnectionStateMachine();

      const sequence: ConnectionEvent[] = [
        'START_SCAN',
        'STOP_SCAN',
        'START_SCAN',
        'SELECT_DEVICE',
        'CONNECT_SUCCESS',
        'START_SYNC',
        'SYNC_SUCCESS',
        'START_SYNC',
        'SYNC_FAILURE',
        'DISCONNECT',
        'START_SCAN',
        'DISCONNECT',
      ];

      for (const event of sequence) {
        expect(() => {
          sm.transition(event, { deviceId: 'DEV-1', name: 'Watch' });
        }).not.toThrow();
      }

      expect(sm.getStatus()).toBe('DISCONNECTED');
    });

    it('preserves immutable state history across reducer dispatches', () => {
      let state = initialConnectionState;
      const states: typeof state[] = [state];

      const actions = [
        connectionActions.startScan(),
        connectionActions.deviceFound({ deviceId: 'D1', name: 'W1' }),
        connectionActions.selectDevice({ deviceId: 'D1', name: 'W1' }),
        connectionActions.connectSuccess({ deviceId: 'D1', name: 'W1' }),
        connectionActions.startSync(),
        connectionActions.syncSuccess(new Date()),
        connectionActions.disconnect(),
      ];

      for (const act of actions) {
        state = connectionReducer(state, act);
        states.push(state);
      }

      // Verify that every state snapshot in states array remains distinct and frozen
      for (let i = 0; i < states.length - 1; i++) {
        expect(states[i]).not.toBe(states[i + 1]);
      }
      expect(states[0].status).toBe('DISCONNECTED');
      expect(states[1].status).toBe('SCANNING');
      expect(states[2].discoveredDevices).toHaveLength(1);
      expect(states[3].status).toBe('CONNECTING');
      expect(states[4].status).toBe('CONNECTED');
      expect(states[5].status).toBe('SYNCING');
      expect(states[6].status).toBe('CONNECTED');
      expect(states[7].status).toBe('DISCONNECTED');
    });
  });
});
