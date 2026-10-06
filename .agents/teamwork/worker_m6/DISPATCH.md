# Task Assignment: Build and Verify Sideloadable Android APK (M6)

## Objective
Build the F91_Jepler mobile companion app into a sideloadable Android APK (`app-debug.apk`), verify the generated artifact with Android SDK tools, and document complete sideloading instructions for the user.

## Context & Inputs
- Project Root: `/Users/jacobloesch/Documents/F91_Jepler`
- Companion App Root: `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app`
- Android Project Directory: `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/android`
- Original User Request: `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md`
- Project Architecture & Scope:
  - `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/PROJECT.md`
  - `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/orchestrator_apk/SCOPE.md`
- Survey Reports:
  - `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/survey_apk_explorer_1/handoff.md`
  - `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/survey_apk_explorer_2/handoff.md`
  - `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/survey_apk_spec_miner/handoff.md`

## Toolchain & Environment Configuration
- **Java Runtime**: Use OpenJDK 21 LTS located at:
  `/Users/jacobloesch/Library/Application Support/minecraft/runtime/java-runtime-delta/mac-os-arm64/java-runtime-delta/jre.bundle/Contents/Home`
- **Android SDK**:
  `export ANDROID_HOME="/Users/jacobloesch/Library/Android/sdk"`
  `export PATH="$ANDROID_HOME/build-tools/35.0.0:$ANDROID_HOME/platform-tools:$PATH"`

## File Ownership
- Primary source files:
  - `Software/companion_app/src/App.tsx` (Default to hardware BLE driver if `Capacitor.isNativePlatform()` is true, while preserving simulation toggle).
  - Any necessary Android config or build scripts in `Software/companion_app/android` or `Software/companion_app`.

## Execution Steps
1. **Source Code Adjustment**:
   - Check `Software/companion_app/src/App.tsx`. If running on a native platform (`Capacitor.isNativePlatform()`), initialize the driver to `hardware` by default so users on an Android phone immediately use real Bluetooth without having to manually switch modes. Keep the toggle available for testing.
2. **Verification of Existing Tests**:
   - Run `npm test` in `Software/companion_app` to ensure all 325 existing unit/integration tests pass.
3. **Web Asset Build**:
   - Run `npm run build` in `Software/companion_app` to compile the production bundle into `dist/`.
4. **Capacitor Sync**:
   - Run `npx cap sync android` in `Software/companion_app` to copy web assets to `android/app/src/main/assets/public` and sync native plugin bridges.
5. **Gradle Build**:
   - In `Software/companion_app/android`, run:
     ```bash
     JAVA_HOME="/Users/jacobloesch/Library/Application Support/minecraft/runtime/java-runtime-delta/mac-os-arm64/java-runtime-delta/jre.bundle/Contents/Home" \
     ANDROID_HOME="/Users/jacobloesch/Library/Android/sdk" \
     ./gradlew assembleDebug
     ```
6. **Artifact Placement & Validation**:
   - Target APK path: `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk`
   - Copy or make accessible as `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/F91_Jepler-companion-debug.apk` for easy user access.
   - Run full verification checks on the generated APK:
     - `file` command
     - `unzip -l` confirming `classes.dex`, `AndroidManifest.xml`, `assets/public/index.html`
     - `aapt dump badging` verifying `package: name='com.f91jepler.companion'`, launchable activity `MainActivity`, permissions `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `ACCESS_FINE_LOCATION`
     - `zipalign -c -v 4` verifying 4-byte alignment
     - `apksigner verify --verbose` verifying APK Signature Scheme v2
7. **Sideloading Instructions**:
   - Document clear, step-by-step instructions for:
     a) Direct ADB install: `adb install -r -t -g <apk_path>` and launch `adb shell am start -n com.f91jepler.companion/.MainActivity`
     b) Manual file transfer to Android device (download/transfer, enable "Install unknown apps", proceed past Play Protect self-signed dialog).

## Output
Write your comprehensive handoff report to:
`/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m6/handoff.md`
Report back when complete.


## 2026-10-05T05:13:59Z
[Message] timestamp=2026-10-05T05:13:59Z sender=73b327f6-797d-4e99-bde6-8417a8908ff9 priority=MESSAGE_PRIORITY_HIGH content=You are the Worker for Milestone M6: Sideloadable Android APK Build & Verification.

Your working directory is:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m6

Read your assigned task and instructions in:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m6/DISPATCH.md
And you MUST read the original user request before starting work:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

Follow the instructions in DISPATCH.md:
1. Ensure App.tsx initializes to hardware BLE mode if Capacitor.isNativePlatform() is true.
2. Run npm test to verify all tests pass.
3. Run npm run build and npx cap sync android.
4. Execute ./gradlew assembleDebug with JDK 21 and Android SDK environment variables.
5. Verify the generated APK artifact using file, unzip, aapt, zipalign, and apksigner. Also create a convenient top-level copy at Software/companion_app/F91_Jepler-companion-debug.apk.
6. Provide exact sideloading commands and instructions.

Write your report to:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m6/handoff.md
Send a message back when complete.
