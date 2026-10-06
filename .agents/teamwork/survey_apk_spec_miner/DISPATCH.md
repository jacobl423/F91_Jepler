# Task Assignment: Sideloading Specifications & Verification Criteria

## Objective
Investigate specifications and requirements for building a sideloadable Android APK for F91_Jepler, including permissions, signing requirements, artifact verification tools, and user sideloading procedures.

## Context
- Project Root: `/Users/jacobloesch/Documents/F91_Jepler`
- Companion App Root: `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app`
- Android Project Directory: `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/android`
- Original Request: `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md`

## Specific Investigation Items
1. Inspect `AndroidManifest.xml` in `android/app/src/main/AndroidManifest.xml`:
   - Package ID / applicationId (`com.f91jepler.companion` or similar).
   - BLE permissions (BLUETOOTH, BLUETOOTH_ADMIN, BLUETOOTH_SCAN, BLUETOOTH_CONNECT, ACCESS_FINE_LOCATION).
   - Launchable activity declaration (`MainActivity` with `android.intent.action.MAIN` and `android.intent.category.LAUNCHER`).
2. Sideloading requirements:
   - Why a debug APK (signed automatically with Android standard debug keystore) is the standard and most reliable target for direct sideloading.
   - Or what is needed if a release APK is generated (keystore, zipalign, apksigner).
3. APK verification tooling available in the system:
   - Check availability of `aapt`, `aapt2`, `apkanalyzer`, `apksigner`, `keytool`, `unzip`, `file`.
   - Formulate exact verification commands to prove the generated APK is valid, signed, contains DEX files, assets, manifest, and is ready for sideloading.
4. Step-by-step sideloading instructions for the end-user (e.g. `adb install -r <apk_path>`, or downloading/transferring via USB/file manager and enabling "Install unknown apps").

## Output
Write your findings to `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/survey_apk_spec_miner/handoff.md`.
Report back when complete.

## 2026-10-05T05:04:56Z
You are the APK Sideload Spec Miner for surveying the specifications, requirements, and verification tooling for building a sideloadable Android APK for F91_Jepler.

Your working directory is:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/survey_apk_spec_miner

Read your assigned task in:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/survey_apk_spec_miner/DISPATCH.md
And you MUST read the original user request before starting work:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md

Investigate:
1. AndroidManifest.xml in Software/companion_app/android/app/src/main/AndroidManifest.xml: application ID, launchable MainActivity, Bluetooth permissions (BLUETOOTH_SCAN, BLUETOOTH_CONNECT, ACCESS_FINE_LOCATION, etc.).
2. Sideloading specifications: debug APK vs release APK, signing requirements, why debug APK is ideal for sideloading (signed with debug key, installable immediately).
3. System tools for APK verification (aapt, aapt2, apkanalyzer, apksigner, unzip, file, etc.).
4. Clear sideloading steps and instructions for an end user (adb install, manual file transfer).

Document your verified specifications and write your structured report to /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/survey_apk_spec_miner/handoff.md.
Send a message back when complete.
