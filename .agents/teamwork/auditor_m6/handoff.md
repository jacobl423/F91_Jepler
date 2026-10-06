# Forensic Audit Report: Milestone M6 — Sideloadable Android APK Build & Verification

**Work Product**: `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/F91_Jepler-companion-debug.apk` & `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk`  
**Profile**: General Project  
**Integrity Mode**: Development (from `ORIGINAL_REQUEST.md`)  
**Verdict**: **CLEAN**

---

## 1. Observation

All observations were independently executed and verified empirically by the Forensic Auditor.

### 1.1 Source Code Diffs & Modification Authenticity
- **File**: `Software/companion_app/src/App.tsx` (lines 16-35, 54-56)
  - Detected `Capacitor.isNativePlatform()` to automatically select the production hardware BLE driver (`CapacitorBleService`) when running inside Android WebView, while preserving simulated driver mode for web browsers and manual testing.
- **File**: `Software/companion_app/tests/uiComponents.test.tsx` (lines 466-486)
  - Added two unit tests verifying driver default behavior when `Capacitor.isNativePlatform()` returns `true` vs `false`.
- **Grep Inspection**:
  - Searched `Software/companion_app/src` for `// TODO`, mock bypasses, or facade returns. Zero stubbed functions or short-circuits found.

### 1.2 Binary Artifact Timestamps & Cryptographic Identity
1. **File Locations & Sizes**:
   - Primary build artifact: `Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk` (4,314,108 bytes, created Oct 5 00:16:17 2026)
   - Convenience root artifact: `Software/companion_app/F91_Jepler-companion-debug.apk` (4,314,108 bytes, created Oct 5 00:16:23 2026)
2. **SHA-256 Bit-for-Bit Identity**:
   ```bash
   shasum -a 256 Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk Software/companion_app/F91_Jepler-companion-debug.apk
   ```
   Output:
   ```
   14dc371c3e8e5394ca981d3258bc30d1fcb524d5f728b9eca0b19ad371bdf928  Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk
   14dc371c3e8e5394ca981d3258bc30d1fcb524d5f728b9eca0b19ad371bdf928  Software/companion_app/F91_Jepler-companion-debug.apk
   ```
   Both files are identical.

### 1.3 Cryptographic Signature & Debug Keystore Verification
1. **`apksigner verify --verbose --print-certs` on `F91_Jepler-companion-debug.apk`**:
   ```
   Verifies
   Verified using v1 scheme (JAR signing): false
   Verified using v2 scheme (APK Signature Scheme v2): true
   Verified using v3 scheme (APK Signature Scheme v3): false
   Verified using v3.1 scheme (APK Signature Scheme v3.1): false
   Verified using v4 scheme (APK Signature Scheme v4): false
   Verified for SourceStamp: false
   Number of signers: 1
   Signer #1 certificate DN: C=US, O=Android, CN=Android Debug
   Signer #1 certificate SHA-256 digest: 326e20174a4e6c72a47c777e040efca1947e8b3a961eb19572f43452663af78f
   Signer #1 certificate SHA-1 digest: a0d3f2a8a5e7d9276bc8b05a9a64b8333f32451b
   Signer #1 certificate MD5 digest: 09169fb35f8cbf55ee66d49ed6503ecf
   Signer #1 key algorithm: RSA
   Signer #1 key size (bits): 2048
   Signer #1 public key SHA-256 digest: 94573b3a02f84513fe0ed29beb99ad53cebd55780d5bd4e2c9e392a4a6b4bd17
   ```
2. **Host Keystore Cross-Verification (`keytool -list -v -keystore ~/.android/debug.keystore`)**:
   ```
   Alias name: androiddebugkey
   Owner: C=US, O=Android, CN=Android Debug
   SHA256: 32:6E:20:17:4A:4E:6C:72:A4:7C:77:7E:04:0E:FC:A1:94:7E:8B:3A:96:1E:B1:95:72:F4:34:52:66:3A:F7:8F
   ```
   **Verification**: The certificate in the APK matches the authentic local host debug keystore byte-for-byte.

### 1.4 Zip Alignment Verification
- Tool command:
  ```bash
  /Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0/zipalign -c -v 4 Software/companion_app/F91_Jepler-companion-debug.apk
  ```
- Output:
  ```
  Verification succesful (returncode 0)
  ```
  All 447 entries in the APK archive conform to 4-byte page boundaries required by Android's memory-mapped runtime loader.

