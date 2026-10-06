# Milestone M6 Independent Review & Adversarial Challenge Report

## Review Summary

**Verdict**: **APPROVE**  
**Milestone**: M6 — Sideloadable Android APK Build & Verification  
**Reviewer Role**: Reviewer 2 (Reviewer & Adversarial Critic)  
**Target Artifact**: `Software/companion_app/F91_Jepler-companion-debug.apk` (and `Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk`)  

---

## 1. Observation

### 1.1 Source Code & Native Auto-Driver Selection
- **File**: `Software/companion_app/src/App.tsx` (lines 19-35, 53-56)
  ```tsx
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
      ...
    } = useBleConnection(
      clientOverride,
      !clientOverride && isNative ? { initialClient: new CapacitorBleService() } : undefined
    );
  ```
- **Unit Tests**: `Software/companion_app/tests/uiComponents.test.tsx` (lines 466-486)
  - Explicit test case `defaults to hardware BLE driver when Capacitor.isNativePlatform() is true` spying on `Capacitor.isNativePlatform().mockReturnValue(true)`.
  - Explicit test case `defaults to simulated watch driver when Capacitor.isNativePlatform() is false` spying on `Capacitor.isNativePlatform().mockReturnValue(false)`.

### 1.2 Automated Test & Typecheck Execution
- **Command**: `npm test`
  - Output:
    ```
    Test Files  11 passed (11)
         Tests  327 passed (327)
      Duration  1.41s
    ```
- **Command**: `npm run typecheck` (`tsc --noEmit`)
  - Output: Exited with code 0, 0 type errors.

### 1.3 AndroidManifest.xml & Component Export Attributes
- **File**: `Software/companion_app/android/app/src/main/AndroidManifest.xml` (lines 12-25, 40-49)
  ```xml
  <activity
      android:configChanges="orientation|keyboardHidden|keyboard|screenSize|locale|smallestScreenSize|screenLayout|uiMode|navigation|density"
      android:name=".MainActivity"
      android:label="@string/title_activity_main"
      android:theme="@style/AppTheme.NoActionBarLaunch"
      android:launchMode="singleTask"
      android:exported="true">

      <intent-filter>
          <action android:name="android.intent.action.MAIN" />
          <category android:name="android.intent.category.LAUNCHER" />
      </intent-filter>

  </activity>
  ```
- **`aapt dump xmltree` Inspection**:
  - `activity name="com.f91jepler.companion.MainActivity"` has `android:exported(0x01010010)=(type 0x12)0xffffffff` (`true`).
  - `provider name="androidx.core.content.FileProvider"` has `android:exported(0x01010010)=(type 0x12)0x0` (`false`).
  - `provider name="androidx.startup.InitializationProvider"` has `android:exported(0x01010010)=(type 0x12)0x0` (`false`).
  - `receiver name="androidx.profileinstaller.ProfileInstallReceiver"` has `android:exported="true"` protected by `android:permission="android.permission.DUMP"`.

### 1.4 Android Permissions in APK Manifest
- **Source & Binary XML**:
  - `android.permission.INTERNET`
  - `android.permission.ACCESS_COARSE_LOCATION`
  - `android.permission.ACCESS_FINE_LOCATION`
  - `android.permission.BLUETOOTH` with `android:maxSdkVersion="30"`
  - `android.permission.BLUETOOTH_ADMIN` with `android:maxSdkVersion="30"`
  - `android.permission.BLUETOOTH_SCAN`
  - `android.permission.BLUETOOTH_CONNECT`
  - `android.hardware.bluetooth_le` (`android:required="true"`)
- **Plugin Permission Logic**: `node_modules/@capacitor-community/bluetooth-le/android/src/main/java/com/capacitorjs/community/plugins/bluetoothle/BluetoothLe.kt` (lines 104-128):
  - On SDK >= 31 (Android 12+), if `androidNeverForLocation` is false (default), requests `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, and `ACCESS_FINE_LOCATION`.
  - On SDK < 31 (Android 6-11), requests `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION`, `BLUETOOTH`, and `BLUETOOTH_ADMIN`.

### 1.5 Web Asset Packaging & Offline Readiness
- **File Extraction via `unzip -l`**:
  ```
  assets/capacitor.config.json
  assets/capacitor.plugins.json
  assets/native-bridge.js
  assets/public/assets/index-_qkASCwR.css (22,897 bytes)
  assets/public/assets/index-RPmAMwiC.js  (294,463 bytes)
  assets/public/assets/web-gq334oLb.js    (7,646 bytes)
  assets/public/index.html               (535 bytes)
  ```
- **File Contents**:
  - `assets/public/index.html` references `/assets/index-RPmAMwiC.js` and `/assets/index-_qkASCwR.css`.
  - Zero external CDN URLs (`https://fonts.googleapis.com`, `cdnjs`, etc.) exist in the stylesheet or script bundle.
  - No remote network dependencies are needed to render the UI.

