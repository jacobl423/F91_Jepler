# Progress — Challenger M6-1

Last visited: 2026-10-05T15:35:00Z

## Current Status
Completed empirical challenges across bytecode structure, DEX analysis, asset parity, cryptographic signatures & tamper tests, 4-byte zipalign verification, and AndroidManifest badging/permissions. Preparing handoff report.

## Steps
- [x] Step 1: Initialize DISPATCH.md, BRIEFING.md, and progress.md
- [x] Step 2: Verify APK file existence, size, archive integrity, and equality between output locations
  - Both APKs exist and share identical SHA-256 (`14dc371c...df928`), 4,314,108 bytes (~4.3 MB).
  - Unzip integrity test passed with 0 errors across 447 entries.
- [x] Step 3: Bytecode & DEX analysis (dexdump/dex checks across classes.dex to classes8.dex)
  - 8 valid DEX files (`classes.dex` through `classes8.dex`), all DEX v037.
  - Verified Adler32 checksums, SHA-1 signatures, and class definitions for all 8 files.
  - Located `MainActivity` in `classes8.dex` (extends `BridgeActivity`).
  - Located `BluetoothLe` in `classes2.dex` (extends `Plugin`).
- [x] Step 4: Asset verification: match assets/public/ in APK to Software/companion_app/dist/
  - All files (`index.html`, `index-_qkASCwR.css`, `index-RPmAMwiC.js`, `web-gq334oLb.js`) match `dist/` bit-for-bit with matching SHA-256.
  - Confirmed presence of F91_Jepler GATT UUIDs and `isNativePlatform` logic in bundled JS.
- [x] Step 5: Android Asset Packaging Tool (aapt) dump badging & manifest invariants check
  - `package: name='com.f91jepler.companion'`, versionCode='1', versionName='1.0'.
  - `minSdkVersion='24'`, `targetSdkVersion='36'`.
  - `MainActivity` has `android:exported="true"`, MAIN and LAUNCHER intents.
  - Required permissions confirmed: `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`.
- [x] Step 6: Alignment check (zipalign -c -v 4)
  - `zipalign -c -v 4` exited with code 0 on both APK files.
  - Verified all 221 uncompressed entries start at 4-byte aligned offsets. Adversarial shifted/corrupted tests failed as expected.
- [x] Step 7: Signature verification & tamper testing (apksigner verify --verbose, tamper test)
  - `apksigner verify --verbose` verified Signature Scheme v2 (Debug Key: CN=Android Debug).
  - Adversarial bit-flip in APK payload triggered `CHUNKED_SHA256 digest mismatch` (exit code 1).
  - Adversarial ZIP entry injection triggered `Missing META-INF/MANIFEST.MF` (exit code 1).
- [ ] Step 8: Compile findings into handoff.md with APPROVE/REJECT verdict
- [ ] Step 9: Notify parent agent
