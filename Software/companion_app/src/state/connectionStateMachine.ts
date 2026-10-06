/**
 * Reactive Connection State Machine for F91_Jepler Companion Mobile Application.
 *
 * Implements a formal 6-state finite state machine with strict transition guards:
 * - States: DISCONNECTED, SCANNING, CONNECTING, CONNECTED, SYNCING, ERROR
 * - Events: START_SCAN, STOP_SCAN, DEVICE_FOUND, SELECT_DEVICE, CONNECT_SUCCESS,
 *           CONNECT_FAILURE, DISCONNECT, START_SYNC, SYNC_SUCCESS, SYNC_FAILURE, CLEAR_ERROR
 *
 * Designed to prevent illegal state transitions, unhandled exceptions on unexpected
 * link loss, and device list corruption.
 */

import { BleDevice } from '../ble/bleClientInterface';

/**
 * The 6 canonical connection states for the F91_Jepler BLE lifecycle.
 */
export type ConnectionStatus =
  | 'DISCONNECTED'
  | 'SCANNING'
  | 'CONNECTING'
  | 'CONNECTED'
  | 'SYNCING'
  | 'ERROR';

export type ConnectionState = ConnectionStatus;

export const CONNECTION_STATUS = {
  DISCONNECTED: 'DISCONNECTED',
  SCANNING: 'SCANNING',
  CONNECTING: 'CONNECTING',
  CONNECTED: 'CONNECTED',
  SYNCING: 'SYNCING',
  ERROR: 'ERROR',
} as const;

/**
 * The 11 valid events/triggers that drive state transitions.
 */
export type ConnectionEvent =
  | 'START_SCAN'
  | 'STOP_SCAN'
  | 'DEVICE_FOUND'
  | 'SELECT_DEVICE'
  | 'CONNECT_SUCCESS'
  | 'CONNECT_FAILURE'
  | 'DISCONNECT'
  | 'START_SYNC'
  | 'SYNC_SUCCESS'
  | 'SYNC_FAILURE'
  | 'CLEAR_ERROR';

export const CONNECTION_EVENT = {
  START_SCAN: 'START_SCAN',
  STOP_SCAN: 'STOP_SCAN',
  DEVICE_FOUND: 'DEVICE_FOUND',
  SELECT_DEVICE: 'SELECT_DEVICE',
  CONNECT_SUCCESS: 'CONNECT_SUCCESS',
  CONNECT_FAILURE: 'CONNECT_FAILURE',
  DISCONNECT: 'DISCONNECT',
  START_SYNC: 'START_SYNC',
  SYNC_SUCCESS: 'SYNC_SUCCESS',
  SYNC_FAILURE: 'SYNC_FAILURE',
  CLEAR_ERROR: 'CLEAR_ERROR',
} as const;

/**
 * Action definitions with strongly typed payloads.
 */
export interface StartScanAction {
  type: 'START_SCAN';
}

export interface StopScanAction {
  type: 'STOP_SCAN';
}

export interface DeviceFoundAction {
  type: 'DEVICE_FOUND';
  payload: BleDevice;
}

export interface SelectDeviceAction {
  type: 'SELECT_DEVICE';
  payload: BleDevice;
}

export interface ConnectSuccessAction {
  type: 'CONNECT_SUCCESS';
  payload?: BleDevice;
}

export interface ConnectFailureAction {
  type: 'CONNECT_FAILURE';
  payload: { error: string };
}

export interface DisconnectAction {
  type: 'DISCONNECT';
  payload?: { error?: string };
}

export interface StartSyncAction {
  type: 'START_SYNC';
}

export interface SyncSuccessAction {
  type: 'SYNC_SUCCESS';
  payload?: { syncedAt?: Date };
}

export interface SyncFailureAction {
  type: 'SYNC_FAILURE';
  payload: { error: string };
}

export interface ClearErrorAction {
  type: 'CLEAR_ERROR';
}

