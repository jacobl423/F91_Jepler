# Task Assignment: Empirical Verification & Adversarial Challenge 1 (M6 APK)

## Objective
Empirically challenge and stress-test the generated Android APK artifact (`Software/companion_app/F91_Jepler-companion-debug.apk` and `Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk`) for correctness, integrity, and runtime viability.

## Context & Inputs
- Project Root: `/Users/jacobloesch/Documents/F91_Jepler`
- Companion App Root: `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app`
- Android Project Directory: `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/android`
- Original User Request: `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md`
- Project Index & Scope:
  - `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/PROJECT.md`
  - `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/orchestrator_apk/SCOPE.md`
- Worker Handoff:
  - `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m6/handoff.md`

## Adversarial Challenge Tasks
1. **Bytecode & Archive Structure Challenge**:
   - Verify the APK archive is not corrupted or truncated.
   - Verify that all DEX files (`classes.dex` through `classes8.dex`) contain actual compiled classes (e.g. use `dexdump` or verify class headers).
   - Check that `assets/public/` contains the actual bundled web code (`index.html`, `index-*.js`, `index-*.css`) matching `Software/companion_app/dist`.
2. **Signature & Security Scheme Challenge**:
   - Run `apksigner verify --verbose` using JDK 21. Verify whether APK Signature Scheme v2 is valid and whether any tampering with files invalidates the signature.
   - Verify `zipalign -c -v 4` confirms strict 4-byte alignment.
3. **Manifest & Permission Invariants**:
   - Verify `aapt dump badging` returns valid `package: name='com.f91jepler.companion'`.
   - Verify launchable activity `com.f91jepler.companion.MainActivity` has `android:exported="true"`.
   - Verify `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, and location permissions exist.
4. **Verdict**:
   - Provide an explicit verdict (`APPROVE` or `REJECT`) based on empirical test results.

## Output
Write your findings to:
`/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/challenger_m6_1/handoff.md`
Report back when complete.

## 2026-10-05T15:23:39Z
You are Challenger 1 for Milestone M6: Sideloadable Android APK Build & Verification.

Your working directory is:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/challenger_m6_1

Read your assigned task in:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/challenger_m6_1/DISPATCH.md
And you MUST read the original user request before starting work:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md

Empirically challenge:
- Bytecode and archive structure of the generated APK (dexdump/dex checks, assets/public/ contents)
- Signature & security scheme checks with apksigner
- Strict 4-byte zip alignment check with zipalign
- Manifest & permission invariants with aapt

Write your report with an explicit verdict (APPROVE or REJECT) to:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/challenger_m6_1/handoff.md
Send a message back when complete.
