/**
 * E2E Integration Test Suite for F91_Jepler Smartwatch Companion Mobile App.
 *
 * Implements the 4-Tier Opaque-Box Verification Framework:
 * - Tier 1: Baseline Feature Flow & Comprehensive Feature Coverage (40 tests, 5 per feature across 8 features)
 * - Tier 2: Boundary & Corner Cases (40 tests across timestamps, timezones, buffer lengths, GATT ATT errors)
 * - Tier 3: Pairwise Combinations & Fault Recovery (16 tests across Mode x DST, mid-sync drops, timeouts)
 * - Tier 4: Real-World Workload Scenarios (6 comprehensive real-world multi-step user scenarios)
 *
 * Total: 102 Genuine Automated Integration Tests.
 */

import React from 'react';
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, fireEvent, act, waitFor, cleanup, renderHook } from '@testing-library/react';
import App from '../src/App';
import { BleDevice } from '../src/ble/bleClientInterface';
import { MockBleService } from '../src/ble/mockBleService';
import {
  F91_DEVICE_NAME,
  CLOCK_SERVICE_UUID,
  CLOCK_TIME_CHAR_UUID,
  CLOCK_TIMEZONE_CHAR_UUID,
  CLOCK_TIMEMODE_CHAR_UUID,
  CLOCK_DST_CHAR_UUID,
  CLOCK_PAYLOAD_LENGTHS,
  TIME_MODE,
  DST_MODE,
} from '../src/ble/gattConstants';
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
  ConnectionStateMachine,
  connectionReducer,
  connectionActions,
  initialConnectionState,
  InvalidTransitionError,
  ConnectionMachineState,
} from '../src/state/connectionStateMachine';
import {
  syncClock,
  SyncProgress,
  SyncDisconnectedError,
  SyncTimeoutError,
  SyncGattError,
} from '../src/state/syncService';
import { useBleConnection } from '../src/state/useBleConnection';

