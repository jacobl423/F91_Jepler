import React, { useState, useEffect } from 'react';
import { Bluetooth, Cpu } from 'lucide-react';
import { BleClientInterface } from '../ble/bleClientInterface';
import { ConnectionStatus } from '../state/connectionStateMachine';
import { SimulatedWatchState } from '../ble/mockBleService';

export interface MockWatchPreviewProps {
  bleClient?: BleClientInterface;
  status?: ConnectionStatus;
  lastSyncedAt?: Date | null;
  className?: string;
}

const DAYS_OF_WEEK = ['SU', 'MO', 'TU', 'WE', 'TH', 'FR', 'SA'];

export const MockWatchPreview: React.FC<MockWatchPreviewProps> = ({
  bleClient,
  status = 'DISCONNECTED',
  lastSyncedAt,
  className = '',
}) => {
  // Read simulated watch registers from MockBleService if available
  const [watchState, setWatchState] = useState<SimulatedWatchState>(() => {
    if (bleClient && typeof (bleClient as any).getWatchState === 'function') {
      return (bleClient as any).getWatchState();
    }
    return {
      clockTime: 1700000000,
      clockTimezone: -300,
      clockTimeMode: 0,
      clockDst: 0,
    };
  });

  const isMockDriver = Boolean(
    bleClient && typeof (bleClient as any).getWatchState === 'function'
  );

  useEffect(() => {
    const refreshState = () => {
      if (bleClient && typeof (bleClient as any).getWatchState === 'function') {
        const state = (bleClient as any).getWatchState();
        setWatchState(state);
      }
    };

    refreshState();
    // Poll periodically to catch any writes from sync or test harness
    const interval = setInterval(refreshState, 500);
    return () => clearInterval(interval);
  }, [bleClient, lastSyncedAt, status]);

  // Compute local watch time based on registers
  // clockTime is UTC epoch seconds. Offset is minutes from UTC. DST is 1 if active.
  const effectiveEpochSeconds =
    watchState.clockTime + watchState.clockTimezone * 60;
  const watchDate = new Date(effectiveEpochSeconds * 1000);

  const dayOfWeekStr = DAYS_OF_WEEK[watchDate.getUTCDay()] || 'SU';
  const dayOfMonthStr = watchDate.getUTCDate().toString();

  const is24HourMode = watchState.clockTimeMode === 1;
  const rawHours = watchDate.getUTCHours();
  const minutes = watchDate.getUTCMinutes().toString().padStart(2, '0');
  const seconds = watchDate.getUTCSeconds().toString().padStart(2, '0');

  let displayHours = rawHours.toString().padStart(2, '0');
  let ampmIndicator = '';

  if (!is24HourMode) {
    const hours12 = rawHours % 12 || 12;
    displayHours = hours12.toString().padStart(2, '0');
    ampmIndicator = rawHours >= 12 ? 'PM' : 'AM';
  }

  const isConnected = status === 'CONNECTED' || status === 'SYNCING';

  return (
    <div
      className={`bg-slate-800/60 rounded-2xl border border-slate-700/60 p-4 shadow-xl backdrop-blur-md flex flex-col items-center ${className}`}
      data-testid="mock-watch-preview"
    >
      {/* Header */}
      <div className="w-full flex items-center justify-between pb-3 border-b border-slate-700/50 mb-4">
        <div className="flex items-center gap-2">
          <div className="p-1.5 bg-indigo-600/20 text-indigo-400 rounded-lg border border-indigo-500/30">
            <Cpu className="w-4 h-4" />
          </div>
          <div>
            <h3 className="text-sm font-semibold text-white tracking-tight">Simulated Watch Display</h3>
            <p className="text-[11px] text-slate-400">Casio F-91W Smartwatch Hardware Simulation</p>
          </div>
        </div>

        <span className="px-2 py-0.5 rounded text-[10px] font-mono font-medium bg-slate-900 border border-slate-700 text-slate-300">
          {isMockDriver ? 'Mock Driver Active' : 'Hardware Driver'}
        </span>
      </div>

      {/* Casio F-91W Watch Case */}
      <div className="w-full max-w-[340px] flex flex-col items-center">
        {/* Watch Strap Top */}
        <div className="w-36 h-4 bg-zinc-950 rounded-t-lg border-t border-x border-zinc-800 flex justify-center items-center shadow-inner">
          <div className="w-24 h-1 bg-zinc-800/80 rounded" />
        </div>

        {/* Resin Watch Body */}
        <div className="w-full bg-zinc-900 rounded-3xl p-3 border-2 border-zinc-700 shadow-2xl relative select-none">
          {/* Watch Pusher Buttons (Left & Right) */}
          <div className="absolute -left-2 top-10 w-2 h-4 bg-zinc-600 rounded-l border-y border-l border-zinc-500" title="LIGHT button" />
          <div className="absolute -left-2 bottom-10 w-2 h-4 bg-zinc-600 rounded-l border-y border-l border-zinc-500" title="MODE button" />
          <div className="absolute -right-2 bottom-10 w-2 h-4 bg-zinc-600 rounded-r border-y border-r border-zinc-500" title="ALARM / 24HR button" />

          {/* Bezel Silk-Screen Graphics & Branding */}
          <div className="rounded-2xl border-2 border-blue-600/70 p-2.5 bg-black flex flex-col items-center">
            {/* Top Bezel Text */}
            <div className="w-full flex justify-between items-center px-1 mb-1 text-[10px] font-sans font-bold tracking-wider">
              <span className="text-zinc-100 tracking-widest text-[11px]">CASIO</span>
              <span className="text-amber-400 text-[9px] border border-amber-400/40 px-1 rounded-sm">
                WATER RESIST
              </span>
            </div>

            {/* Inner Red & Gold Border Framing LCD */}
            <div className="w-full rounded-xl border border-red-600/60 p-1.5 bg-zinc-950">
              <div className="w-full rounded-lg border border-amber-500/40 p-2 bg-[#9ea78e] shadow-inner text-[#1b2512] font-mono">
                {/* LCD Top Row: Day of week, Alarm indicator, Day of month */}
                <div className="flex justify-between items-center text-xs font-bold tracking-wider px-1">
                  <div className="flex items-center gap-1.5">
                    <span data-testid="watch-day-of-week" className="font-extrabold">
                      {dayOfWeekStr}
                    </span>
                    {isConnected && (
                      <span
                        data-testid="watch-ble-indicator"
                        className="inline-flex items-center text-[10px] font-bold text-[#1b2512]"
                        title="BLE Link Active"
                      >
                        <Bluetooth className="w-3 h-3 stroke-[3]" />
                      </span>
                    )}
                  </div>

                  <div className="flex items-center gap-1.5">
                    {watchState.clockDst === 1 && (
                      <span
                        data-testid="watch-dst-indicator"
                        className="text-[9px] font-extrabold bg-[#1b2512]/15 px-1 rounded"
                      >
                        DST
                      </span>
                    )}
                    <span data-testid="watch-day-of-month" className="font-extrabold text-sm">
                      {dayOfMonthStr}
                    </span>
                  </div>
                </div>

                {/* LCD Middle/Main Row: Mode, Digits (HH:MM:SS) */}
                <div className="flex items-baseline justify-between mt-1 px-1">
                  {/* Mode Indicator: 24H or PM */}
                  <div className="w-7 text-[10px] font-extrabold">
                    {is24HourMode ? (
                      <span data-testid="watch-mode-indicator" className="font-black">
                        24H
                      </span>
                    ) : (
                      <span data-testid="watch-mode-indicator" className="font-black">
                        {ampmIndicator}
                      </span>
                    )}
                  </div>

                  {/* Main Digital Clock Digits */}
                  <div className="flex items-baseline gap-1" data-testid="watch-lcd-screen">
                    <span
                      data-testid="watch-time-display"
                      className="text-3xl sm:text-4xl font-extrabold tracking-tighter"
                    >
                      {displayHours}:{minutes}
                    </span>
                    <span
                      data-testid="watch-seconds-display"
                      className="text-xl sm:text-2xl font-extrabold ml-0.5"
                    >
                      {seconds}
                    </span>
                  </div>
                </div>
              </div>
            </div>

            {/* Bottom Bezel Text */}
            <div className="w-full flex justify-between items-center px-1 mt-1.5 text-[9px] font-sans font-bold">
              <span className="text-zinc-100 font-extrabold text-[10px]">F-91W</span>
              <span className="text-amber-400 text-[8px] tracking-tight">ALARM CHRONOGRAPH</span>
            </div>
          </div>
        </div>

        {/* Watch Strap Bottom */}
        <div className="w-36 h-4 bg-zinc-950 rounded-b-lg border-b border-x border-zinc-800 flex justify-center items-center shadow-inner">
          <div className="w-24 h-1 bg-zinc-800/80 rounded" />
        </div>
      </div>

      {/* Internal Simulated Watch Registers Inspector */}
      <div className="w-full mt-4 p-3 rounded-xl bg-slate-900/60 border border-slate-700/60 text-xs font-mono">
        <div className="flex items-center justify-between text-slate-400 pb-1.5 border-b border-slate-800 text-[11px]">
          <span className="font-semibold text-slate-300">Simulated GATT Registers</span>
          <span className="text-[10px] text-slate-500">Zephyr clock_service.c</span>
        </div>

        <div className="grid grid-cols-2 gap-2 mt-2 text-[11px]">
          <div className="flex flex-col">
            <span className="text-slate-500 text-[10px]">Time (Epoch s):</span>
            <span className="text-slate-200 font-bold truncate" data-testid="watch-registers-time">
              {watchState.clockTime}
            </span>
          </div>

          <div className="flex flex-col">
            <span className="text-slate-500 text-[10px]">Timezone (min):</span>
            <span className="text-slate-200 font-bold" data-testid="watch-registers-tz">
              {watchState.clockTimezone} min ({Math.round(watchState.clockTimezone / 60)}h)
            </span>
          </div>

          <div className="flex flex-col">
            <span className="text-slate-500 text-[10px]">Format Mode:</span>
            <span className="text-slate-200 font-bold" data-testid="watch-registers-mode">
              {watchState.clockTimeMode === 1 ? '1 (24-Hour)' : '0 (12-Hour)'}
            </span>
          </div>

          <div className="flex flex-col">
            <span className="text-slate-500 text-[10px]">DST Flag:</span>
            <span className="text-slate-200 font-bold" data-testid="watch-registers-dst">
              {watchState.clockDst === 1 ? '1 (Daylight Saving)' : '0 (Standard)'}
            </span>
          </div>
        </div>
      </div>
    </div>
  );
};

export default MockWatchPreview;
