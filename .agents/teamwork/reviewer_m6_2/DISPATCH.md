# Task Assignment: Independent Review 2 of Milestone M6 (Sideloadable Android APK)

## Objective
Independently review the work performed for Milestone M6: Sideloadable Android APK Build & Verification.
Focus on adversarial review, edge cases, Android permission models across versions (Android 6–11 vs Android 12+), keystore validity, offline functionality of web assets inside the APK, and package manager compatibility.

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
1. Independent Verification:
   - Check the code diff in `Software/companion_app/src/App.tsx`.
   - Run `npm test` and `npm run typecheck`.
   - Verify web assets inside the APK (`unzip -p ... assets/public/index.html | head`).
   - Check `AndroidManifest.xml` within the APK (`aapt dump xmltree ... AndroidManifest.xml` or `aapt dump permissions ...`).
2. Robustness & Permission Evaluation:
   - Verify `BLUETOOTH_SCAN` has `neverForLocation` flag or location permissions are properly paired.
   - Verify `android:exported="true"` is on `MainActivity` for Android 12+ compliance.
   - Verify `minSdkVersion` is 24 and `targetSdkVersion` is 36.
3. APK Signature & Alignment:
   - Verify `apksigner verify --verbose` and certificate details.
   - Check `zipalign -c -v 4`.
4. Verdict:
   - Explicitly conclude with `APPROVE` or `REQUEST_CHANGES`.

## Output
Write your comprehensive review and explicit verdict to:
`/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/reviewer_m6_2/handoff.md`
Report back when complete.

## 2026-10-05T15:23:39Z
You are Reviewer 2 for Milestone M6: Sideloadable Android APK Build & Verification.

Your working directory is:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/reviewer_m6_2

Read your assigned task in:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/reviewer_m6_2/DISPATCH.md
And you MUST read the original user request before starting work:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md

Independently review:
- Adversarial review of permission models across Android versions (Android 6-11 vs 12+)
- Check exported flag on MainActivity
- Run npm test and npm run typecheck
- Verify web assets bundled inside the APK
- Verify signature and 4-byte zip alignment
- Review sideloading documentation

Write your report with an explicit verdict (APPROVE or REQUEST_CHANGES) to:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/reviewer_m6_2/handoff.md
Send a message back when complete.
