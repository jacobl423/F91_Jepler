/**
 * Reactive React hook for F91_Jepler Bluetooth Low Energy connection and clock synchronization.
 *
 * Integrates:
 * - Formal 6-state connection state machine (DISCONNECTED, SCANNING, CONNECTING, CONNECTED, SYNCING, ERROR)
 * - BleClientInterface abstraction (supporting both MockBleService and CapacitorBleService)
 * - Automatic peripheral discovery and list deduplication
 * - Manual and automated clock synchronization with step progress tracking
 * - Safe disconnect handling with unhandled exception prevention
 * - Driver switching between mock and hardware BLE layers
 */

import { useState, useEffect, useCallback, useRef, useReducer } from 'react';
import { BleClientInterface, BleDevice, DisconnectListener } from '../ble/bleClientInterface';
import { MockBleService } from '../ble/mockBleService';
import { F91_DEVICE_NAME } from '../ble/gattConstants';
import {
  ConnectionStatus,
  ConnectionMachineState,
  initialConnectionState,
  connectionReducer,
  connectionActions,
  isValidTransition,
} from './connectionStateMachine';
import {
  syncClock,
  SyncResult,
  SyncOptions,
  SyncProgress,
  SyncDisconnectedError,
} from './syncService';

/**
 * Options for configuring useBleConnection hook.
 */
export interface UseBleConnectionOptions {
  /** Initial BLE driver; defaults to new MockBleService() */
  initialClient?: BleClientInterface;
  /** Scan timeout in milliseconds; defaults to 15000ms */
  scanTimeoutMs?: number;
  /** Sync write timeout in milliseconds; defaults to 5000ms */
  syncTimeoutMs?: number;
  /** Whether to start scanning immediately on mount; defaults to false */
  autoScan?: boolean;
}

/**
 * Return type for useBleConnection hook.
 */
export interface UseBleConnectionReturn {
  // --- Connection State ---
  status: ConnectionStatus;
  state: ConnectionMachineState;
  connectedDevice: BleDevice | null;
  discoveredDevices: BleDevice[];
  error: string | null;
  lastSyncedAt: Date | null;
  lastSyncResult: SyncResult | null;
  syncProgress: SyncProgress | null;

  // --- Convenience Booleans ---
  isDisconnected: boolean;
  isScanning: boolean;
  isConnecting: boolean;
  isConnected: boolean;
  isSyncing: boolean;
  isError: boolean;

  // --- Actions ---
  startScan: (timeoutMs?: number) => Promise<void>;
  stopScan: () => Promise<void>;
  connect: (deviceOrId: BleDevice | string) => Promise<boolean>;
  disconnect: () => Promise<void>;
  syncClock: (options?: Partial<SyncOptions>) => Promise<SyncResult | null>;
  clearError: () => void;

  // --- BLE Client Management ---
  bleClient: BleClientInterface;
  setBleClient: (client: BleClientInterface) => void;
}

/**
 * Hook managing BLE connection lifecycle and clock sync for F91_Jepler smartwatch.
 */
