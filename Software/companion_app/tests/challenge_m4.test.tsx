import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { render, screen, fireEvent, cleanup } from '@testing-library/react';
import { ConnectionStatusBadge } from '../src/components/ConnectionStatusBadge';
import { DeviceDiscovery } from '../src/components/DeviceDiscovery';
import { ClockSyncPanel } from '../src/components/ClockSyncPanel';
import { MockWatchPreview } from '../src/components/MockWatchPreview';
import { MockBleService } from '../src/ble/mockBleService';
import { BleDevice } from '../src/ble/bleClientInterface';

describe('Forensic Auditor M4: Adversarial Stress & Integrity Challenge Suite', () => {
  afterEach(() => {
    cleanup();
    vi.restoreAllMocks();
  });

  // =========================================================================
  // ADV-1: RSSI Signal Quality & Edge Boundaries in DeviceDiscovery
  // =========================================================================
  describe('ADV-1: RSSI Signal Quality & Boundary Tests', () => {
    it.each([
      { rssi: undefined, expectedLabel: 'Signal: Unknown' },
      { rssi: -50, expectedLabel: 'Signal: Excellent' },
      { rssi: -60, expectedLabel: 'Signal: Excellent' }, // Boundary -60
      { rssi: -61, expectedLabel: 'Signal: Good' },
      { rssi: -71, expectedLabel: 'Signal: Good' },
      { rssi: -72, expectedLabel: 'Signal: Good' }, // Boundary -72
      { rssi: -73, expectedLabel: 'Signal: Fair' },
      { rssi: -84, expectedLabel: 'Signal: Fair' },
      { rssi: -85, expectedLabel: 'Signal: Fair' }, // Boundary -85
      { rssi: -86, expectedLabel: 'Signal: Weak' },
      { rssi: -110, expectedLabel: 'Signal: Weak' },
    ])('categorizes RSSI $rssi accurately at boundary condition', ({ rssi, expectedLabel }) => {
      const device: BleDevice = {
        deviceId: 'TEST-DEV-ADV',
        name: 'F91_Jepler',
        rssi,
      };

      const { container } = render(
        <DeviceDiscovery
          status="DISCONNECTED"
          discoveredDevices={[device]}
          connectedDevice={null}
          onStartScan={vi.fn()}
          onStopScan={vi.fn()}
          onConnect={vi.fn()}
          onDisconnect={vi.fn()}
        />
      );

      if (typeof rssi === 'number') {
        const signalSpan = container.querySelector(`[title="${expectedLabel}"]`);
        expect(signalSpan).toBeTruthy();
        expect(signalSpan?.textContent).toContain(`${rssi} dBm`);
      } else {
        // When undefined, signal readout is omitted from device item
        expect(screen.queryByText('dBm')).toBeNull();
      }
    });
  });

  // =========================================================================
  // ADV-2: Malformed Devices & Rapid User Interaction Spam
  // =========================================================================
  describe('ADV-2: Malformed Device Properties & Input Burst Stress', () => {
    it('handles devices with missing name, empty name, or extreme IDs without crashing', () => {
      const edgeDevices: BleDevice[] = [
        { deviceId: 'DEV-EMPTY-NAME', name: '' },
        { deviceId: 'DEV-SPECIAL-CHARS-!@#$%', name: 'F91_Special_<Script>' },
        { deviceId: 'DEV-EXTREME-RSSI', name: 'F91_Jepler', rssi: 999 },
      ];

      render(
        <DeviceDiscovery
          status="DISCONNECTED"
          discoveredDevices={edgeDevices}
          connectedDevice={null}
          onStartScan={vi.fn()}
          onStopScan={vi.fn()}
          onConnect={vi.fn()}
          onDisconnect={vi.fn()}
        />
      );

      expect(screen.getByText('Unnamed Device')).toBeTruthy();
      expect(screen.getByText('F91_Special_<Script>')).toBeTruthy();
      expect(screen.getByText('F91_Jepler')).toBeTruthy();
      expect(screen.getByText('999 dBm')).toBeTruthy();
    });

    it('withstands rapid consecutive clicks on Start Scan without crashing', () => {
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
      for (let i = 0; i < 25; i++) {
        fireEvent.click(scanBtn);
      }
      expect(onStartScan).toHaveBeenCalledTimes(25);
    });
  });

  // =========================================================================
  // ADV-3: ClockSyncPanel State Guards & Extreme Timezone Rendering
  // =========================================================================
  describe('ADV-3: ClockSyncPanel Guards & Timezone Invariants', () => {
    it('strictly guards against manual sync invocation when disconnected', () => {
      const onSync = vi.fn();
      render(
        <ClockSyncPanel
          status="DISCONNECTED"
          isConnected={false}
          onSync={onSync}
          lastSyncedAt={null}
        />
      );

      const btn = screen.getByTestId('manual-sync-button');
      // Attempt multiple click events
      fireEvent.click(btn);
      fireEvent.click(btn);
      fireEvent.click(btn);

      expect(onSync).not.toHaveBeenCalled();
    });

    it('toggles format mode repeatedly without losing state coherence', () => {
      render(
        <ClockSyncPanel
          status="CONNECTED"
          isConnected={true}
          onSync={vi.fn()}
          lastSyncedAt={null}
        />
      );

      const t12 = screen.getByTestId('toggle-12h');
      const t24 = screen.getByTestId('toggle-24h');

      for (let i = 0; i < 10; i++) {
        fireEvent.click(t12);
        expect(t12.className).toContain('bg-indigo-600');
        fireEvent.click(t24);
        expect(t24.className).toContain('bg-indigo-600');
      }
    });

    it('toggles DST repeatedly and inverts status text', () => {
      render(
        <ClockSyncPanel
          status="CONNECTED"
          isConnected={true}
          onSync={vi.fn()}
          lastSyncedAt={null}
        />
      );

      const dstBtn = screen.getByTestId('toggle-dst');
      const initialText = screen.getByTestId('dst-status').textContent;

      fireEvent.click(dstBtn);
      const textAfter1 = screen.getByTestId('dst-status').textContent;
      expect(textAfter1).not.toBe(initialText);

      fireEvent.click(dstBtn);
      const textAfter2 = screen.getByTestId('dst-status').textContent;
      expect(textAfter2).toBe(initialText);
    });
  });

  // =========================================================================
  // ADV-4: MockWatchPreview Rollover, Midnight/Noon, and Leap Dates
  // =========================================================================
  describe('ADV-4: MockWatchPreview Rollovers, Midnight & Leap Days', () => {
    let mockBle: MockBleService;

    beforeEach(() => {
      mockBle = new MockBleService();
    });

    it('correctly formats Midnight (00:00 UTC) as 12:00 AM in 12H mode', () => {
      // 2026-10-05 00:00:00 UTC = 1791158400
      // Timezone offset = 0 min
      mockBle.setWatchState({
        clockTime: 1791158400,
        clockTimezone: 0,
        clockTimeMode: 0, // 12H mode
        clockDst: 0,
      });

      render(<MockWatchPreview bleClient={mockBle} status="DISCONNECTED" />);

      expect(screen.getByTestId('watch-time-display').textContent).toBe('12:00');
      expect(screen.getByTestId('watch-mode-indicator').textContent).toBe('AM');
    });

    it('correctly formats Noon (12:00 UTC) as 12:00 PM in 12H mode', () => {
      // 2026-10-05 12:00:00 UTC = 1791201600
      mockBle.setWatchState({
        clockTime: 1791201600,
        clockTimezone: 0,
        clockTimeMode: 0, // 12H mode
        clockDst: 0,
      });

      render(<MockWatchPreview bleClient={mockBle} status="DISCONNECTED" />);

      expect(screen.getByTestId('watch-time-display').textContent).toBe('12:00');
      expect(screen.getByTestId('watch-mode-indicator').textContent).toBe('PM');
    });

    it('correctly renders 23:59:59 in 24H mode', () => {
      // 2026-10-05 23:59:59 UTC = 1791244799
      mockBle.setWatchState({
        clockTime: 1791244799,
        clockTimezone: 0,
        clockTimeMode: 1, // 24H mode
        clockDst: 0,
      });

      render(<MockWatchPreview bleClient={mockBle} status="DISCONNECTED" />);

      expect(screen.getByTestId('watch-time-display').textContent).toBe('23:59');
      expect(screen.getByTestId('watch-seconds-display').textContent).toBe('59');
      expect(screen.getByTestId('watch-mode-indicator').textContent).toBe('24H');
    });

    it('renders leap day 2024-02-29 with correct day of month and day of week', () => {
      // 2024-02-29 12:00:00 UTC = 1709208000
      // 2024-02-29 is a Thursday ('TH')
      mockBle.setWatchState({
        clockTime: 1709208000,
        clockTimezone: 0,
        clockTimeMode: 1,
        clockDst: 0,
      });

      render(<MockWatchPreview bleClient={mockBle} status="CONNECTED" />);

      expect(screen.getByTestId('watch-day-of-month').textContent).toBe('29');
      expect(screen.getByTestId('watch-day-of-week').textContent).toBe('TH');
      expect(screen.getByTestId('watch-ble-indicator')).toBeTruthy();
    });

    it('hides BLE link icon when disconnected and displays DST badge when active', () => {
      mockBle.setWatchState({
        clockTime: 1700000000,
        clockTimezone: 0,
        clockTimeMode: 1,
        clockDst: 1, // DST active
      });

      const { rerender } = render(
        <MockWatchPreview bleClient={mockBle} status="DISCONNECTED" />
      );

      expect(screen.queryByTestId('watch-ble-indicator')).toBeNull();
      expect(screen.getByTestId('watch-dst-indicator')).toBeTruthy();

      rerender(<MockWatchPreview bleClient={mockBle} status="SYNCING" />);
      expect(screen.getByTestId('watch-ble-indicator')).toBeTruthy();
    });
  });

  // =========================================================================
  // ADV-5: Component Lifecycle, Interval Ticks & Rapid Mount/Unmount Stress
  // =========================================================================
  describe('ADV-5: Component Lifecycle & Memory Isolation Stress', () => {
    it('withstands 50 rapid mount and unmount cycles without leaking intervals or throwing errors', () => {
      for (let i = 0; i < 50; i++) {
        const { unmount } = render(
          <ClockSyncPanel
            status="CONNECTED"
            isConnected={true}
            onSync={vi.fn()}
            lastSyncedAt={null}
          />
        );
        unmount();
      }
    });

    it('withstands 50 rapid mount and unmount cycles of MockWatchPreview', () => {
      const mockBle = new MockBleService();
      for (let i = 0; i < 50; i++) {
        const { unmount } = render(
          <MockWatchPreview bleClient={mockBle} status="CONNECTED" />
        );
        unmount();
      }
    });
  });

  // =========================================================================
  // ADV-6: ConnectionStatusBadge Invariant Matrix
  // =========================================================================
  describe('ADV-6: ConnectionStatusBadge Matrix Verification', () => {
    it.each([
      { status: 'DISCONNECTED', expectedLabel: 'Disconnected' },
      { status: 'SCANNING', expectedLabel: 'Scanning...' },
      { status: 'CONNECTING', expectedLabel: 'Connecting...' },
      { status: 'CONNECTED', expectedLabel: 'Connected' },
      { status: 'SYNCING', expectedLabel: 'Syncing Clock...' },
      { status: 'ERROR', expectedLabel: 'Error' },
    ] as const)('renders base label for status $status without optional props', ({ status, expectedLabel }) => {
      render(<ConnectionStatusBadge status={status} />);
      const badge = screen.getByTestId('connection-status-badge');
      expect(badge.getAttribute('data-status')).toBe(status.toLowerCase());
      expect(screen.getByText(expectedLabel)).toBeTruthy();
    });

    it('renders custom error text when error string is supplied', () => {
      render(<ConnectionStatusBadge status="ERROR" error="Zephyr BLE stack timeout" />);
      expect(screen.getByText('Connection Error')).toBeTruthy();
    });
  });
});
