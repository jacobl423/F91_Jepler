import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, fireEvent, act, waitFor, cleanup } from '@testing-library/react';
import { ConnectionStatusBadge } from '../src/components/ConnectionStatusBadge';
import { DeviceDiscovery } from '../src/components/DeviceDiscovery';
import { ClockSyncPanel } from '../src/components/ClockSyncPanel';
import { MockWatchPreview } from '../src/components/MockWatchPreview';
import App from '../src/App';
import { Capacitor } from '@capacitor/core';
import { MockBleService } from '../src/ble/mockBleService';
import { BleDevice } from '../src/ble/bleClientInterface';
import { SyncProgress, SyncResult } from '../src/state/syncService';

describe('Milestone 4: UI Components & Visual Synchronization Panel', () => {
  afterEach(() => {
    cleanup();
    vi.restoreAllMocks();
  });

  // =========================================================================
  // 1. ConnectionStatusBadge Tests
  // =========================================================================
  describe('ConnectionStatusBadge Component', () => {
    it('renders DISCONNECTED state with proper text and styling', () => {
      render(<ConnectionStatusBadge status="DISCONNECTED" />);
      const badge = screen.getByTestId('connection-status-badge');
      expect(badge).toBeTruthy();
      expect(badge.getAttribute('data-status')).toBe('disconnected');
      expect(screen.getByText('Disconnected')).toBeTruthy();
    });

    it('renders SCANNING state with pulsing indicator', () => {
      render(<ConnectionStatusBadge status="SCANNING" />);
      const badge = screen.getByTestId('connection-status-badge');
      expect(badge.getAttribute('data-status')).toBe('scanning');
      expect(screen.getByText('Scanning...')).toBeTruthy();
    });

    it('renders CONNECTING state with loader text', () => {
      render(<ConnectionStatusBadge status="CONNECTING" />);
      const badge = screen.getByTestId('connection-status-badge');
      expect(badge.getAttribute('data-status')).toBe('connecting');
      expect(screen.getByText('Connecting...')).toBeTruthy();
    });

    it('renders CONNECTED state with device name when provided', () => {
      const mockDevice: BleDevice = {
        deviceId: 'F91-WATCH-SIM-01',
        name: 'F91_Jepler',
        rssi: -58,
      };
      render(<ConnectionStatusBadge status="CONNECTED" device={mockDevice} showDetails={true} />);
      const badge = screen.getByTestId('connection-status-badge');
      expect(badge.getAttribute('data-status')).toBe('connected');
      expect(screen.getByText('Connected: F91_Jepler')).toBeTruthy();
      expect(screen.getByText('F91-WATCH-SIM-01')).toBeTruthy();
      expect(screen.getByText('-58 dBm')).toBeTruthy();
    });

    it('renders SYNCING state with Syncing Clock text', () => {
      render(<ConnectionStatusBadge status="SYNCING" />);
      const badge = screen.getByTestId('connection-status-badge');
      expect(badge.getAttribute('data-status')).toBe('syncing');
      expect(screen.getByText('Syncing Clock...')).toBeTruthy();
    });

    it('renders ERROR state with error label', () => {
      render(<ConnectionStatusBadge status="ERROR" error="GATT timeout" />);
      const badge = screen.getByTestId('connection-status-badge');
      expect(badge.getAttribute('data-status')).toBe('error');
      expect(screen.getByText('Connection Error')).toBeTruthy();
    });

    it('exposes accessible role="status" and aria-live attributes', () => {
      const { container } = render(<ConnectionStatusBadge status="CONNECTED" />);
      const wrapper = container.querySelector('[role="status"]');
      expect(wrapper).toBeTruthy();
      expect(wrapper?.getAttribute('aria-live')).toBe('polite');
    });
  });

  // =========================================================================
  // 2. DeviceDiscovery Component Tests
  // =========================================================================
  describe('DeviceDiscovery Component', () => {
    const mockDevice: BleDevice = {
      deviceId: 'F91-TEST-01',
      name: 'F91_Jepler',
      rssi: -65,
    };

    it('renders empty list message when no devices are discovered', () => {
      render(
        <DeviceDiscovery
          status="DISCONNECTED"
          discoveredDevices={[]}
          connectedDevice={null}
          onStartScan={vi.fn()}
          onStopScan={vi.fn()}
          onConnect={vi.fn()}
          onDisconnect={vi.fn()}
        />
      );
      expect(screen.getByTestId('empty-device-list')).toBeTruthy();
      expect(screen.getByText('No devices discovered')).toBeTruthy();
      expect(screen.getByTestId('scan-button')).toBeTruthy();
    });

    it('triggers onStartScan when "Scan for Watches" button is clicked', () => {
      const onStartScan = vi.fn();
      render(
        <DeviceDiscovery
          status="DISCONNECTED"
          discoveredDevices={[]}
          connectedDevice={null}
          onStartScan={onStartScan}
          onStopScan={vi.fn()}
          onConnect={vi.fn()}
          onDisconnect={vi.fn()}
        />
      );

      const scanBtn = screen.getByTestId('scan-button');
      fireEvent.click(scanBtn);
      expect(onStartScan).toHaveBeenCalledTimes(1);
    });

    it('renders "Stop Scan" button during active SCANNING state and calls onStopScan', () => {
      const onStopScan = vi.fn();
      render(
        <DeviceDiscovery
          status="SCANNING"
          discoveredDevices={[]}
          connectedDevice={null}
          onStartScan={vi.fn()}
          onStopScan={onStopScan}
          onConnect={vi.fn()}
          onDisconnect={vi.fn()}
        />
      );

      expect(screen.getByText('Searching for F91_Jepler watches...')).toBeTruthy();
      const stopBtn = screen.getByTestId('scan-stop-button');
      expect(stopBtn).toBeTruthy();
      fireEvent.click(stopBtn);
      expect(onStopScan).toHaveBeenCalledTimes(1);
    });

    it('renders discovered devices with name, ID, RSSI, and Connect button', () => {
      const onConnect = vi.fn();
      render(
        <DeviceDiscovery
          status="DISCONNECTED"
          discoveredDevices={[mockDevice]}
          connectedDevice={null}
          onStartScan={vi.fn()}
          onStopScan={vi.fn()}
          onConnect={onConnect}
          onDisconnect={vi.fn()}
        />
      );

      expect(screen.getByText('F91_Jepler')).toBeTruthy();
      expect(screen.getByText('F91-TEST-01')).toBeTruthy();
      expect(screen.getByText('-65 dBm')).toBeTruthy();
      expect(screen.getByText('F-91W')).toBeTruthy();

      const connectBtn = screen.getByTestId('connect-btn-F91-TEST-01');
      expect(connectBtn).toBeTruthy();
      fireEvent.click(connectBtn);
      expect(onConnect).toHaveBeenCalledWith(mockDevice);
    });

    it('renders "Disconnect" button for connected device and triggers onDisconnect', () => {
      const onDisconnect = vi.fn();
      render(
        <DeviceDiscovery
          status="CONNECTED"
          discoveredDevices={[mockDevice]}
          connectedDevice={mockDevice}
          onStartScan={vi.fn()}
          onStopScan={vi.fn()}
          onConnect={vi.fn()}
          onDisconnect={onDisconnect}
        />
      );

      const disconnectBtn = screen.getByTestId('disconnect-btn-F91-TEST-01');
      expect(disconnectBtn).toBeTruthy();
      fireEvent.click(disconnectBtn);
      expect(onDisconnect).toHaveBeenCalledTimes(1);
    });

    it('disables scan button when status is CONNECTING or SYNCING', () => {
      render(
        <DeviceDiscovery
          status="CONNECTING"
          discoveredDevices={[]}
          connectedDevice={null}
          onStartScan={vi.fn()}
          onStopScan={vi.fn()}
          onConnect={vi.fn()}
          onDisconnect={vi.fn()}
        />
      );
      const scanBtn = screen.getByTestId('scan-button');
      expect((scanBtn as HTMLButtonElement).disabled).toBe(true);
    });
  });

  // =========================================================================
  // 3. ClockSyncPanel Component Tests
  // =========================================================================
  describe('ClockSyncPanel Component', () => {
    it('renders live system clock and timezone information', () => {
      render(
        <ClockSyncPanel
          status="DISCONNECTED"
          isConnected={false}
          onSync={vi.fn()}
          lastSyncedAt={null}
        />
      );

      expect(screen.getByTestId('live-system-clock')).toBeTruthy();
      expect(screen.getByTestId('tz-offset')).toBeTruthy();
      expect(screen.getByTestId('last-synced-time').textContent).toBe('Never');
    });

    it('toggles between 12-hour and 24-hour display format', () => {
      render(
        <ClockSyncPanel
          status="DISCONNECTED"
          isConnected={false}
          onSync={vi.fn()}
          lastSyncedAt={null}
        />
      );

      const toggle12h = screen.getByTestId('toggle-12h');
      const toggle24h = screen.getByTestId('toggle-24h');

      fireEvent.click(toggle12h);
      expect(screen.getByTestId('toggle-12h').className).toContain('bg-indigo-600');

      fireEvent.click(toggle24h);
      expect(screen.getByTestId('toggle-24h').className).toContain('bg-indigo-600');
    });

    it('toggles Daylight Saving Time status', () => {
      render(
        <ClockSyncPanel
          status="DISCONNECTED"
          isConnected={false}
          onSync={vi.fn()}
          lastSyncedAt={null}
        />
      );

      const dstBtn = screen.getByTestId('toggle-dst');
      const initialText = screen.getByTestId('dst-status').textContent;

      fireEvent.click(dstBtn);
      const newText = screen.getByTestId('dst-status').textContent;
      expect(newText).not.toBe(initialText);
    });

    it('disables manual sync button when disconnected', () => {
      const onSync = vi.fn();
      render(
        <ClockSyncPanel
          status="DISCONNECTED"
          isConnected={false}
          onSync={onSync}
          lastSyncedAt={null}
        />
      );

      const syncBtn = screen.getByTestId('manual-sync-button') as HTMLButtonElement;
      expect(syncBtn.disabled).toBe(true);
      expect(syncBtn.textContent).toContain('Connect Watch to Sync');
      fireEvent.click(syncBtn);
      expect(onSync).not.toHaveBeenCalled();
    });

    it('enables manual sync button when connected and triggers onSync on click', async () => {
      const onSync = vi.fn().mockResolvedValue(null);
      render(
        <ClockSyncPanel
          status="CONNECTED"
          isConnected={true}
          onSync={onSync}
          lastSyncedAt={null}
        />
      );

      const syncBtn = screen.getByTestId('manual-sync-button') as HTMLButtonElement;
      expect(syncBtn.disabled).toBe(false);
      expect(syncBtn.textContent).toContain('Sync Watch Time');

      await act(async () => {
        fireEvent.click(syncBtn);
      });

      expect(onSync).toHaveBeenCalledTimes(1);
      expect(onSync).toHaveBeenCalledWith(
        expect.objectContaining({
          is24Hour: true,
          timezoneOffsetMinutes: expect.any(Number),
        })
      );
    });

    it('renders progress bar when SYNCING with syncProgress details', () => {
      const progress: SyncProgress = {
        step: 'TIMEZONE',
        percent: 50,
        message: 'Writing Timezone Characteristic',
      };

      render(
        <ClockSyncPanel
          status="SYNCING"
          isConnected={true}
          onSync={vi.fn()}
          lastSyncedAt={null}
          syncProgress={progress}
        />
      );

      expect(screen.getByTestId('sync-progress-container')).toBeTruthy();
      expect(screen.getByTestId('sync-progress-percent').textContent).toBe('50%');
      expect(screen.getByText('Step: TIMEZONE')).toBeTruthy();
      expect(screen.getByText('Writing Timezone Characteristic')).toBeTruthy();
    });

    it('renders last synced timestamp and duration when sync succeeds', () => {
      const syncDate = new Date(1700000000 * 1000);
      const mockResult: SyncResult = {
        success: true,
        timestamp: 1700000000,
        localTimeIso: syncDate.toISOString(),
        timezoneOffsetMinutes: -300,
        timezoneFormatted: 'UTC-05:00',
        is24Hour: true,
        isDst: false,
        durationMs: 42,
        stepsCompleted: 4,
        data: {
          timestamp: 1700000000,
          timezoneOffsetMinutes: -300,
          is24Hour: true,
          isDst: false,
        },
        payloadHex: {
          time: '00112233',
          timezone: '4455',
          timeMode: '01',
          dst: '00',
        },
      };

      render(
        <ClockSyncPanel
          status="CONNECTED"
          isConnected={true}
          onSync={vi.fn()}
          lastSyncedAt={syncDate}
          lastSyncResult={mockResult}
        />
      );

      expect(screen.getByTestId('last-synced-time').textContent).not.toBe('Never');
      expect(screen.getByText('42ms')).toBeTruthy();
      expect(screen.getByText('4/4 GATT Writes OK')).toBeTruthy();
    });
  });

  // =========================================================================
  // 4. MockWatchPreview Component Tests
  // =========================================================================
  describe('MockWatchPreview Component', () => {
    it('renders Casio F-91W bezel markings and digital LCD screen', () => {
      const mockBle = new MockBleService();
      render(<MockWatchPreview bleClient={mockBle} status="DISCONNECTED" />);

      expect(screen.getByText('CASIO')).toBeTruthy();
      expect(screen.getByText('WATER RESIST')).toBeTruthy();
      expect(screen.getByText('F-91W')).toBeTruthy();
      expect(screen.getByText('ALARM CHRONOGRAPH')).toBeTruthy();
      expect(screen.getByTestId('watch-lcd-screen')).toBeTruthy();
      expect(screen.getByTestId('watch-time-display')).toBeTruthy();
      expect(screen.getByTestId('watch-seconds-display')).toBeTruthy();
    });

    it('displays simulated watch registers from MockBleService', () => {
      const mockBle = new MockBleService();
      mockBle.setWatchState({
        clockTime: 1700000000,
        clockTimezone: -300,
        clockTimeMode: 1,
        clockDst: 1,
      });

      render(<MockWatchPreview bleClient={mockBle} status="CONNECTED" />);

      expect(screen.getByTestId('watch-registers-time').textContent).toBe('1700000000');
      expect(screen.getByTestId('watch-registers-tz').textContent).toContain('-300 min');
      expect(screen.getByTestId('watch-registers-mode').textContent).toContain('24-Hour');
      expect(screen.getByTestId('watch-registers-dst').textContent).toContain('Daylight Saving');

      // LCD Indicators
      expect(screen.getByTestId('watch-mode-indicator').textContent).toBe('24H');
      expect(screen.getByTestId('watch-dst-indicator')).toBeTruthy();
      expect(screen.getByTestId('watch-ble-indicator')).toBeTruthy();
    });

    it('renders 12-hour AM/PM indicator when clockTimeMode is 0', () => {
      const mockBle = new MockBleService();
      mockBle.setWatchState({
        clockTimeMode: 0,
        clockDst: 0,
      });

      render(<MockWatchPreview bleClient={mockBle} status="DISCONNECTED" />);
      const modeIndicator = screen.getByTestId('watch-mode-indicator');
      expect(['AM', 'PM']).toContain(modeIndicator.textContent);
    });
  });

  // =========================================================================
  // 5. App Full Integration & End-to-End Workflow Tests
  // =========================================================================
  describe('App Full Integration Workflow', () => {
    let mockBle: MockBleService;

    beforeEach(() => {
      mockBle = new MockBleService();
    });

    it('renders header, driver controls, discovery, sync panel, and LCD preview', () => {
      render(<App clientOverride={mockBle} />);

      expect(screen.getByText('F91_Jepler')).toBeTruthy();
      expect(screen.getByText('Smartwatch Companion')).toBeTruthy();
      expect(screen.getByTestId('driver-selector')).toBeTruthy();
      expect(screen.getByTestId('device-discovery')).toBeTruthy();
      expect(screen.getByTestId('clock-sync-panel')).toBeTruthy();
      expect(screen.getByTestId('mock-watch-preview')).toBeTruthy();
    });

    it('switches between Simulated Watch and Hardware BLE drivers', () => {
      render(<App clientOverride={mockBle} />);

      const mockBtn = screen.getByTestId('driver-mock-btn');
      const hwBtn = screen.getByTestId('driver-hardware-btn');

      expect(mockBtn.className).toContain('bg-indigo-600');

      fireEvent.click(hwBtn);
      expect(hwBtn.className).toContain('bg-indigo-600');

      fireEvent.click(mockBtn);
      expect(mockBtn.className).toContain('bg-indigo-600');
    });

    it('defaults to hardware BLE driver when Capacitor.isNativePlatform() is true', () => {
      vi.spyOn(Capacitor, 'isNativePlatform').mockReturnValue(true);
      render(<App />);

      const hwBtn = screen.getByTestId('driver-hardware-btn');
      const mockBtn = screen.getByTestId('driver-mock-btn');

      expect(hwBtn.className).toContain('bg-indigo-600');
      expect(mockBtn.className).not.toContain('bg-indigo-600');
    });

    it('defaults to simulated watch driver when Capacitor.isNativePlatform() is false', () => {
      vi.spyOn(Capacitor, 'isNativePlatform').mockReturnValue(false);
      render(<App />);

      const hwBtn = screen.getByTestId('driver-hardware-btn');
      const mockBtn = screen.getByTestId('driver-mock-btn');

      expect(mockBtn.className).toContain('bg-indigo-600');
      expect(hwBtn.className).not.toContain('bg-indigo-600');
    });

    it('displays and clears error alert banner', async () => {
      render(<App clientOverride={mockBle} />);

      // Trigger error via connection failure simulation
      mockBle.failNextConnection('Test BLE Radio Timeout');
      const scanBtn = screen.getByTestId('scan-button');

      await act(async () => {
        fireEvent.click(scanBtn);
      });

      // Find discovered device
      const connectBtn = await screen.findByTestId('connect-btn-F91-WATCH-SIM-01');
      await act(async () => {
        fireEvent.click(connectBtn);
      });

      // Error alert should now be visible
      const errorAlert = await screen.findByTestId('error-alert');
      expect(errorAlert.textContent).toContain('Test BLE Radio Timeout');

      // Dismiss error
      const clearBtn = screen.getByTestId('clear-error-button');
      act(() => {
        fireEvent.click(clearBtn);
      });

      expect(screen.queryByTestId('error-alert')).toBeNull();
    });

    it('executes full end-to-end user flow: scan -> connect -> sync -> verify LCD updated', async () => {
      render(<App clientOverride={mockBle} />);

      // Initial state: Disconnected
      expect(screen.getByTestId('connection-status-badge').getAttribute('data-status')).toBe('disconnected');
      expect((screen.getByTestId('manual-sync-button') as HTMLButtonElement).disabled).toBe(true);

      // 1. Scan for devices
      const scanBtn = screen.getByTestId('scan-button');
      await act(async () => {
        fireEvent.click(scanBtn);
      });

      // 2. Locate discovered F91_Jepler device
      const connectBtn = await screen.findByTestId('connect-btn-F91-WATCH-SIM-01');
      expect(connectBtn).toBeTruthy();

      // 3. Connect to the watch
      await act(async () => {
        fireEvent.click(connectBtn);
      });

      // Verify connected state
      await waitFor(() => {
        expect(screen.getByTestId('connection-status-badge').getAttribute('data-status')).toBe('connected');
      });
      expect(screen.getByTestId('disconnect-btn-F91-WATCH-SIM-01')).toBeTruthy();

      // 4. Manual Sync button should now be enabled
      const syncBtn = screen.getByTestId('manual-sync-button') as HTMLButtonElement;
      expect(syncBtn.disabled).toBe(false);

      // 5. Trigger manual clock sync
      await act(async () => {
        fireEvent.click(syncBtn);
      });

      // Verify successful sync confirmation
      await waitFor(() => {
        expect(screen.getByTestId('last-synced-time').textContent).not.toBe('Never');
      });
      expect(screen.getByText('4/4 GATT Writes OK')).toBeTruthy();

      // Verify that mock BLE service received the sequential writes
      const writeHistory = mockBle.getWriteHistory();
      expect(writeHistory.length).toBe(4);

      // Verify that MockWatchPreview LCD registers match the written time
      const watchState = mockBle.getWatchState();
      await waitFor(() => {
        expect(screen.getByTestId('watch-registers-time').textContent).toBe(String(watchState.clockTime));
      });

      // 6. Disconnect cleanly
      const disconnectBtn = screen.getByTestId('disconnect-btn-F91-WATCH-SIM-01');
      await act(async () => {
        fireEvent.click(disconnectBtn);
      });

      await waitFor(() => {
        expect(screen.getByTestId('connection-status-badge').getAttribute('data-status')).toBe('disconnected');
      });
    });
  });
});
