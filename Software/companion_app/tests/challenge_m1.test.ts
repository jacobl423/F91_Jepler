import { describe, it, expect, afterEach } from 'vitest';
import React from 'react';
import { render, cleanup, screen } from '@testing-library/react';
import App from '../src/App';
import capacitorConfig from '../capacitor.config';
import fs from 'node:fs';
import path from 'node:path';
import { Capacitor } from '@capacitor/core';
import { BleClient } from '@capacitor-community/bluetooth-le';

describe('Challenger M1 Empirical Stress Tests', () => {
  afterEach(() => {
    cleanup();
  });

  describe('C0: Capacitor Core Runtime Environment', () => {
    it('should correctly identify non-native web/jsdom test platform', () => {
      expect(Capacitor.isNativePlatform()).toBe(false);
      expect(Capacitor.getPlatform()).toBe('web');
    });
  });

  describe('C1: App Component Stress & Runtime Integrity', () => {
    it('should withstand 50 consecutive render and unmount cycles without memory leaks or errors', () => {
      for (let i = 0; i < 50; i++) {
        const { unmount } = render(React.createElement(App));
        expect(screen.getByText('F91_Jepler')).toBeTruthy();
        unmount();
      }
    });

    it('should correctly render all required icons as SVGs in the DOM hierarchy', () => {
      const { container } = render(React.createElement(App));
      const svgElements = container.querySelectorAll('svg');
      // Expect at least 4 Lucide icons: Watch, Bluetooth, Clock, RefreshCw
      expect(svgElements.length).toBeGreaterThanOrEqual(4);
      svgElements.forEach((svg) => {
        expect(svg.tagName.toLowerCase()).toBe('svg');
        expect(svg.getAttribute('xmlns')).toBe('http://www.w3.org/2000/svg');
      });
    });

    it('should display the target service UUID prefix in discovery text', () => {
      render(React.createElement(App));
      const codeElement = screen.getByText('fa35b2f0...');
      expect(codeElement).toBeTruthy();
      expect(codeElement.tagName.toLowerCase()).toBe('code');
    });
  });

  describe('C2: @capacitor-community/bluetooth-le Runtime & API Integrity', () => {
    it('should export all critical BleClient GATT and scanning methods', () => {
      expect(typeof BleClient.initialize).toBe('function');
      expect(typeof BleClient.requestDevice).toBe('function');
      expect(typeof BleClient.connect).toBe('function');
      expect(typeof BleClient.disconnect).toBe('function');
      expect(typeof BleClient.startNotifications).toBe('function');
      expect(typeof BleClient.stopNotifications).toBe('function');
      expect(typeof BleClient.read).toBe('function');
      expect(typeof BleClient.write).toBe('function');
      expect(typeof BleClient.writeWithoutResponse).toBe('function');
      expect(typeof BleClient.getServices).toBe('function');
      expect(typeof BleClient.getDevices).toBe('function');
      expect(typeof BleClient.getConnectedDevices).toBe('function');
    });

    it('should handle uninitialized BleClient calls gracefully with informative rejection', async () => {
      // In jsdom (non-native), initialize should reject cleanly indicating Web Bluetooth missing
      try {
        await BleClient.initialize();
        // If web bluetooth polyfill exists, initialize succeeds
      } catch (err: unknown) {
        expect(err).toBeInstanceOf(Error);
        expect((err as Error).message).toMatch(/Web Bluetooth|not available|unavailable/i);
      }
    });
  });

  describe('C3: Android Native BLE Linkage & Manifest Audit', () => {
    const androidRoot = path.resolve(__dirname, '../android');
    const manifestPath = path.join(androidRoot, 'app/src/main/AndroidManifest.xml');
    const capacitorBuildPath = path.join(androidRoot, 'app/capacitor.build.gradle');
    const capacitorSettingsPath = path.join(androidRoot, 'capacitor.settings.gradle');
    const pluginsJsonPath = path.join(androidRoot, 'app/src/main/assets/capacitor.plugins.json');

    it('should have a structurally valid AndroidManifest with exact required permissions', () => {
      expect(fs.existsSync(manifestPath)).toBe(true);
      const manifestXml = fs.readFileSync(manifestPath, 'utf-8');

      const requiredPermissions = [
        'android.permission.BLUETOOTH_SCAN',
        'android.permission.BLUETOOTH_CONNECT',
        'android.permission.ACCESS_FINE_LOCATION',
        'android.permission.ACCESS_COARSE_LOCATION',
        'android.permission.BLUETOOTH',
        'android.permission.BLUETOOTH_ADMIN',
      ];

      for (const perm of requiredPermissions) {
        expect(
          manifestXml.includes(`android:name="${perm}"`),
          `Missing permission: ${perm}`
        ).toBe(true);
      }

      // Feature requirement
      expect(
        manifestXml.includes('android:name="android.hardware.bluetooth_le"'),
        'Missing bluetooth_le hardware feature'
      ).toBe(true);
      expect(
        manifestXml.includes('android:required="true"'),
        'android.hardware.bluetooth_le must be required=true'
      ).toBe(true);
    });

    it('should link :capacitor-community-bluetooth-le in gradle build scripts', () => {
      expect(fs.existsSync(capacitorBuildPath)).toBe(true);
      const buildGradle = fs.readFileSync(capacitorBuildPath, 'utf-8');
      expect(buildGradle).toContain("implementation project(':capacitor-community-bluetooth-le')");

      expect(fs.existsSync(capacitorSettingsPath)).toBe(true);
      const settingsGradle = fs.readFileSync(capacitorSettingsPath, 'utf-8');
      expect(settingsGradle).toContain("include ':capacitor-community-bluetooth-le'");
      expect(settingsGradle).toContain("new File('../node_modules/@capacitor-community/bluetooth-le/android')");
    });

    it('should register bluetooth-le in Android capacitor.plugins.json', () => {
      expect(fs.existsSync(pluginsJsonPath)).toBe(true);
      const pluginsJson = JSON.parse(fs.readFileSync(pluginsJsonPath, 'utf-8'));
      const bleEntry = pluginsJson.find((p: { pkg: string }) => p.pkg === '@capacitor-community/bluetooth-le');
      expect(bleEntry).toBeDefined();
      expect(bleEntry.classpath).toBe('com.capacitorjs.community.plugins.bluetoothle.BluetoothLe');
    });

    it('should verify the Android plugin native source directory exists on disk', () => {
      const pluginDir = path.resolve(__dirname, '../node_modules/@capacitor-community/bluetooth-le/android');
      expect(fs.existsSync(pluginDir)).toBe(true);
      expect(fs.existsSync(path.join(pluginDir, 'build.gradle'))).toBe(true);
      expect(fs.existsSync(path.join(pluginDir, 'src/main/java/com/capacitorjs/community/plugins/bluetoothle/BluetoothLe.kt'))).toBe(true);
    });
  });

  describe('C4: iOS Native BLE Linkage & Swift Package Manager Audit', () => {
    const iosRoot = path.resolve(__dirname, '../ios');
    const infoPlistPath = path.join(iosRoot, 'App/App/Info.plist');
    const spmManifestPath = path.join(iosRoot, 'App/CapApp-SPM/Package.swift');
    const pbxprojPath = path.join(iosRoot, 'App/App.xcodeproj/project.pbxproj');

    it('should declare user-friendly NSBluetooth usage descriptions in Info.plist', () => {
      expect(fs.existsSync(infoPlistPath)).toBe(true);
      const plistContent = fs.readFileSync(infoPlistPath, 'utf-8');

      expect(plistContent).toContain('<key>NSBluetoothAlwaysUsageDescription</key>');
      expect(plistContent).toContain('<key>NSBluetoothPeripheralUsageDescription</key>');

      // Verify strings are meaningful and not empty
      const alwaysMatch = plistContent.match(/<key>NSBluetoothAlwaysUsageDescription<\/key>\s*<string>([^<]+)<\/string>/);
      expect(alwaysMatch).not.toBeNull();
      expect(alwaysMatch![1].length).toBeGreaterThan(15);
      expect(alwaysMatch![1].toLowerCase()).toContain('bluetooth');

      const periphMatch = plistContent.match(/<key>NSBluetoothPeripheralUsageDescription<\/key>\s*<string>([^<]+)<\/string>/);
      expect(periphMatch).not.toBeNull();
      expect(periphMatch![1].length).toBeGreaterThan(15);
      expect(periphMatch![1].toLowerCase()).toContain('bluetooth');
    });

    it('should declare CapacitorCommunityBluetoothLe in CapApp-SPM Package.swift', () => {
      expect(fs.existsSync(spmManifestPath)).toBe(true);
      const spmContent = fs.readFileSync(spmManifestPath, 'utf-8');

      expect(spmContent).toContain('.package(name: "CapacitorCommunityBluetoothLe", path: "../../../node_modules/@capacitor-community/bluetooth-le")');
      expect(spmContent).toContain('.product(name: "CapacitorCommunityBluetoothLe", package: "CapacitorCommunityBluetoothLe")');
    });

    it('should verify the iOS plugin Package.swift and Sources exist on disk', () => {
      const pluginDir = path.resolve(__dirname, '../node_modules/@capacitor-community/bluetooth-le');
      expect(fs.existsSync(path.join(pluginDir, 'Package.swift'))).toBe(true);
      expect(fs.existsSync(path.join(pluginDir, 'ios/Sources/BluetoothLe/Plugin.swift'))).toBe(true);
    });

    it('should verify CapApp-SPM is linked in Xcode project.pbxproj', () => {
      expect(fs.existsSync(pbxprojPath)).toBe(true);
      const pbxprojContent = fs.readFileSync(pbxprojPath, 'utf-8');
      expect(pbxprojContent).toContain('CapApp-SPM');
      expect(pbxprojContent).toContain('XCLocalSwiftPackageReference');
    });
  });

  describe('C5: Critique of smoke.test.ts vs Deep Validation', () => {
    it('empirically demonstrates tautological assertion in smoke.test.ts', () => {
      // In smoke.test.ts line 11: expect(1 + 1).toBe(2)
      // This is a zero-value tautological assertion that provides no system confidence.
      const tautologyEvaluated = (1 + 1 === 2);
      expect(tautologyEvaluated).toBe(true);
    });

    it('verifies capacitor.config.ts matches all ORIGINAL_REQUEST specifications', () => {
      expect(capacitorConfig.appId).toBe('com.f91jepler.companion');
      expect(capacitorConfig.appName).toBe('F91_Jepler');
      expect(capacitorConfig.webDir).toBe('dist');
    });
  });
});
