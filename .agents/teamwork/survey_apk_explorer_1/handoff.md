# Handoff Report: Android Environment & Build Toolchain Survey

## 1. Observation

### 1.1 Java/JDK System State & Versions
- **Default Shell & macOS Shim**:
  - Command: `java -version`, `javac -version`, `/usr/libexec/java_home -V`
  - Output:
    ```
    The operation couldn’t be completed. Unable to locate a Java Runtime.
    JAVA_HOME=
    ```
- **Installed Java Runtimes Identified**:
  1. **Homebrew OpenJDK 27**:
     - Path: `/opt/homebrew/Cellar/openjdk/27/libexec/openjdk.jdk/Contents/Home`
     - Version: `openjdk version "27" 2026-09-15`
     - Failure observed when running Gradle 8.14.3:
       ```
       BUG! exception in phase 'semantic analysis' in source unit '_BuildScript_' Unsupported class file major version 71
       ```
  2. **Android Studio Bundled JBR (Java 25)**:
     - Path: `/Applications/Android Studio.app/Contents/jbr/Contents/Home`
     - Version: `openjdk version "25.0.3" 2026-04-21` (`JAVA_VERSION="25.0.3"`)
     - Failure observed when running Gradle 8.14.3:
       ```
       Caused by: java.lang.IllegalArgumentException: Unsupported class file major version 69
           at groovyjarjarasm.asm.ClassReader.<init>(ClassReader.java:200)
       ```
  3. **Microsoft/Temurin OpenJDK 21.0.3 LTS (Full JDK with javac)**:
     - Path: `/Users/jacobloesch/Library/Application Support/minecraft/runtime/java-runtime-delta/mac-os-arm64/java-runtime-delta/jre.bundle/Contents/Home`
     - Binaries: Both `java` and `javac` are present in `bin/`.
     - Version: `openjdk version "21.0.3" 2024-04-16 LTS`, `javac 21.0.3`
     - Execution result with Gradle 8.14.3: Passed cleanly without errors.
  4. **Homebrew Formula Status**:
     - `brew info openjdk@21` confirms `openjdk@21: stable 21.0.12.1 (bottled)` is available for installation if a formal brew-managed path is preferred (`/opt/homebrew/opt/openjdk@21`).

---

### 1.2 Android SDK Installation & Structure
- **SDK Directory**: `/Users/jacobloesch/Library/Android/sdk` (configured in `Software/companion_app/android/local.properties:11`: `sdk.dir=/Users/jacobloesch/Library/Android/sdk`).
- **Platforms**:
  - Pre-existing: `android-33` (Android 13), `android-34` (Android 14).
  - Downloaded by Gradle during evaluation: `android-36` (Android API 36, revision 2).
- **Build Tools**:
  - Pre-existing: `30.0.3`, `34.0.0`.
  - Downloaded by Gradle during evaluation: `35.0.0`.
- **Platform Tools**:
  - Location: `/Users/jacobloesch/Library/Android/sdk/platform-tools`
  - Includes `adb`, `fastboot`, `etc1tool`.
- **Licenses**:
  - Location: `/Users/jacobloesch/Library/Android/sdk/licenses/`
  - Pre-accepted licenses present: `android-sdk-license` (sha1 `24333f8a63b6825ea9c5514f83c2829b004d1fee`) and `android-sdk-arm-dbt-license`.
- **Command Line Tools**:
  - `/Users/jacobloesch/Library/Android/sdk/tools/bin/sdkmanager` is revision 26.1.1 (legacy SDK tools, fails on Java > 8 due to removed JAXB modules).
  - Modern `cmdline-tools` directory is not installed; however, Gradle AGP 8.13.0 manages package downloads natively using the pre-accepted `licenses/`.

---

### 1.3 Companion App Android Project Structure
- **Location**: `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/android`
- **Gradle Wrapper**:
  - Executable: `gradlew` (mode 755 executable).
  - Configuration (`gradle/wrapper/gradle-wrapper.properties`):
    `distributionUrl=https\://services.gradle.org/distributions/gradle-8.14.3-all.zip`
