# Sentinel Handoff Report — Sideloadable Android APK Build & Verification

**Date**: 2026-10-05T16:01:00Z  
**Author**: Sentinel (`dcc6dc86-67e4-412a-a005-19ee22f8fdfb`)  
**Workspace**: `/Users/jacobloesch/Documents/F91_Jepler`  
**Target Path**: `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app`  
**Victory Audit Verdict**: **VICTORY CONFIRMED**

---

## 1. Observation

1. **User Request**:
   - The user requested: "Make it into an apk I can side load on my android".
   - Recorded verbatim to `ORIGINAL_REQUEST.md`.
2. **Execution Milestones**:
   - Routed to General path and orchestrated under milestone M6.
   - Built Android APK via Gradle 8.14.3 (`./gradlew assembleDebug`) and OpenJDK 21 LTS using Android SDK Build-Tools 35.0.0.
   - Automatically engaged the native hardware BLE driver when running on Android (`Capacitor.isNativePlatform()`).
   - Produced two identical, signed APK artifacts:
     - `Software/companion_app/F91_Jepler-companion-debug.apk` (convenience top-level artifact)
     - `Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk` (Gradle output artifact)
   - Both artifacts share SHA-256: `14dc371c3e8e5394ca981d3258bc30d1fcb524d5f728b9eca0b19ad371bdf928` (4,314,108 bytes).
3. **Independent Verification**:
   - Independent Victory Auditor (`3da839f0-2dd5-49fe-8977-7c2c43c2bf97`) performed blocking post-victory audit.
   - Verdict: **VICTORY CONFIRMED**.
   - Verified 4-byte zip alignment (`zipalign -c -v 4` code 0), APK Signature Scheme v2 validity via `apksigner`, 8 valid Dalvik 037 DEX archives, offline web assets with all 5 GATT UUIDs, manifest package `com.f91jepler.companion`, launchable `MainActivity`, and runtime BLE permissions (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `ACCESS_FINE_LOCATION`).
   - 327 of 327 automated unit and integration tests executed with 100% pass rate.

---

## 2. Logic Chain

1. **Sideload Target Selection**:
   - Debug APK compilation (`assembleDebug`) was selected because it signs the package with the standard Android debug keystore. This allows immediate installation on any Android device without requiring custom self-signed production certificates.
2. **Hardware BLE Auto-Selection**:
   - On physical Android devices (`Capacitor.isNativePlatform() === true`), the app automatically selects `CapacitorBleService` while retaining manual UI toggle to simulated mode.
3. **Reproducibility & Offline Autonomy**:
   - The compiled APK embeds all production web assets locally into `assets/public/` within the APK, requiring zero network calls or CDN access at runtime.

---

## 3. Caveats

1. **Google Play Protect Warning**:
   - Because debug APKs use the standard Android developer debug keystore, Google Play Protect will flag the application as "Unrecognized app" when sideloading manually. Users should select "More details" -> "Install anyway".
2. **Android Runtime Permissions**:
   - On Android 12+ (API 31+), the app prompts for "Nearby devices" (`BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT`) and Location. These must be approved by the user to discover the F91_Jepler smartwatch.

---

## 4. Conclusion

The F91_Jepler mobile companion application has been compiled into a ready-to-sideload Android APK, verified across all binary and structural criteria, and passed independent post-victory audit.

---

## 5. Verification & Sideloading Method

### Sideload Option A: Direct Install via ADB (Fastest)
```bash
/Users/jacobloesch/Library/Android/sdk/platform-tools/adb install -r -t -g /Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/F91_Jepler-companion-debug.apk
/Users/jacobloesch/Library/Android/sdk/platform-tools/adb shell am start -n com.f91jepler.companion/.MainActivity
```

### Sideload Option B: Manual Device Transfer
1. Transfer `Software/companion_app/F91_Jepler-companion-debug.apk` to phone.
2. Open Files app, tap the APK, and enable "Install unknown apps" if prompted.
3. Tap "More details" -> "Install anyway" on Google Play Protect prompt.
4. Launch the F91_Jepler app and allow Bluetooth permissions.
