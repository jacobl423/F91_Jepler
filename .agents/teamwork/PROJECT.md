# Project: F91_Jepler Smartwatch Cross-Platform Companion Mobile App

## Architecture
The F91_Jepler companion app is a cross-platform mobile application targeting Android and iOS, built with Capacitor 8 + React 19 + TypeScript + Vite 8 + Vitest 5.

### System Diagram
```
+-------------------------------------------------------------------+
|                        React 19 / UI Layer                        |
|   - Discovery View (BLE Scan & List F91_Jepler Devices)           |
|   - Live Connection Status Bar (Badge, Signal, States)            |
|   - Clock Synchronization Panel (Time, TZ, Mode, DST, Sync Btn)   |
|   - Mock / Hardware BLE Driver Switch (Simulation for Preview)    |
+---------------------------------+---------------------------------+
                                  |
                                  v
+-------------------------------------------------------------------+
|                   Reactive State Management                       |
|   - useBleConnection State Machine (6 states)                     |
|   - Device Scanner & Filter (`F91_Jepler` & UUID `0xfa35b2f0...`) |
|   - Clock Sync Controller (Sequential GATT write chaining)        |
+---------------------------------+---------------------------------+
                                  |
                                  v
+-------------------------------------------------------------------+
|                     BleClientInterface (HAL)                      |
+---------------------------------+---------------------------------+
                 |                                  |
                 v                                  v
+----------------------------------+ +------------------------------+
|       CapacitorBleService        | |        MockBleService        |
|  - @capacitor-community/ble      | |  - Virtual F91_Jepler watch  |
|  - CoreBluetooth (iOS SPM)       | |  - Simulated GATT database   |
|  - BluetoothGatt (Android Java)  | |  - Real-time Clock Simulator |
+----------------------------------+ +------------------------------+
```

### Protocol & Characteristic Contracts
- **Clock Service UUID**: `fa35b2f0-7989-11eb-9439-0242ac130002`
- **Clock Time Characteristic UUID**: `fa35b2f1-7989-11eb-9439-0242ac130002`
  - 4-byte `uint32_t` little-endian Unix epoch timestamp in seconds.
  - Strict length = 4 bytes, offset = 0.
