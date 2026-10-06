import { describe, it, expect } from 'vitest';
import React from 'react';
import { render, screen } from '@testing-library/react';
import App from '../src/App';
import capacitorConfig from '../capacitor.config';

describe('Milestone 1 Smoke Tests', () => {
  it('should verify test runner and DOM environment', () => {
    expect(typeof window).toBe('object');
    expect(typeof document).toBe('object');
    expect(1 + 1).toBe(2);
  });

  it('should verify capacitor configuration schema and values', () => {
    expect(capacitorConfig.appId).toBe('com.f91jepler.companion');
    expect(capacitorConfig.appName).toBe('F91_Jepler');
    expect(capacitorConfig.webDir).toBe('dist');
  });

  it('should render App component without errors', () => {
    render(React.createElement(App));
    expect(screen.getByText('F91_Jepler')).toBeDefined();
    expect(screen.getByText('Smartwatch Companion')).toBeDefined();
    expect(screen.getByText('Ready for Discovery')).toBeDefined();
    expect(screen.getByText('Disconnected')).toBeDefined();
  });

  it('should verify AndroidManifest.xml contains required BLE permissions', async () => {
    const fs = await import('node:fs');
    const path = await import('node:path');
    const manifestPath = path.resolve(__dirname, '../android/app/src/main/AndroidManifest.xml');
    expect(fs.existsSync(manifestPath)).toBe(true);

    const manifestContent = fs.readFileSync(manifestPath, 'utf-8');
    expect(manifestContent).toContain('android.permission.BLUETOOTH_SCAN');
    expect(manifestContent).toContain('android.permission.BLUETOOTH_CONNECT');
    expect(manifestContent).toContain('android.permission.ACCESS_FINE_LOCATION');
    expect(manifestContent).toContain('android.hardware.bluetooth_le');
  });

  it('should verify Info.plist contains NSBluetoothAlwaysUsageDescription', async () => {
    const fs = await import('node:fs');
    const path = await import('node:path');
    const plistPath = path.resolve(__dirname, '../ios/App/App/Info.plist');
    expect(fs.existsSync(plistPath)).toBe(true);

    const plistContent = fs.readFileSync(plistPath, 'utf-8');
    expect(plistContent).toContain('NSBluetoothAlwaysUsageDescription');
    expect(plistContent).toContain('NSBluetoothPeripheralUsageDescription');
  });

  it('should verify iOS SPM manifest registers Bluetooth LE plugin', async () => {
    const fs = await import('node:fs');
    const path = await import('node:path');
    const spmPath = path.resolve(__dirname, '../ios/App/CapApp-SPM/Package.swift');
    expect(fs.existsSync(spmPath)).toBe(true);

    const spmContent = fs.readFileSync(spmPath, 'utf-8');
    expect(spmContent).toContain('CapacitorCommunityBluetoothLe');
  });
});
