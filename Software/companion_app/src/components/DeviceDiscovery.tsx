import React from 'react';
import {
  Bluetooth,
  BluetoothSearching,
  Radio,
  CheckCircle2,
  RefreshCw,
  Power,
  Signal,
  Watch,
} from 'lucide-react';
import { BleDevice } from '../ble/bleClientInterface';
import { ConnectionStatus } from '../state/connectionStateMachine';

export interface DeviceDiscoveryProps {
  status: ConnectionStatus;
  discoveredDevices: BleDevice[];
  connectedDevice: BleDevice | null;
  onStartScan: () => void | Promise<void>;
  onStopScan: () => void | Promise<void>;
  onConnect: (device: BleDevice) => void | Promise<boolean>;
  onDisconnect: () => void | Promise<void>;
  className?: string;
}

/**
 * Returns signal strength description and bar count based on RSSI value.
 */
function getSignalQuality(rssi?: number): {
  label: string;
  bars: number;
  colorClass: string;
} {
  if (typeof rssi !== 'number') {
    return { label: 'Unknown', bars: 0, colorClass: 'text-slate-500' };
  }
  if (rssi >= -60) {
    return { label: 'Excellent', bars: 4, colorClass: 'text-emerald-400' };
  }
  if (rssi >= -72) {
    return { label: 'Good', bars: 3, colorClass: 'text-teal-400' };
  }
  if (rssi >= -85) {
    return { label: 'Fair', bars: 2, colorClass: 'text-amber-400' };
  }
  return { label: 'Weak', bars: 1, colorClass: 'text-rose-400' };
}

