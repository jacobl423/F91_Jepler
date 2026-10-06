# BRIEFING — 2026-10-05T05:10:00Z

## Mission
Survey the web build and Capacitor sync pipeline for the F91_Jepler mobile companion app to identify requirements and missing steps before building the APK.

## 🔒 My Identity
- Archetype: explorer
- Roles: explorer, synthesizer
- Working directory: /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/survey_apk_explorer_2
- Original parent: 73b327f6-797d-4e99-bde6-8417a8908ff9
- Milestone: survey_apk_and_native_sync

## 🔒 Key Constraints
- Read-only investigation — do NOT implement
- Focus on web build, dist/, Capacitor sync pipeline, native plugin integration, and pre-requisites for Gradle

## Current Parent
- Conversation ID: 73b327f6-797d-4e99-bde6-8417a8908ff9
- Updated: not yet

## Investigation State
- **Explored paths**:
  - `Software/companion_app/package.json`
  - `Software/companion_app/vite.config.ts`
  - `Software/companion_app/capacitor.config.ts`
  - `Software/companion_app/dist/`
  - `Software/companion_app/android/app/src/main/assets/public`
  - `Software/companion_app/android/settings.gradle`
  - `Software/companion_app/android/capacitor.settings.gradle`
  - `Software/companion_app/android/variables.gradle`
  - `Software/companion_app/android/build.gradle`
  - `Software/companion_app/android/app/build.gradle`
  - `Software/companion_app/android/app/capacitor.build.gradle`
  - `Software/companion_app/android/app/src/main/AndroidManifest.xml`
  - `node_modules/@capacitor-community/bluetooth-le/android/build.gradle`
  - `node_modules/@capacitor-community/bluetooth-le/android/src/main/AndroidManifest.xml`
  - `node_modules/@capacitor-community/bluetooth-le/android/src/main/java/com/capacitorjs/community/plugins/bluetoothle/BluetoothLe.kt`
- **Key findings**:
  - `npm run build` runs `tsc && vite build` and generates valid static assets in `dist/` in <500ms.
  - `npx cap sync android` successfully copies `dist/` into `android/app/src/main/assets/public`, creates `capacitor.config.json` and `capacitor.plugins.json`, and links `@capacitor-community/bluetooth-le` and `@capacitor/app` in 0.035s.
  - Native BLE plugin is properly registered with `BridgeActivity` and manifest permissions.
  - Gradle invocation blocker: System has no default Java in PATH. Android Studio's bundled JBR is OpenJDK 25.0.3 and Homebrew has OpenJDK 27, which fail Gradle 8.14.3 with `Unsupported class file major version 69` (Groovy/Gradle incompatible with Java 25+). Need JDK 21 (e.g. `brew install openjdk@21`).
  - Android SDK at `/Users/jacobloesch/Library/Android/sdk` has licenses accepted, but only platforms 33 and 34 installed; `variables.gradle` targets 36, which requires downloading platform 36 via Gradle or adjusting compileSdkVersion.
- **Unexplored areas**: None for this survey scope.

## Key Decisions Made
- Confirmed web build and Capacitor sync pipeline are fully operational and require zero code fixes.
- Documented clear prerequisites for the Gradle builder (JDK 21 requirement).

## Artifact Index
- DISPATCH.md — Dispatch instructions
- BRIEFING.md — Situational awareness
- progress.md — Liveness heartbeat
- handoff.md — Final structured report
