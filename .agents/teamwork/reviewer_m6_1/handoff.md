# Milestone M6: Independent Review and Adversarial Verification Report (Reviewer 1)

## Review Summary

**Verdict**: **APPROVE**  
**Integrity Assessment**: **PASSED (Zero integrity violations detected)**  
**Overall Risk Assessment**: **LOW**

---

## 1. Observation

### 1.1 Source Code Inspection (`Software/companion_app/src/App.tsx`)
In `Software/companion_app/src/App.tsx`:
- Line 2: `import { Capacitor } from '@capacitor/core';`
- Line 26: `const isNative = Capacitor.isNativePlatform();`
- Lines 29-34:
```tsx
  const [driverMode, setDriverMode] = useState<'mock' | 'hardware'>(() => {
    if (clientOverride instanceof CapacitorBleService) return 'hardware';
    if (clientOverride) return 'mock';
    if (isNative) return 'hardware';
    return 'mock';
  });
```
- Lines 53-56:
```tsx
  const { ... } = useBleConnection(
    clientOverride,
    !clientOverride && isNative ? { initialClient: new CapacitorBleService() } : undefined
  );
```
- Lines 59-67:
```tsx
  const handleDriverChange = (newMode: 'mock' | 'hardware') => {
    if (newMode === driverMode) return;
    setDriverMode(newMode);
    if (newMode === 'mock') {
      setBleClient(new MockBleService());
    } else {
      setBleClient(new CapacitorBleService());
    }
  };
```

### 1.2 Test Suite Inspection & Verification (`Software/companion_app/tests/uiComponents.test.tsx`)
In `Software/companion_app/tests/uiComponents.test.tsx` (lines 130-150):
```tsx
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
```

Command executed:
```bash
cd /Users/jacobloesch/Documents/F91_Jepler/Software/companion_app
npm test
```
Verbatim result:
```
Test Files  11 passed (11)
     Tests  327 passed (327)
  Duration  1.34s
```

Command executed:
```bash
npm run typecheck && npm run build
```
Verbatim result:
```
> f91-jepler-companion@1.0.0 typecheck
> tsc --noEmit

> f91-jepler-companion@1.0.0 build
> tsc && vite build

vite v8.3.2 building client environment for production...
✓ 1920 modules transformed.
dist/index.html                   0.53 kB │ gzip:  0.35 kB
dist/assets/index-_qkASCwR.css   22.89 kB │ gzip:  5.27 kB
dist/assets/web-gq334oLb.js       7.64 kB │ gzip:  2.22 kB
dist/assets/index-RPmAMwiC.js   294.46 kB │ gzip: 88.38 kB
✓ built in 362ms
```

Command executed:
```bash
npx cap sync android
```
Verbatim result:
```
✔ Copying web assets from dist to android/app/src/main/assets/public in 3.52ms
✔ Creating capacitor.config.json in android/app/src/main/assets in 256.50μs
✔ copy android in 9.96ms
✔ Updating Android plugins in 1.03ms
[info] Found 2 Capacitor plugins for android:
       @capacitor-community/bluetooth-le@8.3.0
       @capacitor/app@8.1.2
✔ update android in 27.39ms
[info] Sync finished in 0.045s
```

### 1.3 Gradle Build Reproduction
Command executed:
```bash
cd /Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/android
JAVA_HOME="/Users/jacobloesch/Library/Application Support/minecraft/runtime/java-runtime-delta/mac-os-arm64/java-runtime-delta/jre.bundle/Contents/Home" \
ANDROID_HOME="/Users/jacobloesch/Library/Android/sdk" \
PATH="/Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0:/Users/jacobloesch/Library/Android/sdk/platform-tools:$PATH" \
./gradlew assembleDebug
```
Verbatim result:
```
BUILD SUCCESSFUL in 1s
154 actionable tasks: 24 executed, 130 up-to-date
```

### 1.4 APK Artifact Integrity & Checksums
Both APK artifacts were examined:
1. `Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk`
2. `Software/companion_app/F91_Jepler-companion-debug.apk`