describe('E2E Integration Test Suite: F91_Jepler Companion App', () => {
  afterEach(() => {
    cleanup();
    vi.restoreAllMocks();
    vi.useRealTimers();
  });

  // =========================================================================
  // TIER 1: BASELINE FEATURE COVERAGE (40 Tests, 5 per feature across 8 features)
  // =========================================================================
  describe('Tier 1: Baseline Feature Coverage Suite', () => {
    // -----------------------------------------------------------------------
    // Feature 1: Time Serialization (4-byte LE uint32)
    // -----------------------------------------------------------------------
    describe('F1: Time Serialization (4B LE uint32)', () => {
      it('F1-1: serializes standard timestamp 1700000000 to exact little-endian 4-byte buffer', () => {
        const bytes = serializeTime(1700000000);
        expect(bytes.byteLength).toBe(4);
        // 1700000000 in hex is 0x6553F100 -> LE: 0x00, 0xF1, 0x53, 0x65
        expect(Array.from(bytes)).toEqual([0x00, 0xf1, 0x53, 0x65]);
      });

      it('F1-2: round-trip deserializes 4-byte buffer back to original timestamp', () => {
        const timestamp = 1728000000;
        const serialized = serializeTime(timestamp);
        const deserialized = deserializeTime(serialized);
        expect(deserialized).toBe(timestamp);
      });

      it('F1-3: serializes fixed Y2K epoch vector (946684800)', () => {
        // 946684800 = 0x386D4380 -> LE: [0x80, 0x43, 0x6D, 0x38]
        const bytes = serializeTime(946684800);
        expect(Array.from(bytes)).toEqual([0x80, 0x43, 0x6d, 0x38]);
        expect(deserializeTime(bytes)).toBe(946684800);
      });

      it('F1-4: verifies byte 0 is least-significant byte and byte 3 is most-significant byte', () => {
        const val = 0x12345678;
        const bytes = serializeTime(val);
        expect(bytes[0]).toBe(0x78); // LSB
        expect(bytes[1]).toBe(0x56);
        expect(bytes[2]).toBe(0x34);
        expect(bytes[3]).toBe(0x12); // MSB
      });

      it('F1-5: converts byte array to formatted hex diagnostic string', () => {
        const bytes = new Uint8Array([0x00, 0xf1, 0x53, 0x65]);
        const hex = bytesToHexString(bytes);
        expect(hex).toBe('00 F1 53 65');
      });
    });

    // -----------------------------------------------------------------------
    // Feature 2: Timezone Serialization (2-byte LE int16)
    // -----------------------------------------------------------------------
    describe('F2: Timezone Serialization (2B LE int16)', () => {
      it('F2-1: serializes UTC 0 minutes to [0x00, 0x00]', () => {
        const bytes = serializeTimezone(0);
        expect(bytes.byteLength).toBe(2);
        expect(Array.from(bytes)).toEqual([0x00, 0x00]);
        expect(deserializeTimezone(bytes)).toBe(0);
      });

      it('F2-2: serializes positive offset (+330 min, IST UTC+05:30) to [0x4A, 0x01]', () => {
        // +330 = 0x014A -> LE: [0x4A, 0x01]
        const bytes = serializeTimezone(330);
        expect(Array.from(bytes)).toEqual([0x4a, 0x01]);
        expect(deserializeTimezone(bytes)).toBe(330);
      });

      it('F2-3: serializes negative offset (-300 min, EST UTC-05:00) using two\'s complement to [0xD4, 0xFE]', () => {
        // -300 as signed int16 is 0xFED4 -> LE: [0xD4, 0xFE]
        const bytes = serializeTimezone(-300);
        expect(Array.from(bytes)).toEqual([0xd4, 0xfe]);
        expect(deserializeTimezone(bytes)).toBe(-300);
      });

      it('F2-4: serializes positive CET offset (+60 min) to [0x3C, 0x00]', () => {
        const bytes = serializeTimezone(60);
        expect(Array.from(bytes)).toEqual([0x3c, 0x00]);
        expect(deserializeTimezone(bytes)).toBe(60);
      });

      it('F2-5: formats timezone offsets to human-readable strings', () => {
        expect(formatTimezoneOffset(0)).toBe('UTC+00:00');
        expect(formatTimezoneOffset(-300)).toBe('UTC-05:00');
        expect(formatTimezoneOffset(330)).toBe('UTC+05:30');
        expect(formatTimezoneOffset(-480)).toBe('UTC-08:00');
      });
    });

    // -----------------------------------------------------------------------
    // Feature 3: Time Mode Serialization (1-byte uint8)
    // -----------------------------------------------------------------------
    describe('F3: Time Mode Serialization (1B uint8)', () => {
      it('F3-1: serializes 12-hour format (false) to [0x00]', () => {
        const bytes = serializeTimeMode(false);
        expect(bytes.byteLength).toBe(1);
        expect(bytes[0]).toBe(TIME_MODE.MODE_12_HOUR);
      });

      it('F3-2: serializes 24-hour format (true) to [0x01]', () => {
        const bytes = serializeTimeMode(true);
        expect(bytes.byteLength).toBe(1);
        expect(bytes[0]).toBe(TIME_MODE.MODE_24_HOUR);
      });

      it('F3-3: deserializes [0x00] back to false (12-hour)', () => {
        const bytes = new Uint8Array([0x00]);
        expect(deserializeTimeMode(bytes)).toBe(false);
      });

      it('F3-4: deserializes [0x01] back to true (24-hour)', () => {
        const bytes = new Uint8Array([0x01]);
        expect(deserializeTimeMode(bytes)).toBe(true);
      });

      it('F3-5: normalizes numeric inputs (0 -> 12h, 1 -> 24h, non-zero -> 24h)', () => {
        expect(serializeTimeMode(0)[0]).toBe(TIME_MODE.MODE_12_HOUR);
        expect(serializeTimeMode(1)[0]).toBe(TIME_MODE.MODE_24_HOUR);
        expect(serializeTimeMode(42)[0]).toBe(TIME_MODE.MODE_24_HOUR);
      });
    });

    // -----------------------------------------------------------------------
    // Feature 4: DST Serialization (1-byte uint8)
    // -----------------------------------------------------------------------
    describe('F4: DST Serialization (1B uint8)', () => {
      it('F4-1: serializes Standard Time (false) to [0x00]', () => {
        const bytes = serializeDst(false);
        expect(bytes.byteLength).toBe(1);
        expect(bytes[0]).toBe(DST_MODE.STANDARD);
      });

      it('F4-2: serializes Daylight Saving Time (true) to [0x01]', () => {
        const bytes = serializeDst(true);
        expect(bytes.byteLength).toBe(1);
        expect(bytes[0]).toBe(DST_MODE.DAYLIGHT_SAVING);
      });

      it('F4-3: deserializes [0x00] back to false (Standard Time)', () => {
        const bytes = new Uint8Array([0x00]);
        expect(deserializeDst(bytes)).toBe(false);
      });

      it('F4-4: deserializes [0x01] back to true (Daylight Saving Time)', () => {
        const bytes = new Uint8Array([0x01]);
        expect(deserializeDst(bytes)).toBe(true);
      });

      it('F4-5: round-trips structured ClockSyncData containing all 4 characteristics', () => {
        const data: ClockSyncData = {
          timestamp: 1710000000,
          timezoneOffsetMinutes: -240,
          is24Hour: true,
          isDst: true,
        };
        const payload = serializeClockSyncData(data);
        const restored = deserializeClockSyncPayload(payload);
        expect(restored).toEqual(data);
      });
    });

    // -----------------------------------------------------------------------
    // Feature 5: BLE Peripheral Discovery Filter
    // -----------------------------------------------------------------------
    describe('F5: BLE Peripheral Discovery Filter', () => {
      it('F5-1: discovers peripheral matching target name F91_Jepler', async () => {
        const mockBle = new MockBleService();
        const found: BleDevice[] = [];
        await mockBle.startScan((dev) => found.push(dev));
        expect(found.some((d) => d.name === F91_DEVICE_NAME)).toBe(true);
      });

      it('F5-2: discovers peripheral advertising Clock Service UUID fa35b2f0...', async () => {
        const mockBle = new MockBleService();
        mockBle.setAvailableDevices([
          {
            deviceId: 'DEV-UUID-MATCH',
            name: 'Anonymous_Watch',
            services: [CLOCK_SERVICE_UUID],
          },
        ]);
        const found: BleDevice[] = [];
        await mockBle.startScan((dev) => found.push(dev));
        expect(found.some((d) => d.deviceId === 'DEV-UUID-MATCH')).toBe(true);
      });

      it('F5-3: ignores foreign peripherals with non-matching name and missing service UUID', async () => {
        const mockBle = new MockBleService();
        mockBle.setAvailableDevices([
          {
            deviceId: 'FOREIGN-01',
            name: 'Smart_Fridge',
            services: ['0000180a-0000-1000-8000-00805f9b34fb'],
          },
        ]);
        const found: BleDevice[] = [];
        await mockBle.startScan((dev) => found.push(dev));
        expect(found.length).toBe(0);
      });

      it('F5-4: deduplicates repeated scan advertisements by deviceId', () => {
        const state: ConnectionMachineState = {
          ...initialConnectionState,
          status: 'SCANNING',
          discoveredDevices: [{ deviceId: 'DEV-01', name: 'F91_Jepler', rssi: -70 }],
        };
        const updated = connectionReducer(
          state,
          connectionActions.deviceFound({ deviceId: 'DEV-01', name: 'F91_Jepler', rssi: -65 })
        );
        expect(updated.discoveredDevices.length).toBe(1);
        expect(updated.discoveredDevices[0].rssi).toBe(-65);
      });

      it('F5-5: appends distinct new peripherals to discovery list', () => {
        const state: ConnectionMachineState = {
          ...initialConnectionState,
          status: 'SCANNING',
          discoveredDevices: [{ deviceId: 'DEV-01', name: 'F91_Jepler' }],
        };
        const updated = connectionReducer(
          state,
          connectionActions.deviceFound({ deviceId: 'DEV-02', name: 'F91_Jepler' })
        );
        expect(updated.discoveredDevices.length).toBe(2);
        expect(updated.discoveredDevices[1].deviceId).toBe('DEV-02');
      });
    });

    // -----------------------------------------------------------------------
    // Feature 6: Connection State Machine Lifecycle
    // -----------------------------------------------------------------------
    describe('F6: Connection State Machine Lifecycle', () => {
      it('F6-1: follows standard lifecycle: DISCONNECTED -> SCANNING -> CONNECTING -> CONNECTED', () => {
        const fsm = new ConnectionStateMachine();
        expect(fsm.getStatus()).toBe('DISCONNECTED');

        fsm.dispatch(connectionActions.startScan());
        expect(fsm.getStatus()).toBe('SCANNING');

        const device = { deviceId: 'DEV-TEST', name: 'F91_Jepler' };
        fsm.dispatch(connectionActions.selectDevice(device));
        expect(fsm.getStatus()).toBe('CONNECTING');

        fsm.dispatch(connectionActions.connectSuccess(device));
        expect(fsm.getStatus()).toBe('CONNECTED');
        expect(fsm.getState().selectedDevice?.deviceId).toBe('DEV-TEST');
      });

      it('F6-2: rejects invalid transitions in strict mode', () => {
        const fsm = new ConnectionStateMachine();
        expect(fsm.getStatus()).toBe('DISCONNECTED');
        // Cannot trigger CONNECT_SUCCESS directly from DISCONNECTED
        expect(() => fsm.dispatch(connectionActions.connectSuccess(), { strict: true })).toThrow(
          InvalidTransitionError
        );
      });

      it('F6-3: handles connection failure transitioning to ERROR state', () => {
        const fsm = new ConnectionStateMachine();
        fsm.transition('START_SCAN');
        fsm.transition('SELECT_DEVICE', { deviceId: 'DEV-FAIL', name: 'F91_Jepler' });
        fsm.transition('CONNECT_FAILURE', 'Bluetooth peripheral unreachable');

        expect(fsm.getStatus()).toBe('ERROR');
        expect(fsm.getState().error).toBe('Bluetooth peripheral unreachable');
        expect(fsm.getState().selectedDevice).toBeNull();
      });

      it('F6-4: clears error returning to DISCONNECTED state with cleared message', () => {
        const fsm = new ConnectionStateMachine({
          status: 'ERROR',
          error: 'Connection timeout',
        });
        fsm.dispatch(connectionActions.clearError());
        expect(fsm.getStatus()).toBe('DISCONNECTED');
        expect(fsm.getState().error).toBeNull();
      });

      it('F6-5: permits DISCONNECT from any active state cleanly', () => {
        const states: ConnectionMachineState['status'][] = [
          'DISCONNECTED',
          'SCANNING',
          'CONNECTING',
          'CONNECTED',
          'SYNCING',
          'ERROR',
        ];
        for (const st of states) {
          const fsm = new ConnectionStateMachine({ status: st });
          expect(fsm.canTransition('DISCONNECT')).toBe(true);
          fsm.dispatch(connectionActions.disconnect());
          expect(fsm.getStatus()).toBe('DISCONNECTED');
        }
      });
    });

    // -----------------------------------------------------------------------
    // Feature 7: Sequential GATT Sync Pipeline
    // -----------------------------------------------------------------------
    describe('F7: Sequential GATT Sync Pipeline', () => {
      let mockBle: MockBleService;

      beforeEach(async () => {
        mockBle = new MockBleService();
        await mockBle.initialize();
        await mockBle.connect('F91-WATCH-SIM-01');
      });

      it('F7-1: executes writes in exact canonical order: TIME -> TIMEZONE -> TIMEMODE -> DST', async () => {
        const result = await syncClock('F91-WATCH-SIM-01', mockBle);
        expect(result.success).toBe(true);

        const history = mockBle.getWriteHistory();
        expect(history.length).toBe(4);
        expect(history[0].characteristicUuid).toBe(CLOCK_TIME_CHAR_UUID.toLowerCase());
        expect(history[1].characteristicUuid).toBe(CLOCK_TIMEZONE_CHAR_UUID.toLowerCase());
        expect(history[2].characteristicUuid).toBe(CLOCK_TIMEMODE_CHAR_UUID.toLowerCase());
        expect(history[3].characteristicUuid).toBe(CLOCK_DST_CHAR_UUID.toLowerCase());
      });

      it('F7-2: writes exact expected byte lengths conforming to Zephyr clock_service.c', async () => {
        await syncClock('F91-WATCH-SIM-01', mockBle);
        const history = mockBle.getWriteHistory();

        expect(history[0].data.byteLength).toBe(CLOCK_PAYLOAD_LENGTHS.TIME); // 4
        expect(history[1].data.byteLength).toBe(CLOCK_PAYLOAD_LENGTHS.TIMEZONE); // 2
        expect(history[2].data.byteLength).toBe(CLOCK_PAYLOAD_LENGTHS.TIMEMODE); // 1
        expect(history[3].data.byteLength).toBe(CLOCK_PAYLOAD_LENGTHS.DST); // 1
      });

      it('F7-3: tracks step-by-step progress callbacks through 100% completion', async () => {
        const steps: SyncProgress[] = [];
        await syncClock('F91-WATCH-SIM-01', mockBle, {
          onProgress: (prog) => steps.push(prog),
        });

        expect(steps.map((s) => s.step)).toEqual([
          'IDLE',
          'TIME',
          'TIMEZONE',
          'TIMEMODE',
          'DST',
          'COMPLETED',
        ]);
        expect(steps[steps.length - 1].percent).toBe(100);
      });

      it('F7-4: updates simulated watch registers through sequential writes', async () => {
        const targetDate = new Date('2026-10-05T12:30:00Z');
        await syncClock('F91-WATCH-SIM-01', mockBle, {
          date: targetDate,
          timezoneOffsetMinutes: -300,
          is24Hour: true,
          isDst: false,
        });

        const watchState = mockBle.getWatchState();
        expect(watchState.clockTime).toBe(Math.floor(targetDate.getTime() / 1000));
        expect(watchState.clockTimezone).toBe(-300);
        expect(watchState.clockTimeMode).toBe(1);
        expect(watchState.clockDst).toBe(0);
      });

      it('F7-5: returns detailed structured SyncResult with duration, steps, and hex payloads', async () => {
        const result = await syncClock('F91-WATCH-SIM-01', mockBle, {
          is24Hour: true,
          timezoneOffsetMinutes: 0,
        });

        expect(result.stepsCompleted).toBe(4);
        expect(typeof result.durationMs).toBe('number');
        expect(result.payloadHex.time).toBeTruthy();
        expect(result.payloadHex.timezone).toBe('00 00');
        expect(result.payloadHex.timeMode).toBe('01');
      });
    });

    // -----------------------------------------------------------------------
    // Feature 8: UI State & Feedback Behavior
    // -----------------------------------------------------------------------
    describe('F8: UI State & Feedback Behavior', () => {
      let mockBle: MockBleService;

      beforeEach(() => {
        mockBle = new MockBleService();
      });

      it('F8-1: renders initial cold launch view with disconnected badge and disabled sync button', () => {
        render(React.createElement(App, { clientOverride: mockBle }));

        const badge = screen.getByTestId('connection-status-badge');
        expect(badge.getAttribute('data-status')).toBe('disconnected');
        expect(screen.getByText('Disconnected')).toBeTruthy();

        const syncBtn = screen.getByTestId('manual-sync-button') as HTMLButtonElement;
        expect(syncBtn.disabled).toBe(true);
      });

      it('F8-2: allows toggling between Simulated Watch and Hardware BLE drivers', () => {
        render(React.createElement(App, { clientOverride: mockBle }));

        const mockBtn = screen.getByTestId('driver-mock-btn');
        const hwBtn = screen.getByTestId('driver-hardware-btn');

        fireEvent.click(hwBtn);
        expect(hwBtn.className).toContain('bg-indigo-600');

        fireEvent.click(mockBtn);
        expect(mockBtn.className).toContain('bg-indigo-600');
      });

      it('F8-3: scans for peripherals and updates list with discovered watch', async () => {
        render(React.createElement(App, { clientOverride: mockBle }));

        const scanBtn = screen.getByTestId('scan-button');
        await act(async () => {
          fireEvent.click(scanBtn);
        });

        const devCard = await screen.findByTestId('connect-btn-F91-WATCH-SIM-01');
        expect(devCard).toBeTruthy();
        expect(screen.getAllByText('F91_Jepler').length).toBeGreaterThanOrEqual(1);
      });

      it('F8-4: connects to discovered watch and updates status badge to connected', async () => {
        render(React.createElement(App, { clientOverride: mockBle }));

        await act(async () => {
          fireEvent.click(screen.getByTestId('scan-button'));
        });

        const connectBtn = await screen.findByTestId('connect-btn-F91-WATCH-SIM-01');
        await act(async () => {
          fireEvent.click(connectBtn);
        });

        await waitFor(() => {
          expect(screen.getByTestId('connection-status-badge').getAttribute('data-status')).toBe(
            'connected'
          );
        });
        expect(screen.getByText('Connected')).toBeTruthy();
      });

      it('F8-5: triggers manual sync on click and updates Last Synced readout', async () => {
        render(React.createElement(App, { clientOverride: mockBle }));

        await act(async () => {
          fireEvent.click(screen.getByTestId('scan-button'));
        });

        const connectBtn = await screen.findByTestId('connect-btn-F91-WATCH-SIM-01');
        await act(async () => {
          fireEvent.click(connectBtn);
        });

        await waitFor(() => {
          expect(screen.getByTestId('connection-status-badge').getAttribute('data-status')).toBe(
            'connected'
          );
        });

        const syncBtn = screen.getByTestId('manual-sync-button');
        await act(async () => {
          fireEvent.click(syncBtn);
        });

        await waitFor(() => {
          expect(screen.getByTestId('last-synced-time').textContent).not.toBe('Never');
        });
        expect(screen.getByText('4/4 GATT Writes OK')).toBeTruthy();
      });
    });
  });

  // =========================================================================
  // TIER 2: BOUNDARY & CORNER CASES (40 Tests)
  // =========================================================================
  describe('Tier 2: Boundary & Corner Cases Suite', () => {
    // -----------------------------------------------------------------------
    // B1: Epoch Timestamp Boundaries & Range Validation (8 tests)
    // -----------------------------------------------------------------------
    describe('B1: Epoch Timestamp Boundaries & Range Validation', () => {
      it('B1-1: serializes epoch zero (1970-01-01T00:00:00Z) to [0x00, 0x00, 0x00, 0x00]', () => {
        const bytes = serializeTime(0);
        expect(Array.from(bytes)).toEqual([0x00, 0x00, 0x00, 0x00]);
        expect(deserializeTime(bytes)).toBe(0);
      });

      it('B1-2: serializes epoch 1 (1970-01-01T00:00:01Z) to [0x01, 0x00, 0x00, 0x00]', () => {
        const bytes = serializeTime(1);
        expect(Array.from(bytes)).toEqual([0x01, 0x00, 0x00, 0x00]);
        expect(deserializeTime(bytes)).toBe(1);
      });

      it('B1-3: serializes max 32-bit uint32 (4294967295) to [0xFF, 0xFF, 0xFF, 0xFF]', () => {
        const bytes = serializeTime(0xffffffff);
        expect(Array.from(bytes)).toEqual([0xff, 0xff, 0xff, 0xff]);
        expect(deserializeTime(bytes)).toBe(4294967295);
      });

      it('B1-4: serializes max uint32 - 1 (4294967294) to [0xFE, 0xFF, 0xFF, 0xFF]', () => {
        const bytes = serializeTime(0xfffffffe);
        expect(Array.from(bytes)).toEqual([0xfe, 0xff, 0xff, 0xff]);
        expect(deserializeTime(bytes)).toBe(4294967294);
      });

      it('B1-5: throws RangeError on negative timestamp (-1)', () => {
        expect(() => serializeTime(-1)).toThrow(RangeError);
      });

      it('B1-6: throws RangeError on uint32 overflow (4294967296)', () => {
        expect(() => serializeTime(0x100000000)).toThrow(RangeError);
      });

      it('B1-7: throws RangeError on NaN timestamp', () => {
        expect(() => serializeTime(NaN)).toThrow(RangeError);
      });

      it('B1-8: throws RangeError on Infinity timestamp', () => {
        expect(() => serializeTime(Infinity)).toThrow(RangeError);
        expect(() => serializeTime(-Infinity)).toThrow(RangeError);
      });
    });

    // -----------------------------------------------------------------------
    // B2: Timezone Offsets & Fractional Minute Boundaries (10 tests)
    // -----------------------------------------------------------------------
    describe('B2: Timezone Offsets & Fractional Minute Boundaries', () => {
      it('B2-1: serializes minimum signed int16 (-32768) to [0x00, 0x80]', () => {
        const bytes = serializeTimezone(-32768);
        expect(Array.from(bytes)).toEqual([0x00, 0x80]);
        expect(deserializeTimezone(bytes)).toBe(-32768);
      });

      it('B2-2: serializes maximum signed int16 (32767) to [0xFF, 0x7F]', () => {
        const bytes = serializeTimezone(32767);
        expect(Array.from(bytes)).toEqual([0xff, 0x7f]);
        expect(deserializeTimezone(bytes)).toBe(32767);
      });

      it('B2-3: throws RangeError on int16 timezone underflow (-32769)', () => {
        expect(() => serializeTimezone(-32769)).toThrow(RangeError);
      });

      it('B2-4: throws RangeError on int16 timezone overflow (32768)', () => {
        expect(() => serializeTimezone(32768)).toThrow(RangeError);
      });

      it('B2-5: serializes maximum practical western timezone UTC-12:00 (-720 min) to [0x30, 0xFD]', () => {
        // -720 as int16 is 0xFD30 -> LE: [0x30, 0xFD]
        const bytes = serializeTimezone(-720);
        expect(Array.from(bytes)).toEqual([0x30, 0xfd]);
        expect(deserializeTimezone(bytes)).toBe(-720);
      });

      it('B2-6: serializes maximum practical eastern timezone UTC+14:00 (+840 min) to [0x48, 0x03]', () => {
        // +840 is 0x0348 -> LE: [0x48, 0x03]
        const bytes = serializeTimezone(840);
        expect(Array.from(bytes)).toEqual([0x48, 0x03]);
        expect(deserializeTimezone(bytes)).toBe(840);
      });

      it('B2-7: serializes 45-minute offset UTC+05:45 (Nepal, +345 min) to [0x59, 0x01]', () => {
        // +345 is 0x0159 -> LE: [0x59, 0x01]
        const bytes = serializeTimezone(345);
        expect(Array.from(bytes)).toEqual([0x59, 0x01]);
        expect(deserializeTimezone(bytes)).toBe(345);
      });

      it('B2-8: serializes 45-minute offset UTC+12:45 (Chatham Islands, +765 min) to [0xFD, 0x02]', () => {
        // +765 is 0x02FD -> LE: [0xFD, 0x02]
        const bytes = serializeTimezone(765);
        expect(Array.from(bytes)).toEqual([0xfd, 0x02]);
        expect(deserializeTimezone(bytes)).toBe(765);
      });

      it('B2-9: rounds fractional minute offsets cleanly to nearest integer', () => {
        // 330.4 -> 330
        const bytes1 = serializeTimezone(330.4);
        expect(deserializeTimezone(bytes1)).toBe(330);

        // 330.6 -> 331
        const bytes2 = serializeTimezone(330.6);
        expect(deserializeTimezone(bytes2)).toBe(331);
      });

      it('B2-10: formats negative single-digit minute offset correctly (e.g. -30 min -> UTC-00:30)', () => {
        expect(formatTimezoneOffset(-30)).toBe('UTC-00:30');
        expect(formatTimezoneOffset(45)).toBe('UTC+00:45');
      });
    });

    // -----------------------------------------------------------------------
    // B3: Malformed Payload Buffers & Buffer Length Verification (12 tests)
    // -----------------------------------------------------------------------
    describe('B3: Malformed Payload Buffers & Buffer Length Verification', () => {
      it('B3-1: deserializeTime rejects empty 0-byte buffer', () => {
        expect(() => deserializeTime(new Uint8Array(0))).toThrow(/Invalid Time payload length/);
      });

      it('B3-2: deserializeTime rejects 3-byte buffer (off-by-one underflow)', () => {
        expect(() => deserializeTime(new Uint8Array(3))).toThrow(/Invalid Time payload length/);
      });

      it('B3-3: deserializeTime rejects 5-byte buffer (off-by-one overflow)', () => {
        expect(() => deserializeTime(new Uint8Array(5))).toThrow(/Invalid Time payload length/);
      });

      it('B3-4: deserializeTime rejects 8-byte buffer', () => {
        expect(() => deserializeTime(new Uint8Array(8))).toThrow(/Invalid Time payload length/);
      });

      it('B3-5: deserializeTimezone rejects empty 0-byte buffer', () => {
        expect(() => deserializeTimezone(new Uint8Array(0))).toThrow(
          /Invalid Timezone payload length/
        );
      });

      it('B3-6: deserializeTimezone rejects 1-byte buffer (off-by-one underflow)', () => {
        expect(() => deserializeTimezone(new Uint8Array(1))).toThrow(
          /Invalid Timezone payload length/
        );
      });

      it('B3-7: deserializeTimezone rejects 3-byte buffer (off-by-one overflow)', () => {
        expect(() => deserializeTimezone(new Uint8Array(3))).toThrow(
          /Invalid Timezone payload length/
        );
      });

      it('B3-8: deserializeTimeMode rejects empty 0-byte buffer', () => {
        expect(() => deserializeTimeMode(new Uint8Array(0))).toThrow(
          /Invalid Time Mode payload length/
        );
      });

      it('B3-9: deserializeTimeMode rejects 2-byte buffer (off-by-one overflow)', () => {
        expect(() => deserializeTimeMode(new Uint8Array(2))).toThrow(
          /Invalid Time Mode payload length/
        );
      });

      it('B3-10: deserializeDst rejects empty 0-byte buffer', () => {
        expect(() => deserializeDst(new Uint8Array(0))).toThrow(/Invalid DST payload length/);
      });

      it('B3-11: deserializeDst rejects 2-byte buffer (off-by-one overflow)', () => {
        expect(() => deserializeDst(new Uint8Array(2))).toThrow(/Invalid DST payload length/);
      });

      it('B3-12: deserializeClockSyncPayload rejects when any member buffer is corrupted', () => {
        expect(() =>
          deserializeClockSyncPayload({
            timeBytes: new Uint8Array(4),
            timezoneBytes: new Uint8Array(3), // Invalid
            timeModeBytes: new Uint8Array(1),
            dstBytes: new Uint8Array(1),
          })
        ).toThrow(/Invalid Timezone payload length/);
      });
    });

    // -----------------------------------------------------------------------
    // B4: GATT Server Error Responses & ATT Offset Verification (10 tests)
    // -----------------------------------------------------------------------
    describe('B4: GATT Server Error Responses & ATT Offset Verification', () => {
      let mockBle: MockBleService;

      beforeEach(async () => {
        mockBle = new MockBleService();
        await mockBle.initialize();
        await mockBle.connect('F91-WATCH-SIM-01');
      });

      it('B4-1: MockBleService rejects write to Time characteristic with 3 bytes (BT_ATT_ERR_INVALID_ATTRIBUTE_LEN 0xd)', async () => {
        await expect(
          mockBle.writeCharacteristic(
            'F91-WATCH-SIM-01',
            CLOCK_SERVICE_UUID,
            CLOCK_TIME_CHAR_UUID,
            new Uint8Array(3)
          )
        ).rejects.toThrow(/0xd \(BT_ATT_ERR_INVALID_ATTRIBUTE_LEN\)/);
      });

      it('B4-2: MockBleService rejects write to Time characteristic with 5 bytes', async () => {
        await expect(
          mockBle.writeCharacteristic(
            'F91-WATCH-SIM-01',
            CLOCK_SERVICE_UUID,
            CLOCK_TIME_CHAR_UUID,
            new Uint8Array(5)
          )
        ).rejects.toThrow(/0xd \(BT_ATT_ERR_INVALID_ATTRIBUTE_LEN\)/);
      });

      it('B4-3: MockBleService rejects write to Timezone characteristic with 1 byte', async () => {
        await expect(
          mockBle.writeCharacteristic(
            'F91-WATCH-SIM-01',
            CLOCK_SERVICE_UUID,
            CLOCK_TIMEZONE_CHAR_UUID,
            new Uint8Array(1)
          )
        ).rejects.toThrow(/0xd \(BT_ATT_ERR_INVALID_ATTRIBUTE_LEN\)/);
      });

      it('B4-4: MockBleService rejects write to Timezone characteristic with 3 bytes', async () => {
        await expect(
          mockBle.writeCharacteristic(
            'F91-WATCH-SIM-01',
            CLOCK_SERVICE_UUID,
            CLOCK_TIMEZONE_CHAR_UUID,
            new Uint8Array(3)
          )
        ).rejects.toThrow(/0xd \(BT_ATT_ERR_INVALID_ATTRIBUTE_LEN\)/);
      });

      it('B4-5: MockBleService rejects write to Time Mode characteristic with 0 bytes', async () => {
        await expect(
          mockBle.writeCharacteristic(
            'F91-WATCH-SIM-01',
            CLOCK_SERVICE_UUID,
            CLOCK_TIMEMODE_CHAR_UUID,
            new Uint8Array(0)
          )
        ).rejects.toThrow(/0xd \(BT_ATT_ERR_INVALID_ATTRIBUTE_LEN\)/);
      });

      it('B4-6: MockBleService rejects write to Time Mode characteristic with 2 bytes', async () => {
        await expect(
          mockBle.writeCharacteristic(
            'F91-WATCH-SIM-01',
            CLOCK_SERVICE_UUID,
            CLOCK_TIMEMODE_CHAR_UUID,
            new Uint8Array(2)
          )
        ).rejects.toThrow(/0xd \(BT_ATT_ERR_INVALID_ATTRIBUTE_LEN\)/);
      });

      it('B4-7: MockBleService rejects write to DST characteristic with 0 bytes', async () => {
        await expect(
          mockBle.writeCharacteristic(
            'F91-WATCH-SIM-01',
            CLOCK_SERVICE_UUID,
            CLOCK_DST_CHAR_UUID,
            new Uint8Array(0)
          )
        ).rejects.toThrow(/0xd \(BT_ATT_ERR_INVALID_ATTRIBUTE_LEN\)/);
      });

      it('B4-8: MockBleService rejects write to DST characteristic with 2 bytes', async () => {
        await expect(
          mockBle.writeCharacteristic(
            'F91-WATCH-SIM-01',
            CLOCK_SERVICE_UUID,
            CLOCK_DST_CHAR_UUID,
            new Uint8Array(2)
          )
        ).rejects.toThrow(/0xd \(BT_ATT_ERR_INVALID_ATTRIBUTE_LEN\)/);
      });

      it('B4-9: MockBleService rejects write to unknown characteristic UUID', async () => {
        await expect(
          mockBle.writeCharacteristic(
            'F91-WATCH-SIM-01',
            CLOCK_SERVICE_UUID,
            '00000000-0000-0000-0000-000000000000',
            new Uint8Array(4)
          )
        ).rejects.toThrow(/Unknown characteristic UUID/);
      });

      it('B4-10: MockBleService rejects write to unknown service UUID', async () => {
        await expect(
          mockBle.writeCharacteristic(
            'F91-WATCH-SIM-01',
            '11111111-1111-1111-1111-111111111111',
            CLOCK_TIME_CHAR_UUID,
            new Uint8Array(4)
          )
        ).rejects.toThrow(/Unknown service UUID/);
      });
    });
  });

  // =========================================================================
  // TIER 3: PAIRWISE FEATURE COMBINATIONS & FAULT RECOVERY (16 Tests)
  // =========================================================================
  describe('Tier 3: Pairwise Combinations & Fault Recovery Suite', () => {
    let mockBle: MockBleService;

    beforeEach(async () => {
      mockBle = new MockBleService();
      await mockBle.initialize();
      await mockBle.connect('F91-WATCH-SIM-01');
    });

    it('T3-1: Pairwise (12h format x Standard Time): Mode=0, DST=0 written and verified', async () => {
      await syncClock('F91-WATCH-SIM-01', mockBle, { is24Hour: false, isDst: false });
      const state = mockBle.getWatchState();
      expect(state.clockTimeMode).toBe(0);
      expect(state.clockDst).toBe(0);
    });

    it('T3-2: Pairwise (12h format x Daylight Saving Time): Mode=0, DST=1 written and verified', async () => {
      await syncClock('F91-WATCH-SIM-01', mockBle, { is24Hour: false, isDst: true });
      const state = mockBle.getWatchState();
      expect(state.clockTimeMode).toBe(0);
      expect(state.clockDst).toBe(1);
    });

    it('T3-3: Pairwise (24h format x Standard Time): Mode=1, DST=0 written and verified', async () => {
      await syncClock('F91-WATCH-SIM-01', mockBle, { is24Hour: true, isDst: false });
      const state = mockBle.getWatchState();
      expect(state.clockTimeMode).toBe(1);
      expect(state.clockDst).toBe(0);
    });

    it('T3-4: Pairwise (24h format x Daylight Saving Time): Mode=1, DST=1 written and verified', async () => {
      await syncClock('F91-WATCH-SIM-01', mockBle, { is24Hour: true, isDst: true });
      const state = mockBle.getWatchState();
      expect(state.clockTimeMode).toBe(1);
      expect(state.clockDst).toBe(1);
    });

    it('T3-5: Pairwise (High positive TZ +840 x 24h format x DST active)', async () => {
      await syncClock('F91-WATCH-SIM-01', mockBle, {
        timezoneOffsetMinutes: 840,
        is24Hour: true,
        isDst: true,
      });
      const state = mockBle.getWatchState();
      expect(state.clockTimezone).toBe(840);
      expect(state.clockTimeMode).toBe(1);
      expect(state.clockDst).toBe(1);
    });

    it('T3-6: Pairwise (High negative TZ -720 x 12h format x Standard Time)', async () => {
      await syncClock('F91-WATCH-SIM-01', mockBle, {
        timezoneOffsetMinutes: -720,
        is24Hour: false,
        isDst: false,
      });
      const state = mockBle.getWatchState();
      expect(state.clockTimezone).toBe(-720);
      expect(state.clockTimeMode).toBe(0);
      expect(state.clockDst).toBe(0);
    });

    it('T3-7: Pairwise (Half-hour TZ +330 IST x 24h format x Standard Time)', async () => {
      await syncClock('F91-WATCH-SIM-01', mockBle, {
        timezoneOffsetMinutes: 330,
        is24Hour: true,
        isDst: false,
      });
      const state = mockBle.getWatchState();
      expect(state.clockTimezone).toBe(330);
      expect(state.clockTimeMode).toBe(1);
      expect(state.clockDst).toBe(0);
    });

    it('T3-8: Link drop during Step 1 (Time write) halts sync and raises SyncDisconnectedError', async () => {
      // Inject disconnect on next write
      mockBle.failNextWrite(CLOCK_TIME_CHAR_UUID, 'Link dropped');
      mockBle.simulateDisconnect('F91-WATCH-SIM-01');

      await expect(syncClock('F91-WATCH-SIM-01', mockBle)).rejects.toThrow(
        SyncDisconnectedError
      );
    });

    it('T3-9: Link drop during Step 2 (Timezone write) halts pipeline after Time write', async () => {
      // Let Time write succeed, then disconnect
      const origWrite = mockBle.writeCharacteristic.bind(mockBle);
      vi.spyOn(mockBle, 'writeCharacteristic').mockImplementation(
        async (devId, sUuid, cUuid, data) => {
          if (cUuid.toLowerCase() === CLOCK_TIMEZONE_CHAR_UUID.toLowerCase()) {
            mockBle.simulateDisconnect(devId);
            throw new Error('Link dropped on Timezone');
          }
          return origWrite(devId, sUuid, cUuid, data);
        }
      );

      await expect(syncClock('F91-WATCH-SIM-01', mockBle)).rejects.toThrow(
        SyncDisconnectedError
      );
      // History should only contain the first write
      expect(mockBle.getWriteHistory().length).toBe(1);
      expect(mockBle.getWriteHistory()[0].characteristicUuid).toBe(
        CLOCK_TIME_CHAR_UUID.toLowerCase()
      );
    });

    it('T3-10: Link drop during Step 3 (Time Mode write) halts pipeline after 2 writes', async () => {
      const origWrite = mockBle.writeCharacteristic.bind(mockBle);
      vi.spyOn(mockBle, 'writeCharacteristic').mockImplementation(
        async (devId, sUuid, cUuid, data) => {
          if (cUuid.toLowerCase() === CLOCK_TIMEMODE_CHAR_UUID.toLowerCase()) {
            mockBle.simulateDisconnect(devId);
            throw new Error('Link dropped on Time Mode');
          }
          return origWrite(devId, sUuid, cUuid, data);
        }
      );

      await expect(syncClock('F91-WATCH-SIM-01', mockBle)).rejects.toThrow(
        SyncDisconnectedError
      );
      expect(mockBle.getWriteHistory().length).toBe(2);
    });

    it('T3-11: Link drop during Step 4 (DST write) halts pipeline after 3 writes', async () => {
      const origWrite = mockBle.writeCharacteristic.bind(mockBle);
      vi.spyOn(mockBle, 'writeCharacteristic').mockImplementation(
        async (devId, sUuid, cUuid, data) => {
          if (cUuid.toLowerCase() === CLOCK_DST_CHAR_UUID.toLowerCase()) {
            mockBle.simulateDisconnect(devId);
            throw new Error('Link dropped on DST');
          }
          return origWrite(devId, sUuid, cUuid, data);
        }
      );

      await expect(syncClock('F91-WATCH-SIM-01', mockBle)).rejects.toThrow(
        SyncDisconnectedError
      );
      expect(mockBle.getWriteHistory().length).toBe(3);
    });

    it('T3-12: Disconnect prior to sync initiation throws SyncDisconnectedError without any writes', async () => {
      await mockBle.disconnect('F91-WATCH-SIM-01');
      await expect(syncClock('F91-WATCH-SIM-01', mockBle)).rejects.toThrow(
        SyncDisconnectedError
      );
      expect(mockBle.getWriteHistory().length).toBe(0);
    });

    it('T3-13: Scan timeout recovery cleanly stops scan and returns hook to DISCONNECTED', async () => {
      const { result } = renderHook(() =>
        useBleConnection(mockBle, { scanTimeoutMs: 50 })
      );

      await act(async () => {
        await result.current.startScan(50);
      });
      expect(result.current.status).toBe('SCANNING');

      // Await scan timeout expiration and status transition
      await waitFor(
        () => {
          expect(result.current.status).toBe('DISCONNECTED');
        },
        { timeout: 1000 }
      );
    });

    it('T3-14: Write timeout on stalled GATT characteristic raises SyncTimeoutError without terminating connection', async () => {
      // Simulate hanging write with latency longer than timeout
      mockBle.setWriteLatency(100);

      await expect(
        syncClock('F91-WATCH-SIM-01', mockBle, { timeoutMs: 20 })
      ).rejects.toThrow(SyncTimeoutError);

      // Verify BLE connection is still reported as alive
      expect(await mockBle.isConnected('F91-WATCH-SIM-01')).toBe(true);
    });

    it('T3-15: GATT write failure on Step 2 leaves Step 1 applied in GATT DB and halts', async () => {
      const origWrite = mockBle.writeCharacteristic.bind(mockBle);
      vi.spyOn(mockBle, 'writeCharacteristic').mockImplementation(
        async (devId, sUuid, cUuid, data) => {
          if (cUuid.toLowerCase() === CLOCK_TIMEZONE_CHAR_UUID.toLowerCase()) {
            throw new Error('GATT ATT Error 0x0E: Unlikely Error');
          }
          return origWrite(devId, sUuid, cUuid, data);
        }
      );

      await expect(syncClock('F91-WATCH-SIM-01', mockBle)).rejects.toThrow(SyncGattError);
      expect(mockBle.getWriteHistory().length).toBe(1);
      expect(mockBle.getWriteHistory()[0].characteristicUuid).toBe(
        CLOCK_TIME_CHAR_UUID.toLowerCase()
      );
    });

    it('T3-16: Connection state machine recovers from SYNC_FAILURE back to CONNECTED allowing retry', () => {
      const fsm = new ConnectionStateMachine({
        status: 'CONNECTED',
        selectedDevice: { deviceId: 'F91-WATCH-SIM-01', name: 'F91_Jepler' },
      });

      fsm.dispatch(connectionActions.startSync());
      expect(fsm.getStatus()).toBe('SYNCING');

      fsm.dispatch(connectionActions.syncFailure('GATT Write Timeout'));
      expect(fsm.getStatus()).toBe('CONNECTED');
      expect(fsm.getState().error).toBe('GATT Write Timeout');

      // Retry sync
      fsm.dispatch(connectionActions.startSync());
      expect(fsm.getStatus()).toBe('SYNCING');
      expect(fsm.getState().error).toBeNull();
    });
  });

  // =========================================================================
  // TIER 4: REAL-WORLD WORKLOAD SCENARIOS (6 Scenarios)
  // =========================================================================
  describe('Tier 4: Real-World Workload Scenarios Suite', () => {
    let mockBle: MockBleService;

    beforeEach(() => {
      mockBle = new MockBleService();
    });

    it('Scenario 1: Complete cold-start user journey (Launch -> Scan -> Discover -> Connect -> Sync -> LCD Verify -> Clean Disconnect)', async () => {
      render(React.createElement(App, { clientOverride: mockBle }));

      // Cold start verification
      expect(screen.getByTestId('connection-status-badge').getAttribute('data-status')).toBe(
        'disconnected'
      );
      expect((screen.getByTestId('manual-sync-button') as HTMLButtonElement).disabled).toBe(true);

      // Step 1: Scan
      await act(async () => {
        fireEvent.click(screen.getByTestId('scan-button'));
      });
      expect(screen.getByTestId('connection-status-badge').getAttribute('data-status')).toBe(
        'scanning'
      );

      // Step 2: Discover and Connect
      const connectBtn = await screen.findByTestId('connect-btn-F91-WATCH-SIM-01');
      await act(async () => {
        fireEvent.click(connectBtn);
      });

      await waitFor(() => {
        expect(screen.getByTestId('connection-status-badge').getAttribute('data-status')).toBe(
          'connected'
        );
      });

      // Step 3: Trigger manual time synchronization
      const syncBtn = screen.getByTestId('manual-sync-button') as HTMLButtonElement;
      expect(syncBtn.disabled).toBe(false);

      await act(async () => {
        fireEvent.click(syncBtn);
      });

      // Step 4: Verify sync feedback and GATT writes
      await waitFor(() => {
        expect(screen.getByTestId('last-synced-time').textContent).not.toBe('Never');
      });
      expect(screen.getByText('4/4 GATT Writes OK')).toBeTruthy();
      expect(mockBle.getWriteHistory().length).toBe(4);

      // Step 5: Verify MockWatchPreview LCD registers updated
      const watchState = mockBle.getWatchState();
      await waitFor(() => {
        expect(screen.getByTestId('watch-registers-time').textContent).toBe(
          String(watchState.clockTime)
        );
      });

      // Step 6: Graceful disconnect
      const disconnectBtn = screen.getByTestId('disconnect-btn-F91-WATCH-SIM-01');
      await act(async () => {
        fireEvent.click(disconnectBtn);
      });

      await waitFor(() => {
        expect(screen.getByTestId('connection-status-badge').getAttribute('data-status')).toBe(
          'disconnected'
        );
      });
      expect((screen.getByTestId('manual-sync-button') as HTMLButtonElement).disabled).toBe(true);
    });

    it('Scenario 2: Consecutive multi-time sync operations with format toggle', async () => {
      await mockBle.initialize();
      await mockBle.connect('F91-WATCH-SIM-01');

      // First sync: 12-hour mode, standard time
      const time1 = 1700000000;
      await syncClock('F91-WATCH-SIM-01', mockBle, {
        date: new Date(time1 * 1000),
        is24Hour: false,
        isDst: false,
        timezoneOffsetMinutes: -300,
      });

      expect(mockBle.getWriteHistory().length).toBe(4);
      let state = mockBle.getWatchState();
      expect(state.clockTime).toBe(time1);
      expect(state.clockTimeMode).toBe(0);

      // Second sync 30 minutes later: toggle to 24-hour mode, DST active
      const time2 = time1 + 1800;
      await syncClock('F91-WATCH-SIM-01', mockBle, {
        date: new Date(time2 * 1000),
        is24Hour: true,
        isDst: true,
        timezoneOffsetMinutes: -240,
      });

      expect(mockBle.getWriteHistory().length).toBe(8);
      state = mockBle.getWatchState();
      expect(state.clockTime).toBe(time2);
      expect(state.clockTimezone).toBe(-240);
      expect(state.clockTimeMode).toBe(1);
      expect(state.clockDst).toBe(1);
    });

    it('Scenario 3: International timezone transition (New York UTC-5 to Tokyo UTC+9)', async () => {
      await mockBle.initialize();
      await mockBle.connect('F91-WATCH-SIM-01');

      // Departure: New York UTC-5 (-300 min), 12-hour format
      const departureTime = 1715000000;
      await syncClock('F91-WATCH-SIM-01', mockBle, {
        date: new Date(departureTime * 1000),
        timezoneOffsetMinutes: -300,
        is24Hour: false,
        isDst: true,
      });

      let watch = mockBle.getWatchState();
      expect(watch.clockTimezone).toBe(-300);
      expect(watch.clockTimeMode).toBe(0);

      // Arrival: Tokyo UTC+9 (+540 min), switch to 24-hour international format
      const arrivalTime = departureTime + 50400; // 14 hours later
      await syncClock('F91-WATCH-SIM-01', mockBle, {
        date: new Date(arrivalTime * 1000),
        timezoneOffsetMinutes: 540,
        is24Hour: true,
        isDst: false, // Japan has no DST
      });

      watch = mockBle.getWatchState();
      expect(watch.clockTime).toBe(arrivalTime);
      expect(watch.clockTimezone).toBe(540);
      expect(watch.clockTimeMode).toBe(1);
      expect(watch.clockDst).toBe(0);
    });

    it('Scenario 4: Mid-sync radio detachment with auto-recovery and subsequent resync', async () => {
      render(React.createElement(App, { clientOverride: mockBle }));

      // Connect to watch
      await act(async () => {
        fireEvent.click(screen.getByTestId('scan-button'));
      });
      const connectBtn = await screen.findByTestId('connect-btn-F91-WATCH-SIM-01');
      await act(async () => {
        fireEvent.click(connectBtn);
      });

      await waitFor(() => {
        expect(screen.getByTestId('connection-status-badge').getAttribute('data-status')).toBe(
          'connected'
        );
      });

      // Trigger mid-sync disconnect
      const origWrite = mockBle.writeCharacteristic.bind(mockBle);
      vi.spyOn(mockBle, 'writeCharacteristic').mockImplementation(
        async (devId, sUuid, cUuid, data) => {
          if (cUuid.toLowerCase() === CLOCK_TIMEZONE_CHAR_UUID.toLowerCase()) {
            mockBle.simulateDisconnect(devId);
            throw new Error('Radio detachment');
          }
          return origWrite(devId, sUuid, cUuid, data);
        }
      );

      const syncBtn = screen.getByTestId('manual-sync-button');
      await act(async () => {
        fireEvent.click(syncBtn);
      });

      // App should transition to disconnected with error banner
      await waitFor(() => {
        expect(screen.getByTestId('connection-status-badge').getAttribute('data-status')).toBe(
          'disconnected'
        );
      });
      expect(screen.getByTestId('error-alert')).toBeTruthy();

      // Dismiss error
      act(() => {
        fireEvent.click(screen.getByTestId('clear-error-button'));
      });
      expect(screen.queryByTestId('error-alert')).toBeNull();

      // Restore clean mock behavior and resync
      vi.restoreAllMocks();
      await act(async () => {
        fireEvent.click(screen.getByTestId('scan-button'));
      });
      const reconnectBtn = await screen.findByTestId('connect-btn-F91-WATCH-SIM-01');
      await act(async () => {
        fireEvent.click(reconnectBtn);
      });

      await waitFor(() => {
        expect(screen.getByTestId('connection-status-badge').getAttribute('data-status')).toBe(
          'connected'
        );
      });

      await act(async () => {
        fireEvent.click(screen.getByTestId('manual-sync-button'));
      });

      await waitFor(() => {
        expect(screen.getByText('4/4 GATT Writes OK')).toBeTruthy();
      });
    });

    it('Scenario 5: Multi-peripheral discovery environment with RF noise and beacons', async () => {
      mockBle.setAvailableDevices([
        {
          deviceId: 'BEACON-01',
          name: 'iBeacon_Proximity',
          rssi: -45,
          services: ['0000feaa-0000-1000-8000-00805f9b34fb'],
        },
        {
          deviceId: 'FITNESS-BAND-02',
          name: 'HeartRateMonitor',
          rssi: -55,
          services: ['0000180d-0000-1000-8000-00805f9b34fb'],
        },
        {
          deviceId: 'F91-WATCH-SIM-01',
          name: F91_DEVICE_NAME,
          rssi: -62,
          services: [CLOCK_SERVICE_UUID],
        },
      ]);

      render(React.createElement(App, { clientOverride: mockBle }));

      await act(async () => {
        fireEvent.click(screen.getByTestId('scan-button'));
      });

      // Only the F91_Jepler device should be displayed in discovery list
      const targetDevice = await screen.findByTestId('connect-btn-F91-WATCH-SIM-01');
      expect(targetDevice).toBeTruthy();
      expect(screen.queryByText('iBeacon_Proximity')).toBeNull();
      expect(screen.queryByText('HeartRateMonitor')).toBeNull();

      // Connect and sync cleanly
      await act(async () => {
        fireEvent.click(targetDevice);
      });

      await waitFor(() => {
        expect(screen.getByTestId('connection-status-badge').getAttribute('data-status')).toBe(
          'connected'
        );
      });

      await act(async () => {
        fireEvent.click(screen.getByTestId('manual-sync-button'));
      });

      await waitFor(() => {
        expect(screen.getByText('4/4 GATT Writes OK')).toBeTruthy();
      });
    });

    it('Scenario 6: High latency BLE link resilience with progress tracking', async () => {
      await mockBle.initialize();
      await mockBle.connect('F91-WATCH-SIM-01');

      // Inject 25ms latency per GATT write
      mockBle.setWriteLatency(25);

      const progressSnapshots: SyncProgress[] = [];
      const startTime = Date.now();

      const result = await syncClock('F91-WATCH-SIM-01', mockBle, {
        timeoutMs: 5000,
        onProgress: (prog) => progressSnapshots.push({ ...prog }),
      });

      const elapsed = Date.now() - startTime;
      expect(result.success).toBe(true);
      expect(elapsed).toBeGreaterThanOrEqual(90); // 4 writes * 25ms ~ 100ms
      expect(progressSnapshots.length).toBe(6);
      expect(progressSnapshots[progressSnapshots.length - 1].step).toBe('COMPLETED');
    });
  });
});