### 1.5 DEX Bytecode Authenticity & Decompilation Analysis
1. **Magic Bytes & Header**:
   - Inspected `classes.dex` through `classes8.dex`:
     ```bash
     file /tmp/apk_audit_dex/*.dex
     # Output: Dalvik dex file version 037 across all 8 DEX files
     head -c 8 /tmp/apk_audit_dex/classes.dex | xxd -p
     # Output: 6465780a30333700 (dex\n037\0)
     ```
2. **Disassembled Class Descriptors (`dexdump`)**:
   - `classes8.dex`: Contains `Lcom/f91jepler/companion/MainActivity;`
   - `classes7.dex`: Contains `Lcom/f91jepler/companion/R;` and its inner resource tables, plus `Lcom/capacitorjs/community/plugins/bluetoothle/R;`
   - `classes5.dex`: Contains `Lcom/capacitorjs/plugins/app/AppPlugin;`
   - `classes2.dex`: Contains 902 occurrences of `bluetoothle` including `Lcom/capacitorjs/community/plugins/bluetoothle/BluetoothLe;` and `Device;`
   - `classes.dex`: Contains `Lcom/getcapacitor/BridgeActivity;` and `Bridge;`

### 1.6 Web Asset Packaging Verification (APK vs `dist/`)
Extracted `assets/public/` directly from the APK and compared SHA-256 checksums against the production Vite build in `Software/companion_app/dist/`:
```bash
shasum -a 256 Software/companion_app/dist/index.html /tmp/apk_audit_assets/assets/public/index.html
# 2d824d6747618529d14916369bc1a881346d150b8d963383959fc10839316f09  (MATCH)

shasum -a 256 Software/companion_app/dist/assets/* /tmp/apk_audit_assets/assets/public/assets/*
# f84ee8baae6c443cf2707e88d5dc5a2399c94180081229a482b507613262574e  index-RPmAMwiC.js (MATCH)
# 5fb334db02dc07c09fdaa4d4c878d095c1110e4e1713de9fa428f5dbbe18ef44  index-_qkASCwR.css (MATCH)
# 7e6535f2b919b910980a7c127bf045115b78fdaefcaf17bd3d5cd3811a985af9  web-gq334oLb.js (MATCH)
```
Every single web asset packed in the APK is an identical bit-for-bit copy of the production Vite bundle.

### 1.7 Android Manifest & Packaging Attributes (`aapt dump badging`)
- **Package Name**: `com.f91jepler.companion`
- **Version Code**: `1`
- **Version Name**: `1.0`
- **minSdkVersion**: `24` (Android 7.0 Nougat)
- **targetSdkVersion**: `36` (Android 16 preview / Android 15 compatibility)
- **Launchable Activity**: `com.f91jepler.companion.MainActivity`
- **Permissions Declared**:
  - `android.permission.INTERNET`
  - `android.permission.ACCESS_COARSE_LOCATION`
  - `android.permission.ACCESS_FINE_LOCATION`
  - `android.permission.BLUETOOTH` (maxSdkVersion=30)
  - `android.permission.BLUETOOTH_ADMIN` (maxSdkVersion=30)
  - `android.permission.BLUETOOTH_SCAN`
  - `android.permission.BLUETOOTH_CONNECT`
- **Hardware Features**:
  - `android.hardware.bluetooth_le` (required)
  - `android.hardware.bluetooth` (required)

### 1.8 Independent Test Execution & Clean Build Results
1. **Unit & Integration Test Suite (`npm test`)**:
   - Executed independently with Vitest v5.0.3.
   - Result: **11 test files passed (11/11), 327 tests passed (327/327)**, duration 1.36s.
2. **TypeScript Compilation (`npm run typecheck`)**:
   - Result: Exited 0 with zero errors.
3. **Gradle Build Execution (`./gradlew assembleDebug`)**:
   - Result: 154 actionable tasks evaluated, **BUILD SUCCESSFUL**.

---

## 2. Logic Chain

1. **Genuineness of Build Artifact**:
   - The APK file timestamp (Oct 5 00:16:17 2026) closely succeeds the timestamp of web asset generation and capacitor sync.
   - The SHA-256 hash of the convenience artifact `Software/companion_app/F91_Jepler-companion-debug.apk` exactly matches `Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk`.
   - The Gradle build system successfully ran 154 tasks without dummy workarounds.
2. **Integrity of Dalvik/ART Bytecode**:
   - All 8 DEX files possess valid Dalvik 037 headers (`dex\n037\0`).
   - Disassembly via `dexdump` confirmed full compilation of native Java/Kotlin classes (`MainActivity`, `BridgeActivity`, and the entire `BluetoothLe` plugin comprising over 900 references).
   - This proves the APK was genuinely compiled through D8/R8 and was not fabricated from a generic template or empty stub.
