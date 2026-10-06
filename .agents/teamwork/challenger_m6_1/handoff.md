# Empirical Verification & Adversarial Challenge Report: M6 Android APK

**Agent**: Challenger 1 (`challenger_m6_1`)  
**Milestone**: M6 — Sideloadable Android APK Build & Verification  
**Verdict**: **APPROVE**  
**Overall Risk Assessment**: LOW  

---

## 1. Observation

### 1.1 Target Artifacts & File Invariants
Both primary output APKs exist, are non-empty, and are byte-for-byte identical:
- Top-level convenience artifact: `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/F91_Jepler-companion-debug.apk`
- Gradle build output: `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk`

Verbatim verification command & output:
```bash
shasum -a 256 Software/companion_app/F91_Jepler-companion-debug.apk Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk
```
Output:
```
14dc371c3e8e5394ca981d3258bc30d1fcb524d5f728b9eca0b19ad371bdf928  Software/companion_app/F91_Jepler-companion-debug.apk
14dc371c3e8e5394ca981d3258bc30d1fcb524d5f728b9eca0b19ad371bdf928  Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk
```
Exact file size: `4,314,108` bytes (~4.3 MB).

### 1.2 Zip Archive Integrity & Entry Traversal Checks
- Ran `unzip -t Software/companion_app/F91_Jepler-companion-debug.apk`:
  - 447 total zip entries verified.
  - Output verbatim: `No errors detected in compressed data of Software/companion_app/F91_Jepler-companion-debug.apk.`
- Custom Python structural check verified:
  - 0 duplicate entry names.
  - 0 entries with absolute paths (no leading `/`).
  - 0 entries with directory traversal (`..`).
  - 447 of 447 entries have valid CRC-32 checksums matching decompressed payload data.

### 1.3 Bytecode & DEX Structure Analysis
The APK contains 8 DEX files: `classes.dex` through `classes8.dex`. Each was inspected using both binary parser verification and `/Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0/dexdump -f`:
- All 8 DEX headers start with magic `dex\n037\0` and endian tag `0x12345678`.
- Header sizes are 112 bytes across all files.
- Adler-32 header checksums and SHA-1 signatures match the byte payload:
  - `classes.dex`: 8,500,108 bytes, 5,057 classes, 46,462 methods (Adler32 `0xaa796e88`, SHA-1 `2152...82fe` VALID).
  - `classes2.dex`: 88,556 bytes, 43 classes, 517 methods (Adler32 `0xd94fcc35`, SHA-1 `9a33...ae03` VALID). Contains `Lcom/capacitorjs/community/plugins/bluetoothle/BluetoothLe;` (subclass of `Lcom/getcapacitor/Plugin;`).
  - `classes3.dex`: 21,820 bytes, 21 classes, 187 methods (Adler32 `0x282fce5c`, SHA-1 `f03c...c0cb` VALID). Contains `Lcom/getcapacitor/annotation/CapacitorPlugin;`.
  - `classes4.dex`: 153,260 bytes, 82 classes, 1,230 methods (Adler32 `0xe8da0457`, SHA-1 `4ec7...9e07` VALID). Contains `Lcom/getcapacitor/CapacitorWebView;`.
  - `classes5.dex`: 9,188 bytes, 4 classes, 92 methods (Adler32 `0x0b150466`, SHA-1 `3fd2...814d` VALID).
  - `classes6.dex`: 51,876 bytes, 23 classes, 473 methods (Adler32 `0x5340eb11`, SHA-1 `24d6...dcf3` VALID). Contains `Lcom/getcapacitor/plugin/CapacitorCookieManager;`, `Lcom/getcapacitor/plugin/CapacitorHttp;`.
  - `classes7.dex`: 132,612 bytes, 157 classes, 169 methods (Adler32 `0x45cd8765`, SHA-1 `e055...5208` VALID). Contains `Lcom/f91jepler/companion/R;`.
  - `classes8.dex`: 652 bytes, 1 class, 2 methods (Adler32 `0xd0507837`, SHA-1 `13e7...13a5` VALID). Contains `Lcom/f91jepler/companion/MainActivity;` (subclass of `Lcom/getcapacitor/BridgeActivity;`).

### 1.4 Web Asset Parity & Payload Verification
Compared compiled web assets in `Software/companion_app/dist` against `assets/public/` inside the APK:
- `index.html`:
  - `dist/index.html`: `2d824d6747618529d14916369bc1a881346d150b8d963383959fc10839316f09` (535 bytes)
  - `APK:assets/public/index.html`: `2d824d6747618529d14916369bc1a881346d150b8d963383959fc10839316f09` (535 bytes)
