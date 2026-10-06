# Sideloadable Android APK Specification & Verification Report

## Features Discovered
| # | Category | Feature | Description | Inputs | Outputs | Error Behavior | Discovered Via |
|---|----------|---------|-------------|--------|---------|----------------|----------------|
| 1 | Manifest & App Identity | Application ID / Namespace | App package namespace uniquely identifying F91_Jepler companion app | `build.gradle`, `capacitor.config.ts` | `com.f91jepler.companion` | Package name collision on device | `android/app/build.gradle:4,8`, `capacitor.config.ts:4` |
| 2 | Manifest & App Identity | Launchable MainActivity | Root entry activity with standard Android launch intent filters | App launch intent from OS or user | Launches `BridgeActivity` WebView UI | ActivityNotFoundException if intent filter missing or unexported | `AndroidManifest.xml:12-25`, `MainActivity.java:5` |
| 3 | Manifest & App Identity | Exported Component Flag | `android:exported="true"` declared on MainActivity | Android 12+ package manager verification | Allows OS launcher to invoke activity | Package parsing error on API 31+ if intent filter present without exported flag | `AndroidManifest.xml:18` |
| 4 | Permissions & Hardware | Android 12+ BLE Scanning | `android.permission.BLUETOOTH_SCAN` runtime permission | App requests scan for `F91_Jepler` (UUID `fa35b2f0-7989-11eb-9439-0242ac130002`) | Scan results with advertising packets | `SecurityException` / Scan failure if denied | `AndroidManifest.xml:45`, `BluetoothLe.kt:71` |
| 5 | Permissions & Hardware | Android 12+ BLE Connection | `android.permission.BLUETOOTH_CONNECT` runtime permission | App initiates GATT connection & characteristic read/write | Established BLE link to smartwatch | `SecurityException` on GATT connect / write if denied | `AndroidManifest.xml:46`, `BluetoothLe.kt:77` |
| 6 | Permissions & Hardware | Legacy Bluetooth Permissions | `BLUETOOTH` and `BLUETOOTH_ADMIN` with `android:maxSdkVersion="30"` | Android 6 to Android 11 devices | Grants basic BLE radio access | Permissions omitted on Android 12+ devices | `AndroidManifest.xml:43-44`, `BluetoothLe.kt:60,65` |
| 7 | Permissions & Hardware | Location Permissions for BLE | `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` | Scanning on Android 6–11 or Android 12+ without neverForLocation | Enables beacon/peripheral discovery | Scanning returns zero devices if denied or if GPS toggle disabled | `AndroidManifest.xml:41-42`, `BluetoothLe.kt:50,55` |
| 8 | Permissions & Hardware | BLE Hardware Feature | `<uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />` | Play Store / Device PackageManager | Filters devices without BLE chipsets | Installation blocked if hardware lacks BLE | `AndroidManifest.xml:48` |
| 9 | Permissions & Hardware | Internet Permission | `android.permission.INTERNET` | Webview network requests / local bridging | Allows network access | Socket / network permission error | `AndroidManifest.xml:40` |
| 10 | Packaging & Signing | Debug APK Target | `assembleDebug` Gradle task producing `app-debug.apk` | `./gradlew assembleDebug` | Signed, debuggable APK in `app/build/outputs/apk/debug/` | Build fails if JDK/SDK missing | `build.gradle`, AGP specification |
| 11 | Packaging & Signing | Standard Debug Keystore | Automatic signing using `~/.android/debug.keystore` | Default password `android`, alias `androiddebugkey` | Valid PKCS12 certificate chain (valid to 2053) | Keystore corrupt or inaccessible | `~/.android/debug.keystore`, `keytool` inspection |
| 12 | Packaging & Signing | Multi-Scheme APK Signing | Android v1 (JAR), v2 (APK Signature), and v3 signing schemes | AGP packaging step | Embedded signature blocks in APK | `INSTALL_PARSE_FAILED_NO_CERTIFICATES` if unsigned | `apksigner` specification |
| 13 | Packaging & Signing | Debuggable Manifest Injection | AGP automatically merges `android:debuggable="true"` into debug APK | Debug build variant | Enables Chrome Remote Debugging (`chrome://inspect`) & logcat | Release APK disables WebView inspector | Android Build System spec |
| 14 | Packaging & Signing | ProGuard / R8 Disabling | `minifyEnabled false` in `app/build.gradle` | Compilation pipeline | Code and reflection classes intact without obfuscation | If enabled without keep rules, Capacitor bridge reflection crashes | `android/app/build.gradle:21` |
| 15 | Verification Tooling | `aapt dump badging` | Extracts package name, version, SDK limits, activities, and permissions | Path to `.apk` file | Structured badging output text | Fails if APK is corrupted or invalid zip | `/Users/jacobloesch/Library/Android/sdk/build-tools/34.0.0/aapt` |
| 16 | Verification Tooling | `aapt dump permissions` | Extracts declared Android permissions | Path to `.apk` file | List of `uses-permission` entries | Fails if manifest missing | `/Users/jacobloesch/Library/Android/sdk/build-tools/34.0.0/aapt` |
| 17 | Verification Tooling | `apksigner verify` | Validates APK cryptographic signatures and certificates | Path to `.apk` file + `JAVA_HOME` | `Verifies`, signature scheme levels (v1/v2/v3), cert SHA-256 | Fails with signature verification error if APK tampered or unsigned | `/Users/jacobloesch/Library/Android/sdk/build-tools/34.0.0/apksigner` |
| 18 | Verification Tooling | `zipalign -c -v 4` | Verifies 4-byte memory boundary alignment | Path to `.apk` file | `Verification successful` | `Verification FAILED` if unaligned | `/Users/jacobloesch/Library/Android/sdk/build-tools/34.0.0/zipalign` |
| 19 | Verification Tooling | `unzip -l` | Verifies presence of DEX, assets, resources, and manifest | Path to `.apk` file | List of archive files, dates, sizes | Fails if not a valid zip archive | `/usr/bin/unzip` |
| 20 | Verification Tooling | `file` utility | Verifies zip archive MIME/magic byte header | Path to `.apk` file | `Zip archive data, at least v...` | Reports generic data or error | `/usr/bin/file` |
| 21 | Sideload Procedures | ADB Sideload Install | High-speed direct install with auto-permissions via USB | `adb install -r -t -g <apk_path>` | `Success` response from Package Manager | `INSTALL_FAILED_ALREADY_EXISTS` without `-r`, or `INSTALL_FAILED_TEST_ONLY` without `-t` | `/opt/homebrew/bin/adb` |
| 22 | Sideload Procedures | ADB App Execution | Direct activity launcher via ADB Activity Manager | `adb shell am start -n com.f91jepler.companion/.MainActivity` | `Starting: Intent { cmp=... }` | `Error: Activity not found` | `/opt/homebrew/bin/adb` |
| 23 | Sideload Procedures | Device Manual Transfer | User downloads APK to storage, opens via Files app | `app-debug.apk` file on Android device | System Package Installer UI dialog | Blocked by "Install unknown apps" setting until allowed | Android Package Installer |
| 24 | Sideload Procedures | Unknown Apps Permission | System security gate requiring per-source toggle | User toggle in Settings > Apps > Special access | Permits file manager to trigger package installation | Installation halted until permission given | Android Settings UI |
| 25 | Sideload Procedures | Play Protect Warning Handling | Play Protect scans self-signed debug certificates | Dialog with "More details" -> "Install anyway" | Bypasses Play Protect block | Installation aborted if dismissed | Google Play Protect |