export type ConnectionAction =
  | StartScanAction
  | StopScanAction
  | DeviceFoundAction
  | SelectDeviceAction
  | ConnectSuccessAction
  | ConnectFailureAction
  | DisconnectAction
  | StartSyncAction
  | SyncSuccessAction
  | SyncFailureAction
  | ClearErrorAction;

/**
 * State machine context holding active connection status, devices, errors, and timestamps.
 */
export interface ConnectionMachineState {
  status: ConnectionStatus;
  selectedDevice: BleDevice | null;
  discoveredDevices: BleDevice[];
  error: string | null;
  lastSyncedAt: Date | null;
}

export const initialConnectionState: Readonly<ConnectionMachineState> = Object.freeze({
  status: 'DISCONNECTED',
  selectedDevice: null,
  discoveredDevices: [],
  error: null,
  lastSyncedAt: null,
});

/**
 * Custom error thrown when a transition is rejected in strict mode.
 */
export class InvalidTransitionError extends Error {
  readonly currentState: ConnectionStatus;
  readonly event: ConnectionEvent;

  constructor(currentState: ConnectionStatus, event: ConnectionEvent, details?: string) {
    const message =
      details ||
      `Invalid transition: event '${event}' is not permitted from current state '${currentState}'`;
    super(message);
    this.name = 'InvalidTransitionError';
    this.currentState = currentState;
    this.event = event;
    Object.setPrototypeOf(this, InvalidTransitionError.prototype);
  }
}

/**
 * Transition permission table mapping each state to its allowed triggers.
 *
 * NOTE: 'DISCONNECT' is valid from every state to ensure that unexpected
 * link drops, hardware detachments, or user cancels never throw unhandled errors.
 */
export const VALID_TRANSITIONS: Record<ConnectionStatus, readonly ConnectionEvent[]> = {
  DISCONNECTED: Object.freeze([
    'START_SCAN',
    'SELECT_DEVICE',
    'DISCONNECT',
    'CLEAR_ERROR',
  ]),
  SCANNING: Object.freeze([
    'STOP_SCAN',
    'DEVICE_FOUND',
    'SELECT_DEVICE',
    'DISCONNECT',
    'CONNECT_FAILURE',
  ]),
  CONNECTING: Object.freeze([
    'CONNECT_SUCCESS',
    'CONNECT_FAILURE',
    'DISCONNECT',
  ]),
  CONNECTED: Object.freeze([
    'START_SYNC',
    'DISCONNECT',
    'CLEAR_ERROR',
  ]),
  SYNCING: Object.freeze([
    'SYNC_SUCCESS',
    'SYNC_FAILURE',
    'DISCONNECT',
  ]),
  ERROR: Object.freeze([
    'CLEAR_ERROR',
    'START_SCAN',
    'SELECT_DEVICE',
    'DISCONNECT',
  ]),
};

/**
 * Validates whether an event is permitted in the given state.
 */
export function isValidTransition(
  currentState: ConnectionStatus,
  event: ConnectionEvent
): boolean {
  const allowed = VALID_TRANSITIONS[currentState];
  return allowed ? allowed.includes(event) : false;
}

/**
 * Pure reducer function for connection state transitions.
 *
 * In non-strict mode (default for React useReducer), invalid actions are safely
 * ignored and the current state is preserved without throwing.
 * In strict mode, an InvalidTransitionError is thrown.
 */