- `assets/index-_qkASCwR.css`:
  - `dist`: `5fb334db02dc07c09fdaa4d4c878d095c1110e4e1713de9fa428f5dbbe18ef44` (22,897 bytes)
  - `APK`: `5fb334db02dc07c09fdaa4d4c878d095c1110e4e1713de9fa428f5dbbe18ef44` (22,897 bytes)
- `assets/index-RPmAMwiC.js`:
  - `dist`: `f84ee8baae6c443cf2707e88d5dc5a2399c94180081229a482b507613262574e` (294,463 bytes)
  - `APK`: `f84ee8baae6c443cf2707e88d5dc5a2399c94180081229a482b507613262574e` (294,463 bytes)
- `assets/web-gq334oLb.js`:
  - `dist`: `7e6535f2b919b910980a7c127bf045115b78fdaefcaf17bd3d5cd3811a985af9` (7,646 bytes)
  - `APK`: `7e6535f2b919b910980a7c127bf045115b78fdaefcaf17bd3d5cd3811a985af9` (7,646 bytes)

Inspected JavaScript bundle contents inside `assets/public/assets/index-RPmAMwiC.js`:
- Verified occurrences of device name and GATT service/characteristic UUIDs:
  - `F91_Jepler`: 5 occurrences
  - Clock Service UUID `fa35b2f0-7989-11eb-9439-0242ac130002`: 4 occurrences
  - Time Characteristic UUID `fa35b2f1-7989-11eb-9439-0242ac130002`: 2 occurrences
  - Timezone Characteristic UUID `fa35b2f2-7989-11eb-9439-0242ac130002`: 2 occurrences
  - Time Mode Characteristic UUID `fa35b2f3-7989-11eb-9439-0242ac130002`: 2 occurrences
  - DST Characteristic UUID `fa35b2f4-7989-11eb-9439-0242ac130002`: 2 occurrences
- Verified native platform auto-detection logic:
  - `Capacitor.isNativePlatform()` present and bundled (2 occurrences).
  - Plugin mappings in `assets/capacitor.plugins.json` correctly map `@capacitor-community/bluetooth-le` to `com.capacitorjs.community.plugins.bluetoothle.BluetoothLe`.

### 1.5 Signature & Security Scheme Checks
Executed `apksigner verify --verbose`:
```bash
JAVA_HOME="/Users/jacobloesch/Library/Application Support/minecraft/runtime/java-runtime-delta/mac-os-arm64/java-runtime-delta/jre.bundle/Contents/Home" \
PATH="$JAVA_HOME/bin:$PATH" \
/Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0/apksigner verify --verbose Software/companion_app/F91_Jepler-companion-debug.apk
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
```
Signer certificate details via `apksigner verify --print-certs`:
- DN: `C=US, O=Android, CN=Android Debug`
- SHA-256 Digest: `326e20174a4e6c72a47c777e040efca1947e8b3a961eb19572f43452663af78f`

### 1.6 Adversarial Tampering Stress Tests
1. **Bit-flip in file payload**:
   - Modified byte 500 of the APK.
   - Output from `apksigner verify`:
     ```
     DOES NOT VERIFY
     ERROR: APK Signature Scheme v2 signer #1: APK integrity check failed. CHUNKED_SHA256 digest mismatch.
     ```
     Exit code: `1`.
2. **ZIP Entry Injection**:
   - Injected a new unauthenticated file (`new_asset/hacked.txt`) into the APK.
   - Output from `apksigner verify`:
     ```
     DOES NOT VERIFY
     ERROR: Missing META-INF/MANIFEST.MF
     ```
     Exit code: `1`.

### 1.7 Strict 4-Byte Zip Alignment Checks
1. Built-in `zipalign -c -v 4`:
   ```bash
   /Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0/zipalign -c -v 4 Software/companion_app/F91_Jepler-companion-debug.apk
   ```
   Output: `Verification succesful` (Exit code: `0`).
   Also confirmed on `Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk` (Exit code: `0`).
2. Programmatic Python verification:
   - Scanned all 447 entries across local headers and central directory.
   - 221 entries are stored uncompressed (STORED / method 0).
   - Evaluated `data_offset % 4` for all 221 entries. Result: `0` misaligned entries (100% 4-byte aligned).
3. Adversarial alignment test:
   - Created test zip with a 1-byte misaligned STORED entry. `zipalign -c -v 4` correctly caught the violation (`(BAD - 3) Verification FAILED`, Exit code `1`).

