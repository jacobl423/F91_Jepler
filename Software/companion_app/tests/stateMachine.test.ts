import { describe, it, expect, beforeEach, vi } from 'vitest';
import { renderHook, act } from '@testing-library/react';
import {
  ConnectionStateMachine,
  connectionReducer,
  connectionActions,
  isValidTransition,
  InvalidTransitionError,
  initialConnectionState,
  ConnectionStatus,
  ConnectionEvent,
  VALID_TRANSITIONS,
} from '../src/state/connectionStateMachine';
import { useBleConnection } from '../src/state/useBleConnection';
import { MockBleService } from '../src/ble/mockBleService';
import { BleDevice } from '../src/ble/bleClientInterface';
import { F91_DEVICE_NAME, CLOCK_SERVICE_UUID } from '../src/ble/gattConstants';

describe('Connection State Machine & Transitions (Milestone 3)', () => {
  let sm: ConnectionStateMachine;

  const mockDevice: BleDevice = {
    deviceId: 'F91-WATCH-SIM-01',
    name: F91_DEVICE_NAME,
    rssi: -58,
    services: [CLOCK_SERVICE_UUID],
  };

  const alternateDevice: BleDevice = {
    deviceId: 'F91-WATCH-SIM-02',
    name: 'F91_Jepler_2',
    rssi: -72,
    services: [CLOCK_SERVICE_UUID],
  };

  beforeEach(() => {
    sm = new ConnectionStateMachine();
  });

  describe('SM-1: Initialization & Baseline State', () => {
    it('should initialize in DISCONNECTED state with default values', () => {
      const state = sm.getState();
      expect(state.status).toBe('DISCONNECTED');
      expect(state.selectedDevice).toBeNull();
      expect(state.discoveredDevices).toEqual([]);
      expect(state.error).toBeNull();
      expect(state.lastSyncedAt).toBeNull();
      expect(sm.getStatus()).toBe('DISCONNECTED');
    });

    it('should support custom initial state', () => {
      const customSm = new ConnectionStateMachine({
        status: 'CONNECTED',
        selectedDevice: mockDevice,
      });
      expect(customSm.getStatus()).toBe('CONNECTED');
      expect(customSm.getState().selectedDevice).toEqual(mockDevice);
    });

    it('should reset cleanly to initial state', () => {
      sm.transition('START_SCAN');
      expect(sm.getStatus()).toBe('SCANNING');
      sm.reset();
      expect(sm.getStatus()).toBe('DISCONNECTED');
      expect(sm.getState().discoveredDevices).toEqual([]);
    });
  });

  describe('SM-2: Scanning Lifecycle & Peripheral Discovery', () => {
    it('should transition DISCONNECTED -> SCANNING on START_SCAN and reset devices & error', () => {
      // Setup dirty state with an error
      const dirtySm = new ConnectionStateMachine({
        error: 'Previous scan error',
        discoveredDevices: [alternateDevice],
      });

      dirtySm.dispatch(connectionActions.startScan());
      const state = dirtySm.getState();
      expect(state.status).toBe('SCANNING');
      expect(state.discoveredDevices).toEqual([]);
      expect(state.error).toBeNull();
    });

    it('should accumulate discovered peripherals on DEVICE_FOUND', () => {
      sm.dispatch(connectionActions.startScan());
      sm.dispatch(connectionActions.deviceFound(mockDevice));

      expect(sm.getStatus()).toBe('SCANNING');
      expect(sm.getState().discoveredDevices).toHaveLength(1);
      expect(sm.getState().discoveredDevices[0]).toEqual(mockDevice);

      sm.dispatch(connectionActions.deviceFound(alternateDevice));
      expect(sm.getState().discoveredDevices).toHaveLength(2);
    });

    it('should deduplicate peripherals by deviceId and update RSSI in place', () => {
      sm.dispatch(connectionActions.startScan());
      sm.dispatch(connectionActions.deviceFound(mockDevice));

      const updatedMock: BleDevice = {
        ...mockDevice,
        rssi: -42, // Improved signal strength
      };
      sm.dispatch(connectionActions.deviceFound(updatedMock));

      expect(sm.getState().discoveredDevices).toHaveLength(1);
      expect(sm.getState().discoveredDevices[0].rssi).toBe(-42);
    });

    it('should transition SCANNING -> DISCONNECTED on STOP_SCAN preserving discovered devices', () => {
      sm.dispatch(connectionActions.startScan());
      sm.dispatch(connectionActions.deviceFound(mockDevice));
      sm.dispatch(connectionActions.stopScan());

      const state = sm.getState();
      expect(state.status).toBe('DISCONNECTED');
      expect(state.discoveredDevices).toHaveLength(1);
      expect(state.discoveredDevices[0].deviceId).toBe(mockDevice.deviceId);
    });
  });

  describe('SM-3: Connection Lifecycle & Error Transitions', () => {
    it('should transition SCANNING -> CONNECTING on SELECT_DEVICE', () => {
      sm.dispatch(connectionActions.startScan());
      sm.dispatch(connectionActions.selectDevice(mockDevice));

      expect(sm.getStatus()).toBe('CONNECTING');
      expect(sm.getState().selectedDevice).toEqual(mockDevice);
      expect(sm.getState().error).toBeNull();
    });

    it('should transition DISCONNECTED -> CONNECTING on SELECT_DEVICE directly', () => {
      sm.dispatch(connectionActions.selectDevice(mockDevice));

      expect(sm.getStatus()).toBe('CONNECTING');
      expect(sm.getState().selectedDevice).toEqual(mockDevice);
    });

    it('should transition CONNECTING -> CONNECTED on CONNECT_SUCCESS', () => {
      sm.dispatch(connectionActions.selectDevice(mockDevice));
      sm.dispatch(connectionActions.connectSuccess(mockDevice));

      expect(sm.getStatus()).toBe('CONNECTED');
      expect(sm.getState().selectedDevice).toEqual(mockDevice);
      expect(sm.getState().error).toBeNull();
    });

    it('should transition CONNECTING -> ERROR on CONNECT_FAILURE', () => {
      sm.dispatch(connectionActions.selectDevice(mockDevice));
      sm.dispatch(connectionActions.connectFailure('GATT connection timed out'));

      const state = sm.getState();
      expect(state.status).toBe('ERROR');
      expect(state.error).toBe('GATT connection timed out');
      expect(state.selectedDevice).toBeNull();
    });

    it('should allow recovery from ERROR directly via START_SCAN', () => {
      sm.dispatch(connectionActions.selectDevice(mockDevice));
      sm.dispatch(connectionActions.connectFailure('Fatal link error'));
      expect(sm.getStatus()).toBe('ERROR');

      sm.dispatch(connectionActions.startScan());
      expect(sm.getStatus()).toBe('SCANNING');
      expect(sm.getState().error).toBeNull();
    });

    it('should allow recovery from ERROR directly via SELECT_DEVICE', () => {
      sm.dispatch(connectionActions.selectDevice(mockDevice));
      sm.dispatch(connectionActions.connectFailure('Failed connection'));
      expect(sm.getStatus()).toBe('ERROR');

      sm.dispatch(connectionActions.selectDevice(mockDevice));
      expect(sm.getStatus()).toBe('CONNECTING');
      expect(sm.getState().error).toBeNull();
    });

    it('should transition ERROR -> DISCONNECTED on CLEAR_ERROR', () => {
      sm.dispatch(connectionActions.selectDevice(mockDevice));
      sm.dispatch(connectionActions.connectFailure('Temporary failure'));
      expect(sm.getStatus()).toBe('ERROR');

      sm.dispatch(connectionActions.clearError());
      expect(sm.getStatus()).toBe('DISCONNECTED');
      expect(sm.getState().error).toBeNull();
    });
  });

  describe('SM-4: Clock Synchronization Transitions', () => {
    beforeEach(() => {
      sm.dispatch(connectionActions.selectDevice(mockDevice));
      sm.dispatch(connectionActions.connectSuccess(mockDevice));
      expect(sm.getStatus()).toBe('CONNECTED');
    });

    it('should transition CONNECTED -> SYNCING on START_SYNC', () => {
      sm.dispatch(connectionActions.startSync());
      expect(sm.getStatus()).toBe('SYNCING');
      expect(sm.getState().error).toBeNull();
    });

    it('should transition SYNCING -> CONNECTED on SYNC_SUCCESS and update lastSyncedAt', () => {
      sm.dispatch(connectionActions.startSync());
      const syncDate = new Date('2026-10-05T04:15:00Z');
      sm.dispatch(connectionActions.syncSuccess(syncDate));

      const state = sm.getState();
      expect(state.status).toBe('CONNECTED');
      expect(state.lastSyncedAt).toEqual(syncDate);
      expect(state.error).toBeNull();
    });

    it('should transition SYNCING -> CONNECTED on SYNC_FAILURE and preserve connection', () => {
      sm.dispatch(connectionActions.startSync());
      sm.dispatch(connectionActions.syncFailure('GATT Write Timeout for Timezone'));

      const state = sm.getState();
      expect(state.status).toBe('CONNECTED');
      expect(state.error).toBe('GATT Write Timeout for Timezone');
      expect(state.selectedDevice).toEqual(mockDevice); // Link remains open!
    });

    it('should clear sync error via CLEAR_ERROR while preserving CONNECTED state', () => {
      sm.dispatch(connectionActions.startSync());
      sm.dispatch(connectionActions.syncFailure('GATT Write Timeout'));
      expect(sm.getState().error).toBe('GATT Write Timeout');

      sm.dispatch(connectionActions.clearError());
      expect(sm.getStatus()).toBe('CONNECTED');
      expect(sm.getState().error).toBeNull();
    });
  });

  describe('SM-5: Universal Disconnect Handling (No Unhandled Exceptions)', () => {
    const allStates: ConnectionStatus[] = [
      'DISCONNECTED',
      'SCANNING',
      'CONNECTING',
      'CONNECTED',
      'SYNCING',
      'ERROR',
    ];

    it.each(allStates)(
      'should handle DISCONNECT cleanly from state %s without throwing',
      (initialState) => {
        const testSm = new ConnectionStateMachine({
          status: initialState,
          selectedDevice: mockDevice,
          error: initialState === 'ERROR' ? 'Some error' : null,
        });

        expect(testSm.canTransition('DISCONNECT')).toBe(true);

        expect(() => {
          testSm.dispatch(connectionActions.disconnect('Remote disconnected'));
        }).not.toThrow();

        const state = testSm.getState();
        expect(state.status).toBe('DISCONNECTED');
        expect(state.selectedDevice).toBeNull();
        expect(state.error).toBe('Remote disconnected');
      }
    );

    it('should cleanly abort mid-sync on unexpected link lost', () => {
      sm.dispatch(connectionActions.selectDevice(mockDevice));
      sm.dispatch(connectionActions.connectSuccess(mockDevice));
      sm.dispatch(connectionActions.startSync());
      expect(sm.getStatus()).toBe('SYNCING');

      // Unexpected link lost mid-sync
      sm.dispatch(connectionActions.disconnect('Peripheral link lost mid-sync'));
      const state = sm.getState();
      expect(state.status).toBe('DISCONNECTED');
      expect(state.selectedDevice).toBeNull();
      expect(state.error).toBe('Peripheral link lost mid-sync');
    });
  });

  describe('SM-6: Strict Transition Validation & Invalid Transition Rejections', () => {
    it('should throw InvalidTransitionError on invalid transition in strict mode', () => {
      expect(sm.getStatus()).toBe('DISCONNECTED');

      // START_SYNC is illegal from DISCONNECTED
      expect(() => {
        sm.dispatch(connectionActions.startSync());
      }).toThrow(InvalidTransitionError);

      try {
        sm.dispatch(connectionActions.startSync());
      } catch (err) {
        expect(err).toBeInstanceOf(InvalidTransitionError);
        const invErr = err as InvalidTransitionError;
        expect(invErr.currentState).toBe('DISCONNECTED');
        expect(invErr.event).toBe('START_SYNC');
      }
    });

    it('should return unchanged state in non-strict mode without throwing', () => {
      expect(sm.getStatus()).toBe('DISCONNECTED');

      const returnedState = sm.dispatch(connectionActions.startSync(), { strict: false });
      expect(returnedState.status).toBe('DISCONNECTED');
      expect(sm.getStatus()).toBe('DISCONNECTED');
    });

    it('should verify transition matrix permissions for each state', () => {
      // DISCONNECTED
      expect(sm.canTransition('START_SCAN')).toBe(true);
      expect(sm.canTransition('SELECT_DEVICE')).toBe(true);
      expect(sm.canTransition('DISCONNECT')).toBe(true);
      expect(sm.canTransition('CLEAR_ERROR')).toBe(true);
      expect(sm.canTransition('STOP_SCAN')).toBe(false);
      expect(sm.canTransition('START_SYNC')).toBe(false);
      expect(sm.canTransition('CONNECT_SUCCESS')).toBe(false);

      // SCANNING
      sm.transition('START_SCAN');
      expect(sm.canTransition('STOP_SCAN')).toBe(true);
      expect(sm.canTransition('DEVICE_FOUND')).toBe(true);
      expect(sm.canTransition('SELECT_DEVICE')).toBe(true);
      expect(sm.canTransition('START_SCAN')).toBe(false);
      expect(sm.canTransition('START_SYNC')).toBe(false);

      // CONNECTING
      sm.transition('SELECT_DEVICE', mockDevice);
      expect(sm.canTransition('CONNECT_SUCCESS')).toBe(true);
      expect(sm.canTransition('CONNECT_FAILURE')).toBe(true);
      expect(sm.canTransition('DISCONNECT')).toBe(true);
      expect(sm.canTransition('START_SCAN')).toBe(false);
      expect(sm.canTransition('START_SYNC')).toBe(false);

      // CONNECTED
      sm.transition('CONNECT_SUCCESS', mockDevice);
      expect(sm.canTransition('START_SYNC')).toBe(true);
      expect(sm.canTransition('DISCONNECT')).toBe(true);
      expect(sm.canTransition('START_SCAN')).toBe(false);
      expect(sm.canTransition('STOP_SCAN')).toBe(false);

      // SYNCING
      sm.transition('START_SYNC');
      expect(sm.canTransition('SYNC_SUCCESS')).toBe(true);
      expect(sm.canTransition('SYNC_FAILURE')).toBe(true);
      expect(sm.canTransition('DISCONNECT')).toBe(true);
      expect(sm.canTransition('START_SCAN')).toBe(false);
      expect(sm.canTransition('SELECT_DEVICE')).toBe(false);

      // ERROR
      sm.transition('DISCONNECT');
      const errSm = new ConnectionStateMachine({ status: 'ERROR' });
      expect(errSm.canTransition('CLEAR_ERROR')).toBe(true);
      expect(errSm.canTransition('START_SCAN')).toBe(true);
      expect(errSm.canTransition('SELECT_DEVICE')).toBe(true);
      expect(errSm.canTransition('DISCONNECT')).toBe(true);
      expect(errSm.canTransition('START_SYNC')).toBe(false);
    });

    it('exhaustively matches VALID_TRANSITIONS mapping for all states', () => {
      const allEvents: ConnectionEvent[] = [
        'START_SCAN',
        'STOP_SCAN',
        'DEVICE_FOUND',
        'SELECT_DEVICE',
        'CONNECT_SUCCESS',
        'CONNECT_FAILURE',
        'DISCONNECT',
        'START_SYNC',
        'SYNC_SUCCESS',
        'SYNC_FAILURE',
        'CLEAR_ERROR',
      ];

      for (const [status, allowedEvents] of Object.entries(VALID_TRANSITIONS) as [
        ConnectionStatus,
        readonly ConnectionEvent[],
      ][]) {
        for (const evt of allEvents) {
          const expected = allowedEvents.includes(evt);
          expect(isValidTransition(status, evt)).toBe(expected);
        }
      }
    });
  });

  describe('SM-7: Subscriber Notifications & Observers', () => {
    it('should notify subscribers on state change', () => {
      const listener = vi.fn();
      const unsubscribe = sm.subscribe(listener);

      sm.transition('START_SCAN');
      expect(listener).toHaveBeenCalledTimes(1);
      expect(listener).toHaveBeenCalledWith(
        expect.objectContaining({ status: 'SCANNING' })
      );

      sm.transition('DEVICE_FOUND', mockDevice);
      expect(listener).toHaveBeenCalledTimes(2);

      unsubscribe();
      sm.transition('STOP_SCAN');
      expect(listener).toHaveBeenCalledTimes(2); // No further calls
    });

    it('should isolate subscriber exceptions from breaking state transitions', () => {
      const faultyListener = vi.fn().mockImplementation(() => {
        throw new Error('Subscriber exploded');
      });
      const healthyListener = vi.fn();

      sm.subscribe(faultyListener);
      sm.subscribe(healthyListener);

      expect(() => {
        sm.transition('START_SCAN');
      }).not.toThrow();

      expect(healthyListener).toHaveBeenCalledTimes(1);
      expect(sm.getStatus()).toBe('SCANNING');
    });
  });

  describe('SM-8: Pure Reducer Immutability', () => {
    it('should not mutate previous state object in connectionReducer', () => {
      const state1 = initialConnectionState;
      const state2 = connectionReducer(state1, connectionActions.startScan());

      expect(state1).not.toBe(state2);
      expect(state1.status).toBe('DISCONNECTED');
      expect(state2.status).toBe('SCANNING');

      const state3 = connectionReducer(state2, connectionActions.deviceFound(mockDevice));
      expect(state2.discoveredDevices).toEqual([]);
      expect(state3.discoveredDevices).toHaveLength(1);
    });
  });

  describe('SM-9: useBleConnection React Hook Integration', () => {
    let mockBle: MockBleService;

    beforeEach(() => {
      mockBle = new MockBleService();
    });

    it('should initialize hook with DISCONNECTED state and correct helpers', () => {
      const { result } = renderHook(() => useBleConnection(mockBle));

      expect(result.current.status).toBe('DISCONNECTED');
      expect(result.current.isDisconnected).toBe(true);
      expect(result.current.isScanning).toBe(false);
      expect(result.current.isConnected).toBe(false);
      expect(result.current.isConnecting).toBe(false);
      expect(result.current.isSyncing).toBe(false);
      expect(result.current.isError).toBe(false);
      expect(result.current.connectedDevice).toBeNull();
      expect(result.current.discoveredDevices).toEqual([]);
    });

    it('should scan and discover mock peripherals via hook', async () => {
      const { result } = renderHook(() => useBleConnection(mockBle));

      await act(async () => {
        await result.current.startScan();
      });

      expect(result.current.discoveredDevices.length).toBeGreaterThanOrEqual(1);
      expect(result.current.discoveredDevices[0].deviceId).toBe('F91-WATCH-SIM-01');

      await act(async () => {
        await result.current.stopScan();
      });

      expect(result.current.status).toBe('DISCONNECTED');
      expect(result.current.discoveredDevices.length).toBeGreaterThanOrEqual(1);
    });

    it('should connect to mock peripheral and update state to CONNECTED', async () => {
      const { result } = renderHook(() => useBleConnection(mockBle));

      await act(async () => {
        await result.current.startScan();
      });

      let connectSuccess = false;
      await act(async () => {
        connectSuccess = await result.current.connect('F91-WATCH-SIM-01');
      });

      expect(connectSuccess).toBe(true);
      expect(result.current.status).toBe('CONNECTED');
      expect(result.current.isConnected).toBe(true);
      expect(result.current.connectedDevice?.deviceId).toBe('F91-WATCH-SIM-01');
    });

    it('should disconnect cleanly via hook', async () => {
      const { result } = renderHook(() => useBleConnection(mockBle));

      await act(async () => {
        await result.current.connect(mockDevice);
      });
      expect(result.current.isConnected).toBe(true);

      await act(async () => {
        await result.current.disconnect();
      });

      expect(result.current.status).toBe('DISCONNECTED');
      expect(result.current.connectedDevice).toBeNull();
    });

    it('should handle remote disconnect notification cleanly in hook', async () => {
      const { result } = renderHook(() => useBleConnection(mockBle));

      await act(async () => {
        await result.current.connect(mockDevice);
      });
      expect(result.current.isConnected).toBe(true);

      // Simulate watch disconnecting remotely (e.g. out of range)
      act(() => {
        mockBle.simulateDisconnect(mockDevice.deviceId);
      });

      expect(result.current.status).toBe('DISCONNECTED');
      expect(result.current.connectedDevice).toBeNull();
      expect(result.current.error).toContain('Connection to F91_Jepler was lost');
    });

    it('should execute manual syncClock from hook and update lastSyncedAt', async () => {
      const { result } = renderHook(() => useBleConnection(mockBle));

      await act(async () => {
        await result.current.connect(mockDevice);
      });

      let syncRes: any = null;
      await act(async () => {
        syncRes = await result.current.syncClock({
          is24Hour: true,
          isDst: true,
        });
      });

      expect(syncRes).not.toBeNull();
      expect(syncRes.success).toBe(true);
      expect(result.current.status).toBe('CONNECTED');
      expect(result.current.lastSyncedAt).not.toBeNull();
      expect(result.current.lastSyncResult).not.toBeNull();
    });

    it('should clear error via hook action', async () => {
      const { result } = renderHook(() => useBleConnection(mockBle));

      mockBle.failNextConnection('Connection Refused');

      await act(async () => {
        await result.current.connect(mockDevice);
      });

      expect(result.current.status).toBe('ERROR');
      expect(result.current.error).toBe('Connection Refused');

      act(() => {
        result.current.clearError();
      });

      expect(result.current.status).toBe('DISCONNECTED');
      expect(result.current.error).toBeNull();
    });
  });
});