export function connectionReducer(
  state: ConnectionMachineState,
  action: ConnectionAction,
  options: { strict?: boolean } = { strict: false }
): ConnectionMachineState {
  if (!isValidTransition(state.status, action.type)) {
    if (options.strict) {
      throw new InvalidTransitionError(state.status, action.type);
    }
    return state;
  }

  switch (action.type) {
    case 'START_SCAN': {
      return {
        ...state,
        status: 'SCANNING',
        // Fresh scan resets discovery list and clears any existing error
        discoveredDevices: [],
        error: null,
      };
    }

    case 'STOP_SCAN': {
      return {
        ...state,
        status: 'DISCONNECTED',
        // Retain discoveredDevices so user can view and select
      };
    }

    case 'DEVICE_FOUND': {
      const newDevice = action.payload;
      const existingIndex = state.discoveredDevices.findIndex(
        (d) => d.deviceId.toLowerCase() === newDevice.deviceId.toLowerCase()
      );

      let updatedDevices: BleDevice[];
      if (existingIndex >= 0) {
        // Update device in place (preserving order, refreshing RSSI or services)
        updatedDevices = [...state.discoveredDevices];
        updatedDevices[existingIndex] = {
          ...updatedDevices[existingIndex],
          ...newDevice,
        };
      } else {
        // Append new peripheral
        updatedDevices = [...state.discoveredDevices, newDevice];
      }

      return {
        ...state,
        discoveredDevices: updatedDevices,
      };
    }

    case 'SELECT_DEVICE': {
      return {
        ...state,
        status: 'CONNECTING',
        selectedDevice: action.payload,
        error: null,
      };
    }

    case 'CONNECT_SUCCESS': {
      return {
        ...state,
        status: 'CONNECTED',
        selectedDevice: action.payload ?? state.selectedDevice,
        error: null,
      };
    }

    case 'CONNECT_FAILURE': {
      return {
        ...state,
        status: 'ERROR',
        selectedDevice: null,
        error: action.payload.error,
      };
    }

    case 'DISCONNECT': {
      return {
        ...state,
        status: 'DISCONNECTED',
        selectedDevice: null,
        error: action.payload?.error ?? null,
      };
    }

    case 'START_SYNC': {
      return {
        ...state,
        status: 'SYNCING',
        error: null,
      };
    }

    case 'SYNC_SUCCESS': {
      return {
        ...state,
        status: 'CONNECTED',
        lastSyncedAt: action.payload?.syncedAt ?? new Date(),
        error: null,
      };
    }

    case 'SYNC_FAILURE': {
      // Per specification, failure returns to CONNECTED keeping link open
      return {
        ...state,
        status: 'CONNECTED',
        error: action.payload.error,
      };
    }

    case 'CLEAR_ERROR': {
      return {
        ...state,
        status: state.status === 'ERROR' ? 'DISCONNECTED' : state.status,
        error: null,
      };
    }

    default: {
      return state;
    }
  }
}

/**
 * Helper action creators for standard events.
 */
export const connectionActions = {
  startScan: (): StartScanAction => ({ type: 'START_SCAN' }),
  stopScan: (): StopScanAction => ({ type: 'STOP_SCAN' }),
  deviceFound: (device: BleDevice): DeviceFoundAction => ({
    type: 'DEVICE_FOUND',
    payload: device,
  }),
  selectDevice: (device: BleDevice): SelectDeviceAction => ({
    type: 'SELECT_DEVICE',
    payload: device,
  }),
  connectSuccess: (device?: BleDevice): ConnectSuccessAction => ({
    type: 'CONNECT_SUCCESS',
    payload: device,
  }),
  connectFailure: (error: string): ConnectFailureAction => ({
    type: 'CONNECT_FAILURE',
    payload: { error },
  }),
  disconnect: (error?: string): DisconnectAction => ({
    type: 'DISCONNECT',
    payload: error ? { error } : undefined,
  }),
  startSync: (): StartSyncAction => ({ type: 'START_SYNC' }),
  syncSuccess: (syncedAt?: Date): SyncSuccessAction => ({
    type: 'SYNC_SUCCESS',
    payload: { syncedAt },
  }),
  syncFailure: (error: string): SyncFailureAction => ({
    type: 'SYNC_FAILURE',
    payload: { error },
  }),
  clearError: (): ClearErrorAction => ({ type: 'CLEAR_ERROR' }),
};