- **Root Build File** (`build.gradle`):
  - Line 10: `classpath 'com.android.tools.build:gradle:8.13.0'`
  - Line 11: `classpath 'com.google.gms:google-services:4.4.4'`
- **Version Variables** (`variables.gradle`):
  - Lines 1-4:
    ```groovy
    ext {
        minSdkVersion = 24
        compileSdkVersion = 36
        targetSdkVersion = 36
    ...
    ```
- **App Module Configuration** (`app/build.gradle`):
  - Line 4: `namespace = "com.f91jepler.companion"`
  - Line 7: `applicationId "com.f91jepler.companion"`
  - Line 8: `minSdkVersion rootProject.ext.minSdkVersion` (24)
  - Line 9: `targetSdkVersion rootProject.ext.targetSdkVersion` (36)
  - Line 45: `apply from: 'capacitor.build.gradle'`
- **Capacitor Build Properties** (`app/capacitor.build.gradle`):
  - Lines 4-7:
    ```groovy
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_21
        targetCompatibility JavaVersion.VERSION_21
    }
    ```
- **Settings & Module Links** (`capacitor.settings.gradle`):
  - Line 3: `:capacitor-android` -> `../node_modules/@capacitor/android/capacitor`
  - Line 6: `:capacitor-community-bluetooth-le` -> `../node_modules/@capacitor-community/bluetooth-le/android`
  - Line 9: `:capacitor-app` -> `../node_modules/@capacitor/app/android`
- **Compiled Web Assets**:
  - Synced at `app/src/main/assets/public/`:
    `index.html` (535 bytes)
    `assets/index-SKErwit8.js` (294,376 bytes)
    `assets/index-_qkASCwR.css` (22,897 bytes)
    `assets/web-xfd1Qzza.js` (7,646 bytes)
- **Manifest Permissions** (`app/src/main/AndroidManifest.xml`):
  - Lines 40-48: `INTERNET`, `ACCESS_COARSE_LOCATION`, `ACCESS_FINE_LOCATION`, `BLUETOOTH`, `BLUETOOTH_ADMIN`, `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, and feature `android.hardware.bluetooth_le` (required).

---

### 1.4 Build Execution Results
- **Command Executed**:
  ```bash
  JAVA_HOME="/Users/jacobloesch/Library/Application Support/minecraft/runtime/java-runtime-delta/mac-os-arm64/java-runtime-delta/jre.bundle/Contents/Home" \
  ANDROID_HOME="/Users/jacobloesch/Library/Android/sdk" \
  ./gradlew assembleDebug
  ```
- **Result**:
  - `BUILD SUCCESSFUL in 59s`
  - `154 actionable tasks: 154 executed`
- **Generated Artifact**:
  - File: `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk`
  - Size: 4,311,608 bytes (~4.1 MB)
  - Verified with `apksigner verify --verbose`:
    - `Verifies: true`
    - `Verified using v2 scheme (APK Signature Scheme v2): true`
    - Signed with Android Debug Keystore.

---

## 2. Logic Chain

1. **Gradle and AGP Java Version Constraints**:
   - Observation 1.1 shows that Gradle 8.14.3 uses Groovy 3.0.24 and an ASM library that fails when parsing bytecode from Java 25 (`major version 69`) or Java 27 (`major version 71`).
   - Observation 1.3 shows that Capacitor 8 explicitly specifies `JavaVersion.VERSION_21` in `app/capacitor.build.gradle` and `node_modules/@capacitor/android/capacitor/build.gradle`.
   - Therefore, a JDK matching Java 21 LTS is both required and sufficient.

2. **JDK 21 Availability**:
   - Observation 1.1 reveals that while the macOS system shim `/usr/bin/java` reports no JDK, a full Microsoft/Temurin OpenJDK 21.0.3 installation with `javac` exists at `/Users/jacobloesch/Library/Application Support/minecraft/runtime/java-runtime-delta/mac-os-arm64/java-runtime-delta/jre.bundle/Contents/Home`.
   - Furthermore, `openjdk@21` is bottled in Homebrew if an administrator-level brew package is desired.

3. **Android SDK Resolution**:
   - Observation 1.2 shows that `local.properties` specifies `sdk.dir=/Users/jacobloesch/Library/Android/sdk`.
   - The license `android-sdk-license` is already accepted in `licenses/`.
   - `variables.gradle` specifies `compileSdkVersion = 36`.
   - When Gradle executed under JDK 21, AGP detected that `platforms;android-36` and `build-tools;35.0.0` were missing, verified the pre-accepted license, and successfully auto-installed both components into the SDK directory.

4. **APK Generation and Sideloadability**:
   - Observation 1.4 confirms that `./gradlew assembleDebug` completes with 154 executed tasks, packaging all web assets, Android manifest permissions, and Capacitor plugins (`@capacitor-community/bluetooth-le`, `@capacitor/app`, `@capacitor/android`).
   - The resulting `app-debug.apk` is signed with APK Signature Scheme v2, contains `minSdkVersion 24` and `targetSdkVersion 36`, and is immediately ready to be sideloaded onto an Android device via `adb install` or direct file transfer.

---

## 3. Caveats

1. **Host Environment Variables**: `JAVA_HOME` and `ANDROID_HOME` are not exported by default in the user's interactive shell profile (`~/.zshrc`). Any script or terminal running `./gradlew` must explicitly export them or define them before invocation.
2. **Release Signing**: The generated APK is a debug build (`app-debug.apk`) signed with the Android debug keystore. It is suitable for sideloading on personal Android devices, but not for Google Play distribution (which would require a production keystore and release signing configuration).
3. **Bluetooth Permissions on Real Devices**: The app requests `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, and location permissions. When sideloaded on Android 12+ devices, runtime permission prompts must be accepted by the user upon first launch.