- **Clock Timezone Characteristic UUID**: `fa35b2f2-7989-11eb-9439-0242ac130002`
  - 2-byte `int16_t`/`uint16_t` little-endian offset in minutes from UTC (signed two's complement).
  - Strict length = 2 bytes, offset = 0.
- **Clock Time Mode Characteristic UUID**: `fa35b2f3-7989-11eb-9439-0242ac130002`
  - 1-byte `uint8_t`: `0x00` (12-hour), `0x01` (24-hour).
  - Strict length = 1 byte, offset = 0.
- **Clock DST Characteristic UUID**: `fa35b2f4-7989-11eb-9439-0242ac130002`
  - 1-byte `uint8_t`: `0x00` (Standard Time), `0x01` (Daylight Saving Time).
  - Strict length = 1 byte, offset = 0.

### Code Layout
Project root: `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app`
```
Software/companion_app/
├── package.json
├── tsconfig.json
├── vite.config.ts
├── capacitor.config.ts
├── index.html
├── src/
│   ├── main.tsx
│   ├── App.tsx
│   ├── App.css
│   ├── ble/
│   │   ├── bleClientInterface.ts
│   │   ├── capacitorBleService.ts
│   │   ├── mockBleService.ts
│   │   ├── gattConstants.ts
│   │   └── gattSerializer.ts
│   ├── state/
│   │   ├── connectionStateMachine.ts
│   │   └── useBleConnection.ts
│   ├── components/
│   │   ├── DeviceDiscovery.tsx
│   │   ├── ConnectionStatusBadge.tsx
│   │   ├── ClockSyncPanel.tsx
│   │   └── MockWatchPreview.tsx
│   └── types/
│       └── index.ts
├── tests/
│   ├── serialization.test.ts
│   ├── stateMachine.test.ts
│   ├── mockBleService.test.ts
│   ├── uiComponents.test.tsx
│   └── e2eIntegration.test.ts
├── android/            # Native Android Studio Project
│   ├── app/
│   │   └── src/main/AndroidManifest.xml
│   └── build.gradle
└── ios/                # Native iOS Xcode Project (SPM)
    └── App/
        ├── App/Info.plist
        └── Package.swift
```

---

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | Mobile Project Architecture & Tooling | Clean Capacitor 8 + React 19 + TypeScript + Vite project in Software/companion_app targeting Android and iOS | M1 | ORIGINAL_REQUEST §R1 |
| 2 | Native Android Configuration | Android platform setup with Bluetooth permissions (BLUETOOTH_SCAN, BLUETOOTH_CONNECT, ACCESS_FINE_LOCATION) | M1 | ORIGINAL_REQUEST §R1 |
| 3 | Native iOS Configuration | iOS platform setup with NSBluetoothAlwaysUsageDescription & SPM | M1 | ORIGINAL_REQUEST §R1 |
| 4 | GATT Serializer Engine | Byte serializer for Time (4B LE), TZ (2B LE), Mode (1B), DST (1B) conforming to Zephyr clock_service.c | M2 | ORIGINAL_REQUEST §R3 |
| 5 | BleClientInterface Abstraction | Hardware-independent interface for scanning, connecting, disconnecting, and GATT writes | M2 | ORIGINAL_REQUEST §R2 |
| 6 | CapacitorBleService Implementation | Hardware BLE driver wrapping @capacitor-community/bluetooth-le | M2 | ORIGINAL_REQUEST §R2 |
| 7 | MockBleService Simulation | In-memory simulated F91_Jepler watch with realistic advertising, GATT DB, and error handling | M2 | ORIGINAL_REQUEST §R5 |
| 8 | Connection State Machine | State manager handling disconnected, scanning, connecting, connected, syncing, and error states | M3 | ORIGINAL_REQUEST §R2 |
| 9 | Sequential Time Sync Service | Chained sequential GATT write execution ensuring write acknowledgment between characteristics | M3 | ORIGINAL_REQUEST §R3 |
| 10 | Companion User Interface | Mobile UI with scan triggers, peripheral selection list, live status badge, and sync button | M4 | ORIGINAL_REQUEST §R4 |
| 11 | Visual Feedback & Mode Switch | Visual feedback on sync success/timestamp and toggle between hardware BLE & simulated watch | M4 | ORIGINAL_REQUEST §R4 |
| 12 | Automated Verification & Testing Suite | 4-tier test suite validating serialization, state machine, mock BLE, and UI components | M5 | ORIGINAL_REQUEST §R5 |
| 13 | Native Platform Hardware BLE Default | In native Android app (Capacitor.isNativePlatform()), default BLE driver to hardware | M6 | Survey Findings |
| 14 | Web Asset Production Bundle | Execute npm run build to generate dist/ production assets | M6 | ORIGINAL_REQUEST §R1 |
| 15 | Capacitor Android Native Sync | Execute npx cap sync android to sync web assets and BLE plugin into Android project | M6 | ORIGINAL_REQUEST §R1 |
| 16 | Android Debug APK Compilation | Compile signed debug APK via ./gradlew assembleDebug using Java 21 and Android SDK | M6 | User Request (2026-10-05T05:03:02Z) |
| 17 | APK Artifact Verification Suite | Validate APK via file, unzip, aapt badging/permissions, zipalign, apksigner | M6 | Survey Findings |
| 18 | Sideloading Documentation & Guidelines | Comprehensive instructions for sideloading via adb and direct file transfer | M6 | User Request |

---

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Project Setup & Native Mobile Architecture | Scaffold Software/companion_app, setup Vite + React + TS, add Android & iOS platforms with BLE permissions | none | DONE |
| M2 | BLE Engine & GATT Serialization Core | Implement GATT constants, binary serializers, BleClientInterface, CapacitorBleService, and MockBleService | M1 | DONE |
| M3 | State Machine & Sequential Sync Service | Implement ConnectionStateMachine and sync pipeline with timeout/disconnect guards | M2 | DONE |
| M4 | User Interface & Visual Synchronization Panel | Build React components, responsive mobile layout, status indicators, discovery list, and sync controls | M3 | DONE |
| M5 | Final Verification & Victory Audit | Run 100% automated tests, build/bundle validation, adversarial edge cases, and audit gating | M4, E2E | DONE |
| M6 | Sideloadable Android APK Build & Verification | Clean web build, Capacitor sync, Gradle assembleDebug, artifact verification, sideloading instructions | M1-M5 | DONE |

---

## Interface Contracts

### BleClientInterface
```typescript
export interface BleDevice {
  deviceId: string;
  name: string;
  rssi?: number;
}

export interface BleClientInterface {
  initialize(): Promise<void>;
  startScan(onDeviceFound: (device: BleDevice) => void): Promise<void>;
  stopScan(): Promise<void>;
  connect(deviceId: string): Promise<void>;
  disconnect(deviceId: string): Promise<void>;
  writeCharacteristic(
    deviceId: string,
    serviceUuid: string,
    characteristicUuid: string,
    data: Uint8Array
  ): Promise<void>;
  isConnected(deviceId: string): Promise<boolean>;
}
```

### GattSerializer
```typescript
export interface ClockSyncData {
  timestamp: number; // Unix epoch seconds
  timezoneOffsetMinutes: number; // Signed minutes from UTC
  is24Hour: boolean;
  isDst: boolean;
}

export interface SerializedClockPayload {
  timeBytes: Uint8Array; // 4 bytes LE uint32
  timezoneBytes: Uint8Array; // 2 bytes LE uint16
  timeModeBytes: Uint8Array; // 1 byte uint8
  dstBytes: Uint8Array; // 1 byte uint8
}
```
