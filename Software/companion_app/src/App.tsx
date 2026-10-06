import React, { useState } from 'react';
import { Capacitor } from '@capacitor/core';
import {
  Watch,
  Cpu,
  Radio,
  AlertTriangle,
  X,
  Smartphone,
} from 'lucide-react';
import './App.css';
import { BleClientInterface } from './ble/bleClientInterface';
import { MockBleService } from './ble/mockBleService';
import { CapacitorBleService } from './ble/capacitorBleService';
import { useBleConnection } from './state/useBleConnection';
import { ConnectionStatusBadge } from './components/ConnectionStatusBadge';
import { DeviceDiscovery } from './components/DeviceDiscovery';
import { ClockSyncPanel } from './components/ClockSyncPanel';
import { MockWatchPreview } from './components/MockWatchPreview';

export interface AppProps {
  clientOverride?: BleClientInterface;
}

export const App: React.FC<AppProps> = ({ clientOverride }) => {
  const isNative = Capacitor.isNativePlatform();

  // State for driver toggle: 'mock' | 'hardware'
  const [driverMode, setDriverMode] = useState<'mock' | 'hardware'>(() => {
    if (clientOverride instanceof CapacitorBleService) return 'hardware';
    if (clientOverride) return 'mock';
    if (isNative) return 'hardware';
    return 'mock';
  });

  const {
    status,
    connectedDevice,
    discoveredDevices,
    error,
    lastSyncedAt,
    lastSyncResult,
    syncProgress,
    isConnected,
    startScan,
    stopScan,
    connect,
    disconnect,
    syncClock,
    clearError,
    bleClient,
    setBleClient,
  } = useBleConnection(
    clientOverride,
    !clientOverride && isNative ? { initialClient: new CapacitorBleService() } : undefined
  );

  // Switch between simulated watch and hardware BLE drivers
  const handleDriverChange = (newMode: 'mock' | 'hardware') => {
    if (newMode === driverMode) return;
    setDriverMode(newMode);
    if (newMode === 'mock') {
      setBleClient(new MockBleService());
    } else {
      setBleClient(new CapacitorBleService());
    }
  };

  return (
    <div className="min-h-screen bg-slate-950 text-slate-100 flex flex-col font-sans safe-area-inset selection:bg-indigo-500 selection:text-white">
      {/* Top Header */}
      <header className="w-full max-w-4xl mx-auto flex flex-col sm:flex-row sm:items-center justify-between pb-4 border-b border-slate-800/80 gap-3">
        {/* Brand & Title */}
        <div className="flex items-center space-x-3">
          <div className="p-2.5 bg-gradient-to-br from-indigo-600 to-blue-700 rounded-2xl text-white shadow-lg shadow-indigo-500/20 border border-indigo-400/30">
            <Watch className="w-6 h-6" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-xl font-extrabold tracking-tight text-white font-mono">
                F91_Jepler
              </h1>
              <span className="px-1.5 py-0.5 rounded text-[10px] font-bold bg-indigo-500/20 text-indigo-300 border border-indigo-500/30">
                PROTOTYPE
              </span>
            </div>
            <p className="text-xs text-slate-400">Smartwatch Companion</p>
          </div>
        </div>

        {/* Driver Selector & Live Connection Badge */}
        <div className="flex items-center justify-between sm:justify-end gap-3 flex-wrap">
          {/* Driver Toggle */}
          <div
            className="flex items-center bg-slate-900 p-1 rounded-xl border border-slate-800 text-xs font-mono shadow-inner"
            data-testid="driver-selector"
          >
            <button
              type="button"
              onClick={() => handleDriverChange('mock')}
              className={`flex items-center gap-1.5 px-2.5 py-1 rounded-lg transition-all font-semibold ${
                driverMode === 'mock'
                  ? 'bg-indigo-600 text-white shadow-sm'
                  : 'text-slate-400 hover:text-slate-200'
              }`}
              data-testid="driver-mock-btn"
              aria-label="Use Simulated Watch Driver"
            >
              <Cpu className="w-3.5 h-3.5" />
              <span>Simulated Watch</span>
            </button>
            <button
              type="button"
              onClick={() => handleDriverChange('hardware')}
              className={`flex items-center gap-1.5 px-2.5 py-1 rounded-lg transition-all font-semibold ${
                driverMode === 'hardware'
                  ? 'bg-indigo-600 text-white shadow-sm'
                  : 'text-slate-400 hover:text-slate-200'
              }`}
              data-testid="driver-hardware-btn"
              aria-label="Use Hardware BLE Driver"
            >
              <Radio className="w-3.5 h-3.5" />
              <span>Hardware BLE</span>
            </button>
          </div>

          {/* Connection Status Badge */}
          <ConnectionStatusBadge
            status={status}
            device={connectedDevice}
            error={error}
            showDetails={true}
          />
        </div>
      </header>

      {/* Error Alert Banner */}
      {error && (
        <div className="w-full max-w-4xl mx-auto mt-4" data-testid="error-alert">
          <div className="flex items-start justify-between p-3.5 rounded-xl bg-rose-950/40 border border-rose-500/40 text-rose-300 text-sm backdrop-blur-sm shadow-lg shadow-rose-950/20">
            <div className="flex items-center gap-2.5">
              <AlertTriangle className="w-5 h-5 text-rose-400 shrink-0" />
              <div>
                <p className="font-semibold text-rose-200">Bluetooth Error</p>
                <p className="text-xs text-rose-300/90 font-mono mt-0.5">{error}</p>
              </div>
            </div>
            <button
              type="button"
              onClick={clearError}
              className="p-1 rounded-lg hover:bg-rose-900/50 text-rose-300 hover:text-white transition-all"
              data-testid="clear-error-button"
              aria-label="Dismiss error"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        </div>
      )}

      {/* Main Content Layout */}
      <main className="w-full max-w-4xl mx-auto flex-1 py-6 space-y-6">
        {/* Top Grid: Discovery and Clock Sync Side-by-Side on Desktop, Stacked on Mobile */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 items-start">
          {/* Card 1: Device Discovery */}
          <DeviceDiscovery
            status={status}
            discoveredDevices={discoveredDevices}
            connectedDevice={connectedDevice}
            onStartScan={startScan}
            onStopScan={stopScan}
            onConnect={connect}
            onDisconnect={disconnect}
          />

          {/* Card 2: Clock Synchronization Panel */}
          <ClockSyncPanel
            status={status}
            isConnected={isConnected}
            onSync={syncClock}
            lastSyncedAt={lastSyncedAt}
            lastSyncResult={lastSyncResult}
            syncProgress={syncProgress}
          />
        </div>

        {/* Card 3: Simulated F-91W Watch Preview */}
        <section aria-labelledby="preview-section-title">
          <h2 id="preview-section-title" className="sr-only">
            Simulated Watch Preview
          </h2>
          <MockWatchPreview
            bleClient={bleClient}
            status={status}
            lastSyncedAt={lastSyncedAt}
          />
        </section>
      </main>

      {/* Footer */}
      <footer className="w-full max-w-4xl mx-auto py-4 border-t border-slate-800/80 text-center text-xs text-slate-500 flex flex-col sm:flex-row items-center justify-between gap-2">
        <div className="flex items-center gap-2">
          <Smartphone className="w-4 h-4 text-slate-400" />
          <span>Capacitor 8 Mobile Architecture &bull; Android &amp; iOS</span>
        </div>
        <div className="font-mono text-[11px] text-slate-400">
          UUID: <code className="bg-slate-900 px-1 py-0.5 rounded text-indigo-400">fa35b2f0-7989-11eb-9439-0242ac130002</code>
        </div>
      </footer>
    </div>
  );
};

export default App;
