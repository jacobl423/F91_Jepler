import React from 'react';
import {
  BluetoothSearching,
  BluetoothConnected,
  BluetoothOff,
  RefreshCw,
  AlertCircle,
  Radio,
} from 'lucide-react';
import { ConnectionStatus } from '../state/connectionStateMachine';
import { BleDevice } from '../ble/bleClientInterface';

export interface ConnectionStatusBadgeProps {
  status: ConnectionStatus;
  device?: BleDevice | null;
  error?: string | null;
  className?: string;
  showDetails?: boolean;
}

export const ConnectionStatusBadge: React.FC<ConnectionStatusBadgeProps> = ({
  status,
  device,
  error,
  className = '',
  showDetails = false,
}) => {
  // Config per status
  const getStatusConfig = () => {
    switch (status) {
      case 'SCANNING':
        return {
          label: 'Scanning...',
          bgColor: 'bg-sky-500/10',
          textColor: 'text-sky-400',
          borderColor: 'border-sky-500/30',
          dotColor: 'bg-sky-400',
          ping: true,
          icon: <BluetoothSearching className="w-3.5 h-3.5 animate-pulse text-sky-400" />,
        };
      case 'CONNECTING':
        return {
          label: 'Connecting...',
          bgColor: 'bg-amber-500/10',
          textColor: 'text-amber-400',
          borderColor: 'border-amber-500/30',
          dotColor: 'bg-amber-400',
          ping: true,
          icon: <RefreshCw className="w-3.5 h-3.5 animate-spin text-amber-400" />,
        };
      case 'CONNECTED':
        return {
          label: device?.name ? `Connected: ${device.name}` : 'Connected',
          bgColor: 'bg-emerald-500/10',
          textColor: 'text-emerald-400',
          borderColor: 'border-emerald-500/30',
          dotColor: 'bg-emerald-400',
          ping: false,
          icon: <BluetoothConnected className="w-3.5 h-3.5 text-emerald-400" />,
        };
      case 'SYNCING':
        return {
          label: 'Syncing Clock...',
          bgColor: 'bg-indigo-500/15',
          textColor: 'text-indigo-400',
          borderColor: 'border-indigo-500/40',
          dotColor: 'bg-indigo-400',
          ping: true,
          icon: <RefreshCw className="w-3.5 h-3.5 animate-spin text-indigo-400" />,
        };
      case 'ERROR':
        return {
          label: error ? 'Connection Error' : 'Error',
          bgColor: 'bg-rose-500/10',
          textColor: 'text-rose-400',
          borderColor: 'border-rose-500/30',
          dotColor: 'bg-rose-400',
          ping: false,
          icon: <AlertCircle className="w-3.5 h-3.5 text-rose-400" />,
        };
      case 'DISCONNECTED':
      default:
        return {
          label: 'Disconnected',
          bgColor: 'bg-slate-800/80',
          textColor: 'text-slate-400',
          borderColor: 'border-slate-700/60',
          dotColor: 'bg-slate-500',
          ping: false,
          icon: <BluetoothOff className="w-3.5 h-3.5 text-slate-400" />,
        };
    }
  };

  const config = getStatusConfig();

  return (
    <div className={`inline-flex flex-col items-end ${className}`} role="status" aria-live="polite">
      <div
        className={`inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-medium border backdrop-blur-sm transition-all duration-200 ${config.bgColor} ${config.textColor} ${config.borderColor}`}
        data-testid="connection-status-badge"
        data-status={status.toLowerCase()}
      >
        <span className="relative flex h-2 w-2">
          {config.ping && (
            <span
              className={`animate-ping absolute inline-flex h-full w-full rounded-full opacity-75 ${config.dotColor}`}
            />
          )}
          <span className={`relative inline-flex rounded-full h-2 w-2 ${config.dotColor}`} />
        </span>
        {config.icon}
        <span className="font-mono tracking-tight font-semibold">{config.label}</span>
      </div>

      {showDetails && device && status === 'CONNECTED' && (
        <div className="mt-1 flex items-center gap-2 text-[10px] text-slate-400 font-mono">
          <span className="truncate max-w-[140px]">{device.deviceId}</span>
          {typeof device.rssi === 'number' && (
            <span className="flex items-center gap-0.5 text-slate-400">
              <Radio className="w-2.5 h-2.5" />
              {device.rssi} dBm
            </span>
          )}
        </div>
      )}
    </div>
  );
};

export default ConnectionStatusBadge;