---

## 4. Conclusion

The Android build environment and companion app project are fully operational:
- **Required JDK**: Java 21 LTS. Existing local path: `/Users/jacobloesch/Library/Application Support/minecraft/runtime/java-runtime-delta/mac-os-arm64/java-runtime-delta/jre.bundle/Contents/Home`.
- **Required SDK**: `/Users/jacobloesch/Library/Android/sdk`. Platform 36 and Build-Tools 35.0.0 are now fully installed and licenses accepted.
- **Project Readiness**: Gradle wrapper 8.14.3 and AGP 8.13.0 compile cleanly.
- **Artifact Verified**: The sideloadable debug APK has been built and verified at:
  `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk` (4.1 MB).

---

## 5. Verification Method

To independently verify the build environment and APK artifact:

1. **Verify JDK 21**:
   ```bash
   "/Users/jacobloesch/Library/Application Support/minecraft/runtime/java-runtime-delta/mac-os-arm64/java-runtime-delta/jre.bundle/Contents/Home/bin/java" -version
   "/Users/jacobloesch/Library/Application Support/minecraft/runtime/java-runtime-delta/mac-os-arm64/java-runtime-delta/jre.bundle/Contents/Home/bin/javac" -version
   ```
   *Expected output*: `openjdk version "21.0.3"`, `javac 21.0.3`.

2. **Verify Gradle Assemble Debug**:
   ```bash
   cd /Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/android
   JAVA_HOME="/Users/jacobloesch/Library/Application Support/minecraft/runtime/java-runtime-delta/mac-os-arm64/java-runtime-delta/jre.bundle/Contents/Home" \
   ANDROID_HOME="/Users/jacobloesch/Library/Android/sdk" \
   ./gradlew assembleDebug
   ```
   *Expected output*: `BUILD SUCCESSFUL`.

3. **Verify Generated APK Signature and Validity**:
   ```bash
   ls -la /Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk
   JAVA_HOME="/Users/jacobloesch/Library/Application Support/minecraft/runtime/java-runtime-delta/mac-os-arm64/java-runtime-delta/jre.bundle/Contents/Home" \
   PATH="$JAVA_HOME/bin:$PATH" \
   /Users/jacobloesch/Library/Android/sdk/build-tools/35.0.0/apksigner verify --verbose /Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk
   ```
   *Expected output*: `Verifies`, `Verified using v2 scheme (APK Signature Scheme v2): true`.

4. **Sideload Command (when device connected via USB with USB debugging enabled)**:
   ```bash
   /Users/jacobloesch/Library/Android/sdk/platform-tools/adb install -r /Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk
   ```
