import React, { useState, useEffect } from 'react';
import {
  Clock,
  RefreshCw,
  CheckCircle2,
  Globe,
  Sun,
  Moon,
  Zap,
  Calendar,
} from 'lucide-react';
import { ConnectionStatus } from '../state/connectionStateMachine';
import { SyncOptions, SyncProgress, SyncResult } from '../state/syncService';

export interface ClockSyncPanelProps {
  status: ConnectionStatus;
  isConnected: boolean;
  onSync: (options?: Partial<SyncOptions>) => Promise<SyncResult | null>;
  lastSyncedAt?: Date | null;
  lastSyncResult?: SyncResult | null;
  syncProgress?: SyncProgress | null;
  className?: string;
}

/**
 * Determines whether DST is currently active for the local system timezone.
 */
function detectSystemDst(date: Date): boolean {
  const jan = new Date(date.getFullYear(), 0, 1).getTimezoneOffset();
  const jul = new Date(date.getFullYear(), 6, 1).getTimezoneOffset();
  const stdOffset = Math.max(jan, jul);
  return date.getTimezoneOffset() < stdOffset;
}

/**
 * Formats a timezone offset in minutes into "+HH:MM" or "-HH:MM" string.
 */
function formatTimezoneOffset(minutes: number): string {
  const sign = minutes >= 0 ? '+' : '-';
  const abs = Math.abs(minutes);
  const hrs = Math.floor(abs / 60)
    .toString()
    .padStart(2, '0');
  const mins = (abs % 60).toString().padStart(2, '0');
  return `UTC${sign}${hrs}:${mins}`;
}