export const DeviceDiscovery: React.FC<DeviceDiscoveryProps> = ({
  status,
  discoveredDevices,
  connectedDevice,
  onStartScan,
  onStopScan,
  onConnect,
  onDisconnect,
  className = '',
}) => {
  const isScanning = status === 'SCANNING';
  const isBusy = status === 'CONNECTING' || status === 'SYNCING';

  return (
    <div
      className={`bg-slate-800/60 rounded-2xl border border-slate-700/60 p-4 shadow-xl backdrop-blur-md ${className}`}
      data-testid="device-discovery"
    >
      {/* Header & Scan Trigger */}
      <div className="flex items-center justify-between pb-3 border-b border-slate-700/50">
        <div className="flex items-center gap-2.5">
          <div className="p-2 bg-indigo-600/20 text-indigo-400 rounded-xl border border-indigo-500/30">
            <Bluetooth className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-base font-semibold text-white tracking-tight">Ready for Discovery</h2>
            <p className="text-xs text-slate-400">
              Service UUID: <code className="text-xs bg-slate-900 px-1 py-0.5 rounded text-indigo-300 font-mono">fa35b2f0...</code>
            </p>
          </div>
        </div>

        {/* Scan / Stop Scan Action */}
        {isScanning ? (
          <button
            type="button"
            onClick={() => onStopScan()}
            className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold bg-rose-600/20 text-rose-300 border border-rose-500/40 hover:bg-rose-600/30 active:scale-95 transition-all shadow-sm"
            data-testid="scan-stop-button"
            aria-label="Stop Scanning"
          >
            <RefreshCw className="w-3.5 h-3.5 animate-spin" />
            <span>Stop Scan</span>
          </button>
        ) : (
          <button
            type="button"
            onClick={() => onStartScan()}
            disabled={isBusy}
            className="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-lg text-xs font-semibold bg-indigo-600 text-white hover:bg-indigo-500 active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-md shadow-indigo-600/20"
            data-testid="scan-button"
            aria-label="Scan for Watches"
          >
            <BluetoothSearching className="w-3.5 h-3.5" />
            <span>Scan for Watches</span>
          </button>
        )}
      </div>

      {/* Discovered Devices List */}
      <div className="mt-3 space-y-2">
        {discoveredDevices.length === 0 ? (
          <div
            className="py-8 px-4 text-center rounded-xl bg-slate-900/40 border border-dashed border-slate-700/60"
            data-testid="empty-device-list"
          >
            {isScanning ? (
              <div className="flex flex-col items-center justify-center space-y-2">
                <RefreshCw className="w-6 h-6 animate-spin text-sky-400" />
                <p className="text-sm font-medium text-slate-300">Searching for F91_Jepler watches...</p>
                <p className="text-xs text-slate-500">Ensure the smartwatch Bluetooth is active and advertising</p>
              </div>
            ) : (
              <div className="flex flex-col items-center justify-center space-y-2">
                <Radio className="w-6 h-6 text-slate-500" />
                <p className="text-sm font-medium text-slate-300">No devices discovered</p>
                <p className="text-xs text-slate-500">Tap "Scan for Watches" to search for nearby peripherals</p>
              </div>
            )}
          </div>
        ) : (
          <div className="space-y-2" data-testid="device-list">
            {discoveredDevices.map((device) => {
              const isThisDeviceConnected = connectedDevice?.deviceId === device.deviceId;
              const isF91 = device.name?.toLowerCase().includes('f91') || device.name?.toLowerCase().includes('jepler');
              const signal = getSignalQuality(device.rssi);

              return (
                <div
                  key={device.deviceId}
                  className={`flex items-center justify-between p-3 rounded-xl border transition-all ${
                    isThisDeviceConnected
                      ? 'bg-emerald-950/20 border-emerald-500/40 shadow-sm shadow-emerald-500/10'
                      : 'bg-slate-900/60 border-slate-700/60 hover:border-slate-600'
                  }`}
                  data-testid={`device-item-${device.deviceId}`}
                >
                  {/* Device Info */}
                  <div className="flex items-center gap-3 min-w-0">
                    <div
                      className={`p-2 rounded-lg border ${
                        isThisDeviceConnected
                          ? 'bg-emerald-500/20 text-emerald-400 border-emerald-500/30'
                          : 'bg-slate-800 text-slate-300 border-slate-700'
                      }`}
                    >
                      <Watch className="w-5 h-5" />
                    </div>

                    <div className="min-w-0">
                      <div className="flex items-center gap-2">
                        <span className="text-sm font-semibold text-slate-100 truncate font-mono">
                          {device.name || 'Unnamed Device'}
                        </span>
                        {isF91 && (
                          <span className="px-1.5 py-0.5 rounded text-[10px] font-bold bg-indigo-500/20 text-indigo-300 border border-indigo-500/30">
                            F-91W
                          </span>
                        )}
                        {isThisDeviceConnected && (
                          <span className="flex items-center gap-1 text-[10px] font-medium text-emerald-400">
                            <CheckCircle2 className="w-3 h-3" />
                            Connected
                          </span>
                        )}
                      </div>

                      <div className="flex items-center gap-3 text-xs text-slate-400 mt-0.5 font-mono">
                        <span className="truncate">{device.deviceId}</span>
                        {typeof device.rssi === 'number' && (
                          <span className={`inline-flex items-center gap-1 ${signal.colorClass}`} title={`Signal: ${signal.label}`}>
                            <Signal className="w-3 h-3" />
                            <span>{device.rssi} dBm</span>
                          </span>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Action Button */}
                  <div>
                    {isThisDeviceConnected ? (
                      <button
                        type="button"
                        onClick={() => onDisconnect()}
                        disabled={status === 'SYNCING'}
                        className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold bg-rose-600/15 text-rose-300 border border-rose-500/30 hover:bg-rose-600/25 active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
                        data-testid={`disconnect-btn-${device.deviceId}`}
                        aria-label={`Disconnect from ${device.name || device.deviceId}`}
                      >
                        <Power className="w-3.5 h-3.5" />
                        <span>Disconnect</span>
                      </button>
                    ) : (
                      <button
                        type="button"
                        onClick={() => onConnect(device)}
                        disabled={isBusy}
                        className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-semibold bg-indigo-600/20 text-indigo-300 border border-indigo-500/30 hover:bg-indigo-600/30 active:scale-95 disabled:opacity-50 disabled:cursor-not-allowed transition-all"
                        data-testid={`connect-btn-${device.deviceId}`}
                        aria-label={`Connect to ${device.name || device.deviceId}`}
                      >
                        {status === 'CONNECTING' ? (
                          <>
                            <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                            <span>Connecting</span>
                          </>
                        ) : (
                          <>
                            <Bluetooth className="w-3.5 h-3.5" />
                            <span>Connect</span>
                          </>
                        )}
                      </button>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
};

export default DeviceDiscovery;