### 1.8 Manifest & Permission Invariants
Command:
```bash
/Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0/aapt dump badging Software/companion_app/F91_Jepler-companion-debug.apk
```
Extracted badging metadata:
- Package: `com.f91jepler.companion`
- Version Code: `1`
- Version Name: `1.0`
- Min SDK: `24` (Android 7.0)
- Target SDK: `36` (Android 16 preview)
- Launchable Activity: `com.f91jepler.companion.MainActivity`
- Hardware Feature: `android.hardware.bluetooth_le` (required=true)
- Declared permissions:
  - `android.permission.INTERNET`
  - `android.permission.BLUETOOTH_SCAN`
  - `android.permission.BLUETOOTH_CONNECT`
  - `android.permission.ACCESS_FINE_LOCATION`
  - `android.permission.ACCESS_COARSE_LOCATION`
  - `android.permission.BLUETOOTH` (maxSdkVersion=30)
  - `android.permission.BLUETOOTH_ADMIN` (maxSdkVersion=30)

Command:
```bash
/Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0/aapt dump xmltree Software/companion_app/F91_Jepler-companion-debug.apk AndroidManifest.xml
```
Verified Android 12+ (API 31+) exported activity invariant:
- Activity `com.f91jepler.companion.MainActivity` explicitly sets `android:exported="true"` (`(type 0x12)0xffffffff`).
- Contained intent filter:
  - Action: `android.intent.action.MAIN`
  - Category: `android.intent.category.LAUNCHER`

---

## 2. Logic Chain

1. **Archive Integrity**:
   - Observations 1.1 and 1.2 demonstrate that the APK is an intact, non-corrupted ZIP archive containing 447 entries with matching CRCs and no traversal exploits.
2. **Bytecode Viability**:
   - Observation 1.3 shows that the APK's 8 DEX files contain valid Dalvik/ART bytecode headers, valid Adler-32 and SHA-1 checksums, and proper multiversion class definitions.
   - `MainActivity` cleanly inherits from `com.getcapacitor.BridgeActivity`, and the native Bluetooth plugin `BluetoothLe` is compiled into `classes2.dex`.
3. **Web Asset Packaging**:
   - Observation 1.4 confirms exact SHA-256 matching between Vite's `dist/` directory and the APK's `assets/public/` folder.
   - All necessary GATT UUIDs and native platform detection logic are embedded in the production JS bundle, enabling the application to run completely standalone and offline.
4. **Android OS Compatibility & Security**:
   - Observations 1.5 and 1.6 prove that the APK is signed with APK Signature Scheme v2, which is mandatory for sideloading on modern Android (API 24+).
   - Adversarial tampering tests confirmed that any file corruption or unauthorized payload injection triggers a hard verification failure.
   - Observation 1.7 proves that all uncompressed assets are strictly aligned to 4-byte memory boundaries, satisfying `mmap()` alignment requirements.
   - Observation 1.8 verifies all required Bluetooth permissions across both Android 12+ (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`) and legacy versions (`ACCESS_FINE_LOCATION`, `BLUETOOTH`). Furthermore, `MainActivity` explicitly declares `android:exported="true"`, preventing install rejections on API 31+.

---

## 3. Caveats

- **Debug Signing Certificate**: The APK is signed using the standard Android debug keystore (`CN=Android Debug`). While ideal for direct sideloading and testing, Android's Play Protect will present an "Unrecognized app" prompt upon initial installation, requiring the user to tap "Install anyway".
- **Physical BLE Hardware**: Empirical verification was executed on the static APK container and runtime tools in macOS without a connected physical Android device. Full end-to-end hardware BLE over-the-air transmission requires a physical Android smartphone with Bluetooth enabled.

---

## 4. Conclusion

The generated Android APK (`Software/companion_app/F91_Jepler-companion-debug.apk`) meets all criteria for a sideloadable Android package. It is cryptographically signed, 4-byte zipaligned, contains valid multiversion DEX bytecode, embeds all production web assets matching `dist/`, and declares compliant manifest permissions and exported activity attributes.

**Explicit Verdict**: **APPROVE**

---

## 5. Verification Method

To independently reproduce this verification:

```bash
cd /Users/jacobloesch/Documents/F91_Jepler/Software/companion_app

# 1. Verify archive integrity
unzip -t F91_Jepler-companion-debug.apk

# 2. Verify strict 4-byte alignment
/Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0/zipalign -c -v 4 F91_Jepler-companion-debug.apk

# 3. Verify APK signature
JAVA_HOME="/Users/jacobloesch/Library/Application Support/minecraft/runtime/java-runtime-delta/mac-os-arm64/java-runtime-delta/jre.bundle/Contents/Home" \
PATH="$JAVA_HOME/bin:$PATH" \
/Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0/apksigner verify --verbose F91_Jepler-companion-debug.apk

# 4. Verify package badging and permissions
/Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0/aapt dump badging F91_Jepler-companion-debug.apk

# 5. Verify DEX headers
/Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0/dexdump -f F91_Jepler-companion-debug.apk
```