export function useBleConnection(
  clientOverride?: BleClientInterface,
  options: UseBleConnectionOptions = {}
): UseBleConnectionReturn {
  const scanTimeoutDuration = options.scanTimeoutMs ?? 15000;
  const syncTimeoutDuration = options.syncTimeoutMs ?? 5000;

  // Active BLE Client (can be swapped at runtime)
  const [bleClient, setBleClientState] = useState<BleClientInterface>(() => {
    return clientOverride || options.initialClient || new MockBleService();
  });

  const clientRef = useRef<BleClientInterface>(bleClient);
  useEffect(() => {
    clientRef.current = bleClient;
  }, [bleClient]);

  // Reducer for formal state machine
  const [machineState, dispatch] = useReducer(
    (state: ConnectionMachineState, action: Parameters<typeof connectionReducer>[1]) =>
      connectionReducer(state, action, { strict: false }),
    initialConnectionState
  );

  const stateRef = useRef<ConnectionMachineState>(machineState);
  useEffect(() => {
    stateRef.current = machineState;
  }, [machineState]);

  // Clock sync auxiliary state
  const [lastSyncResult, setLastSyncResult] = useState<SyncResult | null>(null);
  const [syncProgress, setSyncProgress] = useState<SyncProgress | null>(null);

  // Scan timer reference
  const scanTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  const clearScanTimer = useCallback(() => {
    if (scanTimerRef.current !== null) {
      clearTimeout(scanTimerRef.current);
      scanTimerRef.current = null;
    }
  }, []);

  // --- Stop Scan ---
  const stopScan = useCallback(async (): Promise<void> => {
    clearScanTimer();
    try {
      await clientRef.current.stopScan();
    } catch (err) {
      console.warn('Error stopping BLE scan:', err);
    } finally {
      if (stateRef.current.status === 'SCANNING') {
        dispatch(connectionActions.stopScan());
      }
    }
  }, [clearScanTimer]);

  // --- Start Scan ---
  const startScan = useCallback(
    async (timeoutMs?: number): Promise<void> => {
      const currentStatus = stateRef.current.status;
      if (currentStatus === 'SCANNING') {
        return;
      }
      if (!isValidTransition(currentStatus, 'START_SCAN')) {
        console.warn(`Cannot start scan from state ${currentStatus}`);
        return;
      }

      clearScanTimer();
      dispatch(connectionActions.startScan());

      try {
        await clientRef.current.startScan((device: BleDevice) => {
          dispatch(connectionActions.deviceFound(device));
        });

        // Set scan timeout
        const duration = timeoutMs ?? scanTimeoutDuration;
        scanTimerRef.current = setTimeout(() => {
          stopScan().catch((err) => console.error('Error stopping scan on timeout:', err));
        }, duration);
      } catch (err: unknown) {
        clearScanTimer();
        const errorMsg = err instanceof Error ? err.message : String(err);
        dispatch(connectionActions.connectFailure(`Scan failed: ${errorMsg}`));
      }
    },
    [clearScanTimer, scanTimeoutDuration, stopScan]
  );

  // --- Connect ---
  const connect = useCallback(
    async (deviceOrId: BleDevice | string): Promise<boolean> => {
      // Resolve device object
      let targetDevice: BleDevice;
      if (typeof deviceOrId === 'string') {
        const found = stateRef.current.discoveredDevices.find(
          (d) => d.deviceId.toLowerCase() === deviceOrId.toLowerCase()
        );
        targetDevice = found || {
          deviceId: deviceOrId,
          name: F91_DEVICE_NAME,
        };
      } else {
        targetDevice = deviceOrId;
      }

      // If currently scanning, stop scan first
      if (stateRef.current.status === 'SCANNING') {
        await stopScan();
      }

      dispatch(connectionActions.selectDevice(targetDevice));

      try {
        await clientRef.current.connect(targetDevice.deviceId);
        dispatch(connectionActions.connectSuccess(targetDevice));
        return true;
      } catch (err: unknown) {
        const errorMsg = err instanceof Error ? err.message : String(err);
        dispatch(connectionActions.connectFailure(errorMsg));
        return false;
      }
    },
    [stopScan]
  );

  // --- Disconnect ---
  const disconnect = useCallback(async (): Promise<void> => {
    clearScanTimer();
    const activeDevice = stateRef.current.selectedDevice;

    if (activeDevice) {
      try {
        await clientRef.current.disconnect(activeDevice.deviceId);
      } catch (err) {
        console.warn('Error during disconnect call:', err);
      }
    }

    dispatch(connectionActions.disconnect());
  }, [clearScanTimer]);

  // --- Sync Clock ---
  const handleSyncClock = useCallback(
    async (syncOpts?: Partial<SyncOptions>): Promise<SyncResult | null> => {
      const activeDevice = stateRef.current.selectedDevice;
      if (!activeDevice || stateRef.current.status !== 'CONNECTED') {
        console.warn('Cannot sync clock: watch is not connected');
        return null;
      }

      dispatch(connectionActions.startSync());

      try {
        const result = await syncClock(activeDevice.deviceId, clientRef.current, {
          ...syncOpts,
          timeoutMs: syncOpts?.timeoutMs ?? syncTimeoutDuration,
          onProgress: (prog) => {
            setSyncProgress(prog);
            syncOpts?.onProgress?.(prog);
          },
        });

        dispatch(connectionActions.syncSuccess(new Date(result.timestamp * 1000)));
        setLastSyncResult(result);
        return result;
      } catch (err: unknown) {
        const message = err instanceof Error ? err.message : String(err);

        if (err instanceof SyncDisconnectedError) {
          // Peripheral lost link during sync
          dispatch(connectionActions.disconnect(`Disconnected during clock sync: ${message}`));
        } else {
          // GATT write error or timeout while link remains open
          dispatch(connectionActions.syncFailure(`Sync failed: ${message}`));
        }

        return null;
      }
    },
    [syncTimeoutDuration]
  );

  // --- Clear Error ---
  const clearError = useCallback(() => {
    dispatch(connectionActions.clearError());
  }, []);

  // --- Swap BLE Client ---
  const setBleClient = useCallback(
    (newClient: BleClientInterface) => {
      // Disconnect current client if connected
      if (stateRef.current.selectedDevice) {
        disconnect().catch((err) => console.warn('Error disconnecting previous client:', err));
      }
      setBleClientState(newClient);
    },
    [disconnect]
  );

  // Setup disconnect listener on the current bleClient instance
  useEffect(() => {
    const currentClient = bleClient;
    const disconnectHandler: DisconnectListener = (disconnectedDeviceId: string) => {
      const active = stateRef.current.selectedDevice;
      if (active && active.deviceId.toLowerCase() === disconnectedDeviceId.toLowerCase()) {
        dispatch(
          connectionActions.disconnect(`Connection to ${active.name || 'watch'} was lost`)
        );
      }
    };

    if (typeof currentClient.onDisconnect === 'function') {
      currentClient.onDisconnect(disconnectHandler);
    }

    return () => {
      if (typeof currentClient.removeDisconnectListener === 'function') {
        currentClient.removeDisconnectListener(disconnectHandler);
      }
    };
  }, [bleClient]);

  // Auto-scan on mount if requested
  useEffect(() => {
    if (options.autoScan) {
      startScan().catch((err) => console.error('Error during auto-scan:', err));
    }
  }, [options.autoScan, startScan]);

  // Teardown on unmount
  useEffect(() => {
    return () => {
      clearScanTimer();
      const client = clientRef.current;
      if (stateRef.current.status === 'SCANNING') {
        client.stopScan().catch(() => {});
      }
    };
  }, [clearScanTimer]);

  const { status, selectedDevice, discoveredDevices, error, lastSyncedAt } = machineState;

  return {
    status,
    state: machineState,
    connectedDevice: selectedDevice,
    discoveredDevices,
    error,
    lastSyncedAt,
    lastSyncResult,
    syncProgress,

    isDisconnected: status === 'DISCONNECTED',
    isScanning: status === 'SCANNING',
    isConnecting: status === 'CONNECTING',
    isConnected: status === 'CONNECTED',
    isSyncing: status === 'SYNCING',
    isError: status === 'ERROR',

    startScan,
    stopScan,
    connect,
    disconnect,
    syncClock: handleSyncClock,
    clearError,

    bleClient,
    setBleClient,
  };
}