/**
 * Stateful ConnectionStateMachine class with subscription listener support
 * and strict transition verification.
 */
export class ConnectionStateMachine {
  private state: ConnectionMachineState;
  private listeners: Set<(state: Readonly<ConnectionMachineState>) => void> = new Set();

  constructor(initialState?: Partial<ConnectionMachineState>) {
    this.state = {
      ...initialConnectionState,
      ...initialState,
    };
  }

  /**
   * Returns an immutable copy of the current machine state.
   */
  getState(): Readonly<ConnectionMachineState> {
    return { ...this.state };
  }

  /**
   * Returns the current status string.
   */
  getStatus(): ConnectionStatus {
    return this.state.status;
  }

  /**
   * Checks whether the given event can be fired from the current state.
   */
  canTransition(event: ConnectionEvent): boolean {
    return isValidTransition(this.state.status, event);
  }

  /**
   * Dispatches an action to transition the state.
   * By default, throws an InvalidTransitionError if the event is not permitted.
   */
  dispatch(
    action: ConnectionAction,
    options: { strict?: boolean } = { strict: true }
  ): Readonly<ConnectionMachineState> {
    if (!this.canTransition(action.type)) {
      if (options.strict) {
        throw new InvalidTransitionError(this.state.status, action.type);
      }
      return this.getState();
    }

    this.state = connectionReducer(this.state, action, { strict: false });
    this.notify();
    return this.getState();
  }

  /**
   * Convenience transition helper taking an event name and optional payload.
   */
  transition(
    event: ConnectionEvent,
    payload?: any,
    options: { strict?: boolean } = { strict: true }
  ): Readonly<ConnectionMachineState> {
    let action: ConnectionAction;

    switch (event) {
      case 'START_SCAN':
        action = connectionActions.startScan();
        break;
      case 'STOP_SCAN':
        action = connectionActions.stopScan();
        break;
      case 'DEVICE_FOUND':
        action = connectionActions.deviceFound(payload);
        break;
      case 'SELECT_DEVICE':
        action = connectionActions.selectDevice(payload);
        break;
      case 'CONNECT_SUCCESS':
        action = connectionActions.connectSuccess(payload);
        break;
      case 'CONNECT_FAILURE':
        action = connectionActions.connectFailure(
          typeof payload === 'string' ? payload : payload?.error || 'Connection failed'
        );
        break;
      case 'DISCONNECT':
        action = connectionActions.disconnect(
          typeof payload === 'string' ? payload : payload?.error
        );
        break;
      case 'START_SYNC':
        action = connectionActions.startSync();
        break;
      case 'SYNC_SUCCESS':
        action = connectionActions.syncSuccess(
          payload instanceof Date ? payload : payload?.syncedAt
        );
        break;
      case 'SYNC_FAILURE':
        action = connectionActions.syncFailure(
          typeof payload === 'string' ? payload : payload?.error || 'Sync failed'
        );
        break;
      case 'CLEAR_ERROR':
        action = connectionActions.clearError();
        break;
      default:
        throw new Error(`Unsupported event: ${event}`);
    }

    return this.dispatch(action, options);
  }

  /**
   * Subscribes a listener to state change notifications.
   * Returns an unsubscribe function.
   */
  subscribe(listener: (state: Readonly<ConnectionMachineState>) => void): () => void {
    this.listeners.add(listener);
    return () => {
      this.listeners.delete(listener);
    };
  }

  /**
   * Resets the state machine to an initial or specific state.
   */
  reset(initialState?: Partial<ConnectionMachineState>): void {
    this.state = {
      ...initialConnectionState,
      ...initialState,
    };
    this.notify();
  }

  private notify(): void {
    const snapshot = this.getState();
    for (const listener of this.listeners) {
      try {
        listener(snapshot);
      } catch (err) {
        console.error('Error in state machine subscriber listener:', err);
      }
    }
  }
}