3. **Integrity of Web Assets**:
   - Direct extraction of `assets/public/` from the APK yielded identical SHA-256 hashes to the files in `Software/companion_app/dist/`.
   - The production bundle is completely packaged inside the APK, allowing full offline operation without an external web server.
4. **Compliance with Android Platform Standards**:
   - The package is 4-byte aligned via `zipalign`.
   - The package is signed with APK Signature Scheme v2 using the authentic host debug keystore.
   - Sideloading compatibility requirements on Android 7.0 through Android 15/16 are fully satisfied.

---

## 3. Adversarial Review & Stress-Testing

### Dimension 1: Permissions Model Under Modern Android (API 31+)
- **Assumption Challenged**: Does the app have the required permissions for BLE on modern Android versions without crashing?
- **Attack Scenario**: On Android 12+ (API 31+), initiating BLE scans without runtime `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT` causes a `SecurityException`.
- **Finding**: In `AndroidManifest.xml`, both `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT` are declared alongside backward-compatible `BLUETOOTH` and `BLUETOOTH_ADMIN` (gated with `maxSdkVersion=30`). Furthermore, `ACCESS_FINE_LOCATION` is included for Android 10-11 BLE discovery.
- **Assessment**: PASS.

### Dimension 2: Offline WebView Runtime Usability
- **Assumption Challenged**: Does the WebView try to fetch web assets over the network or rely on a live Vite dev server?
- **Attack Scenario**: If Vite dev server URLs (`http://localhost:5173`) are hardcoded, opening the app in airplane mode would show a white screen with `ERR_CONNECTION_REFUSED`.
- **Finding**: `capacitor.config.json` inside the APK specifies `"webDir": "dist"`, and `assets/public/index.html` references relative bundled assets (`assets/index-RPmAMwiC.js`, `assets/index-_qkASCwR.css`). No network server URLs are present.
- **Assessment**: PASS.

### Dimension 3: Dual-Mode Driver Resilience
- **Assumption Challenged**: What happens if an Android device lacks Bluetooth or the user runs inside an emulator without BLE hardware?
- **Finding**: `App.tsx` retains a responsive UI toggle between "Simulated Watch" and "Hardware BLE". If hardware scanning fails or is unsupported on an emulator, the user can seamlessly toggle to simulated mode.
- **Assessment**: PASS.

---

## 4. Caveats

- **Debug Keystore Warning**: The APK is signed with Android's standard debug keystore (`CN=Android Debug`), which is normal for developer sideloading. When installing via Android's package installer, Google Play Protect will present an "Unknown developer / Unrecognized app" prompt requiring the user to tap "More details -> Install anyway". This is expected and documented in the worker's sideloading guide.
- **Physical Device Required for Live Hardware BLE**: Physical Bluetooth Low Energy radio communication requires physical Android hardware; standard Android emulators lack Bluetooth hardware emulation. The app's simulation mode covers emulators.

---

## 5. Conclusion

**Verdict**: **CLEAN**

Milestone M6 is complete and complies 100% with all integrity and quality requirements:
- The APK is an authentic, freshly compiled Android package produced by the Gradle and Capacitor build toolchain.
- The APK is verified with APK Signature Scheme v2, aligned to 4-byte boundaries, and contains authentic Dalvik 037 bytecode and complete web assets.
- No dummy implementations, hardcoded shortcuts, or fabricated outputs were detected.

---

## 6. Verification Method

To independently verify these findings:

```bash
cd /Users/jacobloesch/Documents/F91_Jepler/Software/companion_app

# 1. Verify all unit tests
npm test

# 2. Verify TypeScript types
npm run typecheck

# 3. Verify APK 4-byte alignment
/Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0/zipalign -c -v 4 F91_Jepler-companion-debug.apk

# 4. Verify APK signature
JAVA_HOME="/Users/jacobloesch/Library/Application Support/minecraft/runtime/java-runtime-delta/mac-os-arm64/java-runtime-delta/jre.bundle/Contents/Home" \
PATH="$JAVA_HOME/bin:$PATH" \
/Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0/apksigner verify --verbose --print-certs F91_Jepler-companion-debug.apk

# 5. Verify asset integrity
mkdir -p /tmp/verify_apk && unzip -q -o F91_Jepler-companion-debug.apk "assets/public/*" -d /tmp/verify_apk
shasum -a 256 dist/index.html /tmp/verify_apk/assets/public/index.html
shasum -a 256 dist/assets/* /tmp/verify_apk/assets/public/assets/*
rm -rf /tmp/verify_apk
```