### 1.6 Alignment & Signature Verification
- **Zip Alignment**:
  - Command: `/Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0/zipalign -c -v 4 F91_Jepler-companion-debug.apk`
  - Output: `Verification succesful` (return code 0, 100% 4-byte boundary compliance).
- **Signature Scheme**:
  - Command: `apksigner verify --verbose --print-certs F91_Jepler-companion-debug.apk`
  - Output:
    ```
    Verifies
    Verified using v1 scheme (JAR signing): false
    Verified using v2 scheme (APK Signature Scheme v2): true
    Verified using v3 scheme (APK Signature Scheme v3): false
    Number of signers: 1
    Signer #1 certificate DN: C=US, O=Android, CN=Android Debug
    Signer #1 key algorithm: RSA (2048 bits)
    ```
- **Keystore Validity**:
  - Owner: `C=US, O=Android, CN=Android Debug`
  - Valid from: `Thu Jul 13 14:16:13 CDT 2023` until: `Sat Jul 05 14:16:13 CDT 2053` (valid for 27+ years).

### 1.7 Sideloading Documentation
- In `worker_m6/handoff.md` Section 5:
  - **Method A (ADB)**: Correct flags specified (`-r -t -g`), launch activity target specified, logcat filter command provided.
  - **Method B (Direct transfer)**: Local HTTP server setup, unknown source authorization, and explicit instructions to bypass the Google Play Protect warning on debug keys.

---

## 2. Logic Chain

1. **Native Runtime Driver Defaulting**:
   - In a browser environment, `Capacitor.isNativePlatform()` returns `false`, defaulting the driver to `mock` so unit tests and web previews run in simulation without errors.
   - When running on physical Android hardware inside Capacitor's native shell, `Capacitor.isNativePlatform()` returns `true`, initializing `CapacitorBleService` and defaulting the toggle to `hardware`.
   - The user toggle remains functional, allowing developers to switch between mock simulation and hardware BLE on demand.

2. **Android 12+ Exported Component Security & Compliance**:
   - Android 12 (API 31+) mandates `android:exported` on all components declaring `<intent-filter>`.
   - `MainActivity` has `android:exported="true"`, allowing the Android launcher (`ACTION_MAIN` / `CATEGORY_LAUNCHER`) to launch the app.
   - Internal providers (`FileProvider`, `InitializationProvider`) are explicitly marked `android:exported="false"`, preventing unauthorized cross-app access to local files or internal component states.

3. **Multi-Version Android Permission Compatibility**:
   - **Android 6.0–11 (API 23–30)**:
     - `BLUETOOTH` and `BLUETOOTH_ADMIN` are bounded by `maxSdkVersion="30"`, granting them at install time.
     - `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` are declared and requested at runtime, satisfying Android 6-11 BLE discovery requirements.
   - **Android 12+ (API 31+)**:
     - `BLUETOOTH` and `BLUETOOTH_ADMIN` are ignored by the OS due to `maxSdkVersion="30"`.
     - `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT` are declared and requested at runtime.
     - Because `BLUETOOTH_SCAN` does not declare `neverForLocation`, both Android OS and the `@capacitor-community/bluetooth-le` plugin pair `BLUETOOTH_SCAN` with `ACCESS_FINE_LOCATION`. Both are declared in the manifest and requested during `initialize()`, preventing manifest mismatch crashes.

4. **Offline Capability & Asset Serving**:
   - Capacitor's Android native bridge serves assets from `assets/public/` using `WebViewAssetLoader`.
   - Production bundle files are minified, bundled locally, and have zero CDN dependencies.
   - The application functions completely offline (e.g. in airplane mode).

5. **APK Packaging & Installation Integrity**:
   - `zipalign -c -v 4` verifies all uncompressed resources are aligned to 4-byte boundaries, enabling zero-copy `mmap()` execution by Android's zygote process.
   - `apksigner` verifies APK Signature Scheme v2, preventing tampering and satisfying Android 7.0+ package manager requirements.
   - Debug certificate is valid through 2053, ensuring no installation failures due to expired signing keys.

---

## 3. Adversarial Challenges & Findings