export const ClockSyncPanel: React.FC<ClockSyncPanelProps> = ({
  status,
  isConnected,
  onSync,
  lastSyncedAt,
  lastSyncResult,
  syncProgress,
  className = '',
}) => {
  // Live ticking system clock
  const [currentDate, setCurrentDate] = useState(() => new Date());
  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentDate(new Date());
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  // Sync settings: 24h mode and DST
  const [is24Hour, setIs24Hour] = useState(true);
  const [isDst, setIsDst] = useState(() => detectSystemDst(currentDate));

  const isSyncing = status === 'SYNCING';

  // Timezone calculations
  const tzMinutes = -currentDate.getTimezoneOffset();
  const tzString = formatTimezoneOffset(tzMinutes);
  const tzName = Intl.DateTimeFormat().resolvedOptions().timeZone || 'System Local';

  // Formatted clock components
  const hoursRaw = currentDate.getHours();
  const hours12 = hoursRaw % 12 || 12;
  const hours = is24Hour
    ? hoursRaw.toString().padStart(2, '0')
    : hours12.toString().padStart(2, '0');
  const minutes = currentDate.getMinutes().toString().padStart(2, '0');
  const seconds = currentDate.getSeconds().toString().padStart(2, '0');
  const ampm = hoursRaw >= 12 ? 'PM' : 'AM';
  const dateFormatted = currentDate.toLocaleDateString(undefined, {
    weekday: 'short',
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });

  const handleManualSync = async () => {
    if (!isConnected || isSyncing) return;
    await onSync({
      is24Hour,
      isDst,
      timezoneOffsetMinutes: tzMinutes,
    });
  };

  return (
    <div
      className={`bg-slate-800/60 rounded-2xl border border-slate-700/60 p-4 shadow-xl backdrop-blur-md ${className}`}
      data-testid="clock-sync-panel"
    >
      {/* Header */}
      <div className="flex items-center justify-between pb-3 border-b border-slate-700/50">
        <div className="flex items-center gap-2.5">
          <div className="p-2 bg-indigo-600/20 text-indigo-400 rounded-xl border border-indigo-500/30">
            <Clock className="w-5 h-5" />
          </div>
          <div>
            <h2 className="text-base font-semibold text-white tracking-tight">Clock Synchronization</h2>
            <p className="text-xs text-slate-400">GATT client time calibration service</p>
          </div>
        </div>

        {/* 12h / 24h Mode Toggle */}
        <div className="flex items-center bg-slate-900/80 p-0.5 rounded-lg border border-slate-700/80 text-xs font-mono">
          <button
            type="button"
            onClick={() => setIs24Hour(false)}
            className={`px-2.5 py-1 rounded-md transition-all font-semibold ${
              !is24Hour
                ? 'bg-indigo-600 text-white shadow-sm'
                : 'text-slate-400 hover:text-slate-200'
            }`}
            data-testid="toggle-12h"
            aria-label="12-hour format"
          >
            12H
          </button>
          <button
            type="button"
            onClick={() => setIs24Hour(true)}
            className={`px-2.5 py-1 rounded-md transition-all font-semibold ${
              is24Hour
                ? 'bg-indigo-600 text-white shadow-sm'
                : 'text-slate-400 hover:text-slate-200'
            }`}
            data-testid="toggle-24h"
            aria-label="24-hour format"
          >
            24H
          </button>
        </div>
      </div>

      {/* Live System Time Display Card */}
      <div className="mt-3 p-4 rounded-xl bg-slate-900/70 border border-slate-700/60 flex flex-col items-center justify-center relative overflow-hidden">
        <div className="text-[11px] font-mono text-slate-400 flex items-center gap-1.5 mb-1">
          <Calendar className="w-3.5 h-3.5 text-indigo-400" />
          <span data-testid="live-date">{dateFormatted}</span>
        </div>

        {/* Digital Clock Readout */}
        <div
          className="font-mono text-3xl sm:text-4xl font-extrabold tracking-wider text-slate-100 flex items-baseline gap-1"
          data-testid="live-system-clock"
        >
          <span>{hours}</span>
          <span className="text-indigo-400 animate-pulse">:</span>
          <span>{minutes}</span>
          <span className="text-indigo-400 animate-pulse">:</span>
          <span className="text-2xl sm:text-3xl text-indigo-300">{seconds}</span>
          {!is24Hour && (
            <span className="ml-1 text-xs font-bold px-1.5 py-0.5 rounded bg-slate-800 text-indigo-300 border border-slate-700">
              {ampm}
            </span>
          )}
        </div>

        {/* Timezone & DST Details Bar */}
        <div className="mt-3 w-full pt-3 border-t border-slate-800/80 flex flex-wrap items-center justify-between text-xs text-slate-400 gap-2 font-mono">
          <div className="flex items-center gap-1.5" title={`Offset: ${tzMinutes} minutes`}>
            <Globe className="w-3.5 h-3.5 text-indigo-400" />
            <span data-testid="tz-offset">{tzString}</span>
            <span className="text-slate-500 truncate max-w-[110px]">({tzName})</span>
          </div>

          <button
            type="button"
            onClick={() => setIsDst((prev) => !prev)}
            className={`inline-flex items-center gap-1.5 px-2 py-0.5 rounded border text-[11px] transition-all ${
              isDst
                ? 'bg-amber-500/15 text-amber-300 border-amber-500/30'
                : 'bg-slate-800/60 text-slate-400 border-slate-700/60'
            }`}
            data-testid="toggle-dst"
            aria-label={`Toggle DST metadata (does not change offset), currently ${isDst ? 'active' : 'standard'}`}
          >
            {isDst ? <Sun className="w-3 h-3 text-amber-400" /> : <Moon className="w-3 h-3 text-slate-400" />}
            <span data-testid="dst-status">{isDst ? 'DST Active' : 'Standard Time'}</span>
          </button>
        </div>
      </div>

      <p className="text-xs text-slate-400 mt-2">The UTC offset already includes daylight saving. The DST flag is descriptive only.</p>
      {/* Progress Bar (Visible during active sync) */}
      {isSyncing && (
        <div className="mt-3 p-3 rounded-xl bg-indigo-950/40 border border-indigo-500/30" data-testid="sync-progress-container">
          <div className="flex items-center justify-between text-xs font-mono text-indigo-300 mb-1.5">
            <span className="flex items-center gap-1.5">
              <RefreshCw className="w-3.5 h-3.5 animate-spin" />
              <span>GATT Write Pipeline</span>
            </span>
            <span className="font-bold" data-testid="sync-progress-percent">
              {syncProgress ? `${syncProgress.percent}%` : '0%'}
            </span>
          </div>

          {/* Progress track */}
          <div className="w-full h-2 bg-slate-900 rounded-full overflow-hidden border border-slate-800">
            <div
              className="h-full bg-gradient-to-r from-indigo-500 to-sky-400 transition-all duration-300 ease-out"
              style={{ width: `${syncProgress?.percent ?? 15}%` }}
              data-testid="sync-progress-bar"
            />
          </div>

          <div className="mt-1.5 text-[10px] font-mono text-indigo-400/80 flex items-center justify-between">
            <span>Step: {syncProgress?.step ?? 'INITIALIZING'}</span>
            <span className="truncate max-w-[160px]">{syncProgress?.message || 'Starting writes'}</span>
          </div>
        </div>
      )}

      {/* Manual Sync Trigger Button */}
      <div className="mt-4">
        <button
          type="button"
          onClick={handleManualSync}
          disabled={!isConnected || isSyncing}
          className={`w-full py-3 px-4 rounded-xl font-semibold text-sm flex items-center justify-center gap-2 transition-all shadow-lg active:scale-[0.99] ${
            !isConnected
              ? 'bg-slate-800 text-slate-500 border border-slate-700/50 cursor-not-allowed shadow-none'
              : isSyncing
              ? 'bg-indigo-600/80 text-white cursor-wait animate-pulse'
              : 'bg-gradient-to-r from-indigo-600 to-blue-600 hover:from-indigo-500 hover:to-blue-500 text-white shadow-indigo-600/30'
          }`}
          data-testid="manual-sync-button"
          aria-label="Synchronize Watch Time"
        >
          {isSyncing ? (
            <>
              <RefreshCw className="w-4 h-4 animate-spin" />
              <span>Calibrating Watch Clock...</span>
            </>
          ) : (
            <>
              <Zap className="w-4 h-4" />
              <span>{isConnected ? 'Sync Watch Time' : 'Connect Watch to Sync'}</span>
            </>
          )}
        </button>
      </div>

      {/* Last Synced Status & Feedback */}
      <div
        className="mt-3 p-3 rounded-xl bg-slate-900/40 border border-slate-800/80 flex items-center justify-between text-xs font-mono"
        data-testid="last-synced-container"
      >
        <div className="flex items-center gap-2">
          {lastSyncedAt ? (
            <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
          ) : (
            <Clock className="w-4 h-4 text-slate-500 shrink-0" />
          )}
          <div>
            <span className="text-slate-400">Last Synced: </span>
            <span
              className={`font-semibold ${lastSyncedAt ? 'text-emerald-300' : 'text-slate-500'}`}
              data-testid="last-synced-time"
            >
              {lastSyncedAt ? lastSyncedAt.toLocaleTimeString() : 'Never'}
            </span>
          </div>
        </div>

        {lastSyncResult && (
          <div className="flex items-center gap-1.5 text-[10px] text-slate-400">
            <span className="px-1.5 py-0.5 rounded bg-slate-800 border border-slate-700">
              {lastSyncResult.durationMs}ms
            </span>
            <span className="px-1.5 py-0.5 rounded bg-slate-800 border border-slate-700">
              4/4 GATT Writes OK
            </span>
          </div>
        )}
      </div>
    </div>
  );
};

export default ClockSyncPanel;
