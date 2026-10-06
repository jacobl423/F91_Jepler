# Task Assignment: Independent Review 1 of Milestone M6 (Sideloadable Android APK)

## Objective
Independently review the work performed for Milestone M6: Sideloadable Android APK Build & Verification.
Evaluate correctness, completeness, robustness, interface conformance, and verify that the generated APK artifact is valid, properly signed, contains all web assets and DEX bytecode, and is ready for sideloading.

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

## Review Verification Requirements
1. Code Inspection:
   - Check changes in `Software/companion_app/src/App.tsx` and `tests/uiComponents.test.tsx`.
   - Verify that native platform default driver selection logic is robust and doesn't break web or test environments.
2. Build & Test Verification:
   - Run `npm test` in `Software/companion_app` to verify all tests pass.
   - Run `npm run build` in `Software/companion_app`.
   - Verify Gradle build and APK generation.
3. APK Artifact Verification:
   - Verify existence and integrity of `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/F91_Jepler-companion-debug.apk` and `Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk`.
   - Inspect package name (`com.f91jepler.companion`), target SDK (36), launchable activity (`MainActivity`), and BLE permissions using `aapt dump badging`.
   - Verify 4-byte zip alignment using `zipalign -c -v 4`.
   - Verify cryptographic signature using `apksigner verify --verbose`.
4. Sideloading Instructions Review:
   - Verify that instructions for both ADB install and manual device transfer are complete and accurate.

## Output
Write your comprehensive review and explicit verdict (`APPROVE` or `REQUEST_CHANGES`) to:
`/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/reviewer_m6_1/handoff.md`
Report back when complete.


## 2026-10-05T15:23:39Z
[Message] timestamp=2026-10-05T15:23:39Z sender=73b327f6-797d-4e99-bde6-8417a8908ff9 priority=MESSAGE_PRIORITY_HIGH
You are Reviewer 1 for Milestone M6: Sideloadable Android APK Build & Verification.

Your working directory is:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/reviewer_m6_1

Read your assigned task in:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/reviewer_m6_1/DISPATCH.md
And you MUST read the original user request before starting work:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md

Independently review:
- Code changes in App.tsx and tests
- Run npm test in Software/companion_app
- Verify Gradle build and generated APKs:
  Software/companion_app/android/app/build/outputs/apk/debug/app-debug.apk
  Software/companion_app/F91_Jepler-companion-debug.apk
- Inspect package name, target SDK, launchable activity, and BLE permissions with aapt
- Verify alignment with zipalign and signature with apksigner
- Review sideloading instructions

Write your report with an explicit verdict (APPROVE or REQUEST_CHANGES) to:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/reviewer_m6_1/handoff.md
Send a message back when complete.
