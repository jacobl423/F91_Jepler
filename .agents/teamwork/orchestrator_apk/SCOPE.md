# Scope: Sideloadable Android APK Generation & Verification

## Architecture & Toolchain
- **Framework**: Capacitor 8 + React 19 + TypeScript + Vite 8
- **Native Android Platform**: Android Studio / Gradle wrapper 8.14.3 + AGP 8.13.0
- **Java Runtime**: OpenJDK 21 LTS (`/Users/jacobloesch/Library/Application Support/minecraft/runtime/java-runtime-delta/mac-os-arm64/java-runtime-delta/jre.bundle/Contents/Home` or Homebrew `openjdk@21`)
- **Android SDK**: `/Users/jacobloesch/Library/Android/sdk` (Platform 36, Build-Tools 35.0.0, Platform-Tools with `adb`)
- **Signing**: Android Debug Keystore (`~/.android/debug.keystore`), APK Signature Scheme v2

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 13 | Native Platform Hardware BLE Default | In native Android app (`Capacitor.isNativePlatform()`), default BLE driver to `hardware` while retaining user toggle | M6 | Survey Findings |
| 14 | Web Asset Production Bundle | Execute `npm run build` to generate `dist/` production assets | M6 | ORIGINAL_REQUEST §R1 |
| 15 | Capacitor Android Native Sync | Execute `npx cap sync android` to sync web assets and `@capacitor-community/bluetooth-le` into Android project | M6 | ORIGINAL_REQUEST §R1 |
| 16 | Android Debug APK Compilation | Compile signed debug APK via `./gradlew assembleDebug` using Java 21 and Android SDK | M6 | User Request (2026-10-05T05:03:02Z) |
| 17 | APK Artifact Verification Suite | Validate APK via `file`, `unzip -l`, `aapt dump badging`, `aapt dump permissions`, `zipalign`, and `apksigner` | M6 | Survey Findings |
| 18 | Sideloading Documentation & Guidelines | Comprehensive instructions for sideloading via `adb` and direct file transfer (Play Protect handling) | M6 | User Request |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M6 | Sideloadable Android APK Build & Verification | Clean web build, Capacitor sync, Gradle assembleDebug, artifact verification, sideloading instructions | M1-M5 | DONE |

## Interface Contracts
- **Artifact Path**: `Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk`
- **Application ID**: `com.f91jepler.companion`
- **Main Activity**: `com.f91jepler.companion.MainActivity`
- **Permissions**: `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `INTERNET`
- **Signature**: Android Debug Keystore (Scheme v2)