### Finding 1 (Minor / Advisory): Location Permission Prompt on Android 12+
- **What**: On Android 12+ (API 31+), the app prompts users for `ACCESS_FINE_LOCATION` in addition to `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT`.
- **Where**: `Software/companion_app/android/app/src/main/AndroidManifest.xml` (line 45) and `Software/companion_app/src/ble/capacitorBleService.ts` (line 34).
- **Why**: `BLUETOOTH_SCAN` is declared without `android:usesPermissionFlags="neverForLocation"`, and `BleClient.initialize()` is called without `{ androidNeverForLocation: true }`. Consequently, Android OS and the plugin require Location permission. If a user grants "Nearby devices" but denies "Location" permission, BLE initialization fails.
- **Severity**: Minor / Advisory. The current configuration is 100% functional when all permissions are granted and represents the standard conservative default for `@capacitor-community/bluetooth-le`.
- **Suggestion**: For future production releases where users might hesitate to grant location access to a smartwatch app, consider adding `android:usesPermissionFlags="neverForLocation"` to the manifest and initializing with `BleClient.initialize({ androidNeverForLocation: true })`.

### Finding 2 (Informational): No Native ABIs (.so Libraries)
- **What**: The APK contains no `.so` shared libraries in `lib/`.
- **Assessment**: Positive feature. The absence of native C/C++ libraries makes the APK architecture-agnostic (`all-arch`), guaranteeing that the APK installs without `INSTALL_FAILED_NO_MATCHING_ABIS` errors on `arm64-v8a`, `armeabi-v7a`, `x86_64`, and `x86` devices.

---

## 4. Integrity Violation Checks

| Check | Result | Evidence |
|---|---|---|
| Hardcoded test results embedded in source | PASS | None detected; dynamic calculations and real state machines used. |
| Dummy or facade implementations | PASS | Real Capacitor BLE calls wrapping Android's `BluetoothGatt` / `BluetoothLeScanner`. |
| Shortcuts bypassing intended task | PASS | Real APK generated via Gradle AGP from compiled Vite assets. |
| Fabricated verification outputs | PASS | Independently reproduced via terminal execution of `aapt`, `zipalign`, `apksigner`, `keytool`, `vitest`, `tsc`. |
| Self-certifying work | PASS | Verified independently by Reviewer 2. |

---

## 5. Caveats

- **Physical BLE Hardware**: BLE peripheral discovery requires a physical Android device with Bluetooth turned on. Android emulators without hardware Bluetooth passthrough will report BLE unavailable.
- **Google Play Protect Prompt**: Because the APK is signed with a standard Android SDK debug keystore, Google Play Protect will prompt the user during sideloading. Users must tap "More details -> Install anyway". This is standard and expected for debug builds.

---

## 6. Conclusion

The implementation and verification for Milestone M6 (Sideloadable Android APK Build & Verification) satisfy all requirements, interfaces, and quality standards:
- Source code in `App.tsx` properly defaults to `CapacitorBleService` when running natively.
- Full test suite passes 100% (327 tests across 11 suites).
- TypeScript type checking passes without errors.
- `MainActivity` has `android:exported="true"` for Android 12+ compliance.
- APK signature (Scheme v2) and 4-byte zip alignment are fully verified.
- Web assets are completely self-contained and run offline.
- Sideloading instructions are accurate, clear, and actionable.

**Verdict: APPROVE**

---

## 7. Verification Method

To independently reproduce this review from the project root:

```bash
cd Software/companion_app

# 1. Run unit tests and typechecker
npm test
npm run typecheck

# 2. Re-verify Gradle APK compilation
cd android
JAVA_HOME="/Users/jacobloesch/Library/Application Support/minecraft/runtime/java-runtime-delta/mac-os-arm64/java-runtime-delta/jre.bundle/Contents/Home" \
ANDROID_HOME="/Users/jacobloesch/Library/Android/sdk" \
PATH="/Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0:/Users/jacobloesch/Library/Android/sdk/platform-tools:$PATH" \
./gradlew assembleDebug
cd ..

# 3. Verify 4-byte zip alignment
/Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0/zipalign -c -v 4 F91_Jepler-companion-debug.apk

# 4. Verify APK signature
JAVA_HOME="/Users/jacobloesch/Library/Application Support/minecraft/runtime/java-runtime-delta/mac-os-arm64/java-runtime-delta/jre.bundle/Contents/Home" \
PATH="$JAVA_HOME/bin:$PATH" \
/Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0/apksigner verify --verbose --print-certs F91_Jepler-companion-debug.apk

# 5. Verify manifest components and permissions
/Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0/aapt dump badging F91_Jepler-companion-debug.apk
/Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0/aapt dump xmltree F91_Jepler-companion-debug.apk AndroidManifest.xml

# 6. Verify bundled web assets offline integrity
unzip -p F91_Jepler-companion-debug.apk assets/public/index.html | head
```