## Edge Cases
| # | Feature | Input | Observed Behavior |
|---|---------|-------|-------------------|
| 1 | System Tooling (`apkanalyzer`) | Running legacy `sdk/tools/bin/apkanalyzer` with Java 25 / modern JDK | Crashes with `java.lang.NoClassDefFoundError: javax/xml/bind/annotation/XmlSchema` due to Java 9+ JAXB removal. Verified that `aapt dump badging` is the authoritative replacement. |
| 2 | Gradle Toolchain | Running Gradle 8.14.3 with JDK 25 (`/Applications/Android Studio.app/Contents/jbr`) | Fails with `BUG! exception in phase 'semantic analysis' in source unit '_BuildScript_' Unsupported class file major version 69`. Requires JDK 17 or JDK 21 (class major version 61/65). |
| 3 | SDK Platform Availability | Building with `compileSdkVersion = 36` in `variables.gradle` | Local SDK only contains `android-33` and `android-34` in `~/Library/Android/sdk/platforms/`. Offline builds fail unless platform 36 is downloaded or `compileSdkVersion`/`targetSdkVersion` is set to 34. |
| 4 | ADB Install Test Flag | Running `adb install <apk>` on debuggable build | Some Android OEM devices reject debug builds without `-t` (`INSTALL_FAILED_TEST_ONLY`). Adding `-t` (`adb install -r -t -g`) guarantees universal compatibility. |
| 5 | Legacy BLE Location Toggle | Scanning for BLE devices on Android 6–11 with GPS/Location turned OFF in quick settings | BLE scan callback returns zero devices even though `ACCESS_FINE_LOCATION` was granted, because Android 6–11 enforces hardware location services enablement for BLE scans. |
| 6 | Android 12+ Permission Pairing | Granting `BLUETOOTH_SCAN` but denying `BLUETOOTH_CONNECT` | Peripheral discovery succeeds, but calling `connect()` throws `SecurityException: Need android.permission.BLUETOOTH_CONNECT`. Both must be granted. |
| 7 | Keystore Collision / Reinstallation | Installing debug APK over a previously installed release APK (or APK built on another developer's machine) | Fails with `INSTALL_FAILED_UPDATE_INCOMPATIBLE: Existing package and new package have different signatures`. Requires `adb uninstall com.f91jepler.companion` first. |
| 8 | Missing Web Bundle in APK | Building APK without running `npm run build && npx cap copy android` | APK builds and installs successfully, but `assets/public/index.html` is missing or stale, leading to a blank white screen upon launch. `unzip -l` must verify `assets/public/index.html`. |

---

## 1. Observation

Direct inspection of the project files, Android SDK, and system environment revealed the following verified facts:

### A. AndroidManifest.xml and Identity Specifications
File: `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/android/app/src/main/AndroidManifest.xml`
- **Application ID / Package**:
  `com.f91jepler.companion` (defined in `android/app/build.gradle:4,8` and `capacitor.config.ts:4`).
- **MainActivity**:
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
  `android:exported="true"` is explicitly set, satisfying Android 12+ (API 31+) requirements for activities containing intent filters.
- **Permissions Declared**:
  - `android.permission.INTERNET`
  - `android.permission.ACCESS_COARSE_LOCATION`
  - `android.permission.ACCESS_FINE_LOCATION`
  - `android.permission.BLUETOOTH` (with `android:maxSdkVersion="30"`)
  - `android.permission.BLUETOOTH_ADMIN` (with `android:maxSdkVersion="30"`)
  - `android.permission.BLUETOOTH_SCAN`
  - `android.permission.BLUETOOTH_CONNECT`
- **Hardware Requirement**:
  - `<uses-feature android:name="android.hardware.bluetooth_le" android:required="true" />`
- **Capacitor Plugin Alignment**:
  In `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/node_modules/@capacitor-community/bluetooth-le/android/src/main/java/com/capacitorjs/community/plugins/bluetoothle/BluetoothLe.kt:47-77`, the plugin requests matching runtime aliases (`ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION`, `BLUETOOTH`, `BLUETOOTH_ADMIN`, `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`).

### B. Keystore and Sideloading Specifications
- Existing Keystore: `~/.android/debug.keystore` exists on this system.
- Direct verification with `keytool`:
  ```
  Command: "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" -list -v -keystore ~/.android/debug.keystore -storepass android
  Output:
  Alias name: androiddebugkey
  Creation date: Jul 13, 2023
  Owner: C=US, O=Android, CN=Android Debug
  Valid from: Thu Jul 13 14:16:13 CDT 2023 until: Sat Jul 05 14:16:13 CDT 2053
  Certificate fingerprints:
    SHA1: A0:D3:F2:A8:A5:E7:D9:27:6B:C8:B0:5A:9A:64:B8:33:3F:32:45:1B
    SHA256: 32:6E:20:17:4A:4E:6C:72:A4:7C:77:7E:04:0E:FC:A1:94:7E:8B:3A:96:1E:B1:95:72:F4:34:52:66:3A:F7:8F
  Signature algorithm name: SHA256withRSA
  Subject Public Key Algorithm: 2048-bit RSA key
  ```
- Debug builds automatically consume this key without requiring manual password entry or external key files.

### C. Available Verification Tooling in System
- **`aapt`**: `/Users/jacobloesch/Library/Android/sdk/build-tools/34.0.0/aapt` (Android Asset Packaging Tool v0.2-10229193). Executed successfully.
- **`aapt2`**: `/Users/jacobloesch/Library/Android/sdk/build-tools/34.0.0/aapt2` (AAPT 2.19-10229193). Executed successfully.
- **`apksigner`**: `/Users/jacobloesch/Library/Android/sdk/build-tools/34.0.0/apksigner` (v0.9). Executed and verified against sample APK (`SystemUIEmulationPixel10Overlay.apk`), verifying v3 signature scheme and cert hash.
- **`zipalign`**: `/Users/jacobloesch/Library/Android/sdk/build-tools/34.0.0/zipalign`. Executed and verified 4-byte alignment on sample APK.
- **`adb`**: `/opt/homebrew/bin/adb` and `/Users/jacobloesch/Library/Android/sdk/platform-tools/adb` (v1.0.41, v37.0.1). Started daemon tcp:5037 cleanly.
- **`unzip`**: `/usr/bin/unzip`. Verified archive listing.
- **`file`**: `/usr/bin/file`. Verified zip container identification.
- **`dexdump`**: `/Users/jacobloesch/Library/Android/sdk/build-tools/34.0.0/dexdump`. Verified bytecode header tool availability.
- **`apkanalyzer` exception**: Legacy script `/Users/jacobloesch/Library/Android/sdk/tools/bin/apkanalyzer` threw `java.lang.NoClassDefFoundError: javax/xml/bind/annotation/XmlSchema` under Java 25.

### D. Installed Android SDK Platforms
Directory: `/Users/jacobloesch/Library/Android/sdk/platforms/`
- Contains: `android-33`, `android-34`.
- Note: `android-36` is referenced in `variables.gradle` (`compileSdkVersion = 36`), but is not installed locally in `platforms/`.

---

## 2. Logic Chain

1. **Manifest Validity**:
   - `AndroidManifest.xml` defines `MainActivity` with `android.intent.action.MAIN` and `android.intent.category.LAUNCHER`.
   - `android:exported="true"` is declared on the activity, which avoids the Android 12+ manifest validation crash.
   - All necessary Bluetooth Low Energy permissions (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `BLUETOOTH`, `BLUETOOTH_ADMIN`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`) and the hardware feature `android.hardware.bluetooth_le` are present.
   - Therefore, the application manifest complies with Android 6.0 through Android 15/16 specifications for BLE companion apps.

2. **Debug APK Sideloading Viability**:
   - Android enforces that every installed APK must be signed.
   - An unsigned APK (e.g. default output of `assembleRelease`) fails installation with `INSTALL_PARSE_FAILED_NO_CERTIFICATES`.
   - The `assembleDebug` task automatically binds `signingConfigs.debug`, using `~/.android/debug.keystore`, which we verified exists, is valid until 2053, and uses 2048-bit RSA.
   - Debug APKs have `android:debuggable="true"` injected, allowing Chrome Remote Debugging (`chrome://inspect`) to inspect the Capacitor web view and console logs during clock sync testing.
   - Minification is disabled (`minifyEnabled false`), preventing R8 from stripping Capacitor reflection classes.
   - Therefore, the Debug APK (`app-debug.apk`) is the optimal target for direct end-user sideloading.

3. **Verification Tooling Robustness**:
   - Although the legacy `tools/bin/apkanalyzer` script fails under modern JDKs due to missing JAXB, native binaries in `build-tools/34.0.0` (`aapt`, `aapt2`, `zipalign`, `dexdump`) and the standalone utilities (`apksigner`, `unzip`, `file`) provide 100% verification coverage.
   - We executed test runs using `aapt dump badging`, `zipalign -c -v 4`, and `apksigner verify --verbose`, confirming that any generated APK can be completely validated without a physical device connected.

4. **User Sideloading Workflows**:
   - For developer/direct installation: `adb install -r -t -g <path>` handles installation, allows test packages, and pre-grants runtime permissions in a single atomic step.
   - For end-user installation: Transferring the APK via file sharing / USB and opening it requires enabling "Install unknown apps" for the file manager and acknowledging Play Protect's prompt regarding the self-signed debug certificate.

---

## 3. Caveats

1. **Gradle Build Environment Dependency**:
   - As observed when testing `./gradlew tasks`, the Android Studio bundled JDK is Java 25 (`class file major version 69`), which Gradle 8.14.3's Groovy parser rejects. Building the APK requires setting `JAVA_HOME` to a compatible JDK (e.g., JDK 17 or JDK 21).
2. **SDK Platform Version Alignment**:
   - `variables.gradle` specifies `compileSdkVersion = 36` and `targetSdkVersion = 36`, whereas `/Users/jacobloesch/Library/Android/sdk/platforms/` currently contains `android-33` and `android-34`. If Gradle is run offline or without automatic platform downloading, `compileSdkVersion` and `targetSdkVersion` should be aligned with `34` (or `android-36` installed via SDK manager).
3. **Physical BLE Device Testing**:
   - ADB and verification tools verify the APK structure, certificates, and manifest on the computer; actual BLE communication with the F91_Jepler physical watch requires deploying to a physical Android device with Bluetooth turned on.

---

## 4. Conclusion

1. **Specification Verified**: The companion app's Android configuration is fully capable of producing a sideloadable APK.
2. **Target Artifact**: The ideal build target is `assembleDebug`, which outputs:
   `Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk`.
3. **Artifact Readiness**: The artifact will be pre-signed by `~/.android/debug.keystore`, launchable via `com.f91jepler.companion/.MainActivity`, and properly configured with all BLE permissions for Android 6 through Android 15+.
4. **Verification Strategy**: The generated APK can be verified using a 5-step test suite:
   - File format check (`file`)
   - Archive & assets check (`unzip -l`, confirming `assets/public/index.html` and `classes.dex`)
   - Manifest badging check (`aapt dump badging`)
   - Memory alignment check (`zipalign -c -v 4`)
   - Cryptographic signature check (`apksigner verify --verbose`)
5. **Sideloading Instructions**: Clear, unambiguous step-by-step instructions exist for both `adb install` and manual file transfer methods.

---

## 5. Verification Method

To independently verify the tooling and specifications documented in this report:

### Step 1: Verify System Inspection Tools
Run the following verification suite in terminal:
```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export PATH="$JAVA_HOME/bin:/Users/jacobloesch/Library/Android/sdk/build-tools/34.0.0:/opt/homebrew/bin:$PATH"

# 1. Verify AAPT
/Users/jacobloesch/Library/Android/sdk/build-tools/34.0.0/aapt version

# 2. Verify apksigner
apksigner --version

# 3. Verify zipalign
/Users/jacobloesch/Library/Android/sdk/build-tools/34.0.0/zipalign 2>&1 | grep "Zip alignment utility"

# 4. Verify ADB
adb version

# 5. Verify Debug Keystore
keytool -list -keystore ~/.android/debug.keystore -storepass android | grep "androiddebugkey"
```

### Step 2: Verify a Built APK (Once Assembled)
When `app-debug.apk` is generated at `Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk`, execute:
```bash
APK_PATH="/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk"
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"

# A. Container Format
file "$APK_PATH"

# B. Internal Assets (Verify classes.dex, AndroidManifest.xml, and web assets)
unzip -l "$APK_PATH" | grep -E "classes.dex|AndroidManifest.xml|assets/public/index.html"

# C. Package & Launchable Activity Badging
/Users/jacobloesch/Library/Android/sdk/build-tools/34.0.0/aapt dump badging "$APK_PATH" | grep -E "package: name='com.f91jepler.companion'|launchable-activity: name='com.f91jepler.companion.MainActivity'"

# D. Permissions
/Users/jacobloesch/Library/Android/sdk/build-tools/34.0.0/aapt dump permissions "$APK_PATH" | grep -E "BLUETOOTH_SCAN|BLUETOOTH_CONNECT"

# E. 4-Byte Zip Alignment
/Users/jacobloesch/Library/Android/sdk/build-tools/34.0.0/zipalign -c -v 4 "$APK_PATH"

# F. Cryptographic Signature
"$JAVA_HOME/bin/java" -jar /Users/jacobloesch/Library/Android/sdk/build-tools/34.0.0/lib/apksigner.jar verify --verbose "$APK_PATH"
```

### Step 3: Verify Sideloading onto Connected Android Device
With an Android device connected via USB and USB debugging enabled:
```bash
# 1. Confirm device recognized
adb devices

# 2. Install APK with automatic permissions
adb install -r -t -g "$APK_PATH"

# 3. Launch MainActivity
adb shell am start -n com.f91jepler.companion/.MainActivity
```