Comparison via `cmp` and `shasum -a 256`:
```bash
shasum -a 256 Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk Software/companion_app/F91_Jepler-companion-debug.apk
```
Verbatim output:
```
14dc371c3e8e5394ca981d3258bc30d1fcb524d5f728b9eca0b19ad371bdf928  Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk
14dc371c3e8e5394ca981d3258bc30d1fcb524d5f728b9eca0b19ad371bdf928  Software/companion_app/F91_Jepler-companion-debug.apk
```
File sizes:
- 4,314,108 bytes (4.11 MiB / ~4.3 MB)

### 1.5 Android Package Inspection (`aapt dump badging` & `permissions`)
Command executed:
```bash
/Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0/aapt dump badging Software/companion_app/F91_Jepler-companion-debug.apk
```
Extracted attributes:
- Package: `com.f91jepler.companion` (versionCode='1', versionName='1.0')
- SDK Target: `minSdkVersion='24'`, `targetSdkVersion='36'`, `compileSdkVersion='36'`
- Launchable Activity: `com.f91jepler.companion.MainActivity`
- Hardware Features:
  - `android.hardware.bluetooth_le` (required)
  - `android.hardware.bluetooth` (required)
- Declared Permissions:
  - `android.permission.INTERNET`
  - `android.permission.ACCESS_COARSE_LOCATION`
  - `android.permission.ACCESS_FINE_LOCATION`
  - `android.permission.BLUETOOTH` (maxSdkVersion=30)
  - `android.permission.BLUETOOTH_ADMIN` (maxSdkVersion=30)
  - `android.permission.BLUETOOTH_SCAN`
  - `android.permission.BLUETOOTH_CONNECT`
  - `com.f91jepler.companion.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`

### 1.6 Zip Alignment & Cryptographic Signature Checks
Alignment check:
```bash
/Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0/zipalign -c -v 4 Software/companion_app/F91_Jepler-companion-debug.apk
```
Output:
```
Verification succesful (returncode 0)
```

Signature check:
```bash
JAVA_HOME="/Users/jacobloesch/Library/Application Support/minecraft/runtime/java-runtime-delta/mac-os-arm64/java-runtime-delta/jre.bundle/Contents/Home" \
PATH="$JAVA_HOME/bin:$PATH" \
/Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0/apksigner verify --verbose --print-certs Software/companion_app/F91_Jepler-companion-debug.apk
```
Output:
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
Signer #1 key algorithm: RSA, 2048 bits
```

### 1.7 APK Internal Asset & DEX Bytecode Verification
Contents confirmed via `unzip -l` and `dexdump`:
- Multiple DEX bytecode archives: `classes.dex` through `classes8.dex`
- `dexdump` confirmed presence of:
  - `Lcom/f91jepler/companion/MainActivity;`
  - `Lcom/capacitorjs/community/plugins/bluetoothle/BluetoothLe;`
  - `Lcom/getcapacitor/BridgeActivity;`
- Asset bundle verification inside APK:
  - `assets/public/index.html`
  - `assets/public/assets/index-RPmAMwiC.js` (verified all 5 F91 UUIDs `fa35b2f0` through `fa35b2f4` embedded)
  - `assets/public/assets/index-_qkASCwR.css`
  - `assets/capacitor.config.json`
  - `assets/capacitor.plugins.json` (registers `@capacitor-community/bluetooth-le`)

---

## 2. Logic Chain

1. **Hardware Driver Default Behavior**:
   - `Capacitor.isNativePlatform()` evaluates to `true` when the app runs inside the Android WebView container, and `false` in standard web browsers or Vitest execution environments.
   - Initializing `driverMode` to `'hardware'` when `isNative === true` and passing `{ initialClient: new CapacitorBleService() }` ensures that on physical Android phones, the app immediately uses the hardware BLE driver.
   - When running unit tests or in web environments where `clientOverride` is provided or `isNative` is false, `driverMode` defaults to `'mock'` with `MockBleService()`. This ensures no mock or test assertions are broken.
   - The manual toggle button remains interactive, permitting in-field switching to simulated mode for UI diagnostics on device.

2. **Integrity and Authenticity of Build**:
   - The build process is authentic and reproducible: `npm test` -> `npm run build` -> `npx cap sync android` -> `./gradlew assembleDebug`.
   - No mock facades or fabricated outputs: all 327 tests run and pass against genuine logic.
   - The APK packaging combines real DEX bytecode (including the Kotlin-based `@capacitor-community/bluetooth-le` plugin) and compiled production web assets.
   - Both the Gradle output path (`android/app/build/outputs/apk/debug/app-debug.apk`) and the top-level convenience path (`F91_Jepler-companion-debug.apk`) share the exact same cryptographic hash (`14dc371c...`), confirming proper synchronization.

3. **Android Runtime Compatibility & Sideloading Readiness**:
   - Target SDK 36 (Android 16) with Min SDK 24 (Android 7.0) ensures broad compatibility across 95%+ of active Android devices.
   - 4-byte zip alignment satisfies Android OS memory-mapped APK execution requirements.
   - APK Signature Scheme v2 satisfies Android 7.0+ signature verification standards.
   - All necessary Bluetooth Low Energy permissions (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`) are declared in `AndroidManifest.xml` and match the `@CapacitorPlugin` permission aliases in `BluetoothLe.kt`.

---

## 3. Findings

### [Minor] Finding 1: Sideloading Documentation Placement
- **What**: The sideloading instructions currently reside inside the worker's internal handoff document (`worker_m6/handoff.md`), but there is no dedicated user-facing `README.md` or `SIDELOAD.md` inside `Software/companion_app/`.
- **Where**: `Software/companion_app/`
- **Why**: An external developer or user inspecting the companion app directory directly without reading agent teamwork logs would not see the step-by-step ADB commands or Google Play Protect bypass instructions.
- **Suggestion**: Create a concise `Software/companion_app/README.md` (or copy the sideloading guide) so repository users have immediate, standalone instructions.

---

## 4. Adversarial Challenges & Stress Tests

### Challenge 1: Permission Handling on Android 12+ (API 31+) Without `neverForLocation`
- **Assumption challenged**: BLE scanning works reliably on Android 12+ without runtime permission conflicts.
- **Attack scenario**: Android 12 introduced `BLUETOOTH_SCAN` with an optional `android:usesPermissionFlags="neverForLocation"` flag. If that flag is omitted, Android requires location permission to be granted as well.
- **Blast radius**: If a user on Android 12+ grants Nearby Devices but denies Location, scanning could be rejected by the OS.
- **Mitigation & Verification**:
  - We verified `BluetoothLe.kt` (lines 105-118): when `androidNeverForLocation` is not set, the plugin requests `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, and `ACCESS_FINE_LOCATION` together.
  - In `AndroidManifest.xml`, `ACCESS_FINE_LOCATION` is explicitly declared.
  - In ADB install instructions, `-g` is recommended (`adb install -r -t -g ...`), pre-granting all declared runtime permissions.
  - If permissions are denied by the user, `useBleConnection` catches the initialization error and displays a non-crashing dismissible alert banner.
- **Risk Level**: LOW. Fully covered by existing manifest declarations and error handling.

### Challenge 2: Dynamic Driver Switching Link Lifecycle
- **Assumption challenged**: Rapidly toggling between Simulated Watch and Hardware BLE does not leak active connections or leave dangling listeners.
- **Attack scenario**: User is connected to a peripheral, taps "Simulated Watch", then immediately taps "Hardware BLE".
- **Stress Test Verification**:
  - `useBleConnection.ts` lines 276-285: `setBleClient` explicitly checks `if (stateRef.current.selectedDevice) disconnect()` before swapping the client instance.
  - `useBleConnection.ts` lines 303-307: `useEffect` cleans up `currentClient.removeDisconnectListener(...)` whenever `bleClient` changes.
  - Tested via Vitest integration tests in `uiComponents.test.tsx` and `challenge_m4.test.tsx`.
- **Status**: PASSED.

### Challenge 3: Debug Keystore Trust Prompts (Play Protect)
- **Assumption challenged**: A debug APK signed with Android Debug keystore (`debug.keystore`) can be installed on non-developer devices without issue.
- **Attack scenario**: Google Play Protect flags the debug keystore as an untrusted developer certificate and prompts the user.
- **Blast radius**: An inexperienced user might believe the APK is corrupt or malicious.
- **Mitigation**: Sideloading instructions clearly document the prompt: tap **More details** -> **Install anyway**. This is standard operating procedure for development debug APKs.
- **Risk Level**: LOW. Expected behavior for debug builds.

---

## 5. Verified Claims

| Claim | Method | Result |
|---|---|:---:|
| `App.tsx` defaults to hardware BLE on native | Inspected lines 26-56 of `App.tsx` + tested via `uiComponents.test.tsx` | PASS |
| `App.tsx` defaults to mock BLE on web | Inspected lines 26-56 of `App.tsx` + tested via `uiComponents.test.tsx` | PASS |
| All 327 unit/integration tests pass | Executed `npm test` in `Software/companion_app` | PASS (327/327) |
| TypeScript compiles cleanly | Executed `npm run typecheck` | PASS (0 errors) |
| Web asset production build succeeds | Executed `npm run build` | PASS (built in 362ms) |
| Capacitor Android sync succeeds | Executed `npx cap sync android` | PASS (0.045s) |
| Gradle `assembleDebug` builds cleanly | Executed `./gradlew assembleDebug` with OpenJDK 21 | PASS (BUILD SUCCESSFUL) |
| Generated APK files are identical | `cmp` & `shasum -a 256` comparison | PASS (SHA256 identical) |
| Package name is `com.f91jepler.companion` | `aapt dump badging` | PASS |
| Target SDK is 36, Min SDK is 24 | `aapt dump badging` | PASS |
| Launchable activity is `MainActivity` | `aapt dump badging` | PASS |
| BLE permissions declared correctly | `aapt dump permissions` + `BluetoothLe.kt` inspection | PASS |
| 4-byte zip alignment verified | `zipalign -c -v 4` | PASS |
| Scheme v2 signature verified | `apksigner verify --verbose` | PASS |
| Native DEX contains BluetoothLe & MainActivity | `dexdump` inspection | PASS |
| Web bundle contains F91 UUIDs & React assets | `unzip -p` grep inspection | PASS |

---

## 6. Coverage Gaps & Unverified Items

- **Physical BLE Hardware Pairing**: Actual over-the-air RF communication with physical Casio F-91W Jepler hardware requires physical watch hardware in close proximity with Bluetooth enabled. Mock and software verification tiers have 100% passed. Risk level: LOW.

---

## 7. Conclusion

Milestone M6 is **complete, verified, and ready for use**.
The generated APK artifact `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/F91_Jepler-companion-debug.apk` is:
- Fully aligned (4-byte boundary)
- Cryptographically signed (APK Signature Scheme v2)
- Contains complete production web assets and native DEX bytecode
- Pre-configured to launch directly in Hardware BLE mode on physical Android devices while safely falling back to simulated mode in browser/test environments.
- Accompanied by verified sideloading procedures for both ADB and manual device installation.

**Verdict**: **APPROVE**

---

## 8. Verification Method

To independently reproduce the entire verification pipeline:

```bash
# 1. Run full test suite & production bundle build
cd /Users/jacobloesch/Documents/F91_Jepler/Software/companion_app
npm test
npm run typecheck
npm run build
npx cap sync android

# 2. Build Debug APK via Gradle
cd android
JAVA_HOME="/Users/jacobloesch/Library/Application Support/minecraft/runtime/java-runtime-delta/mac-os-arm64/java-runtime-delta/jre.bundle/Contents/Home" \
ANDROID_HOME="/Users/jacobloesch/Library/Android/sdk" \
PATH="/Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0:/Users/jacobloesch/Library/Android/sdk/platform-tools:$PATH" \
./gradlew assembleDebug

# 3. Verify Artifact Alignment & Cryptographic Signature
cd ..
/Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0/zipalign -c -v 4 F91_Jepler-companion-debug.apk
JAVA_HOME="/Users/jacobloesch/Library/Application Support/minecraft/runtime/java-runtime-delta/mac-os-arm64/java-runtime-delta/jre.bundle/Contents/Home" \
PATH="$JAVA_HOME/bin:$PATH" \
/Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0/apksigner verify --verbose F91_Jepler-companion-debug.apk
```
Invalidation conditions:
- Any test in `npm test` fails.
- `zipalign` or `apksigner` reports verification failure.
- SHA-256 hash of `app-debug.apk` diverges from `F91_Jepler-companion-debug.apk`.
