# Task Assignment: Empirical Verification & Adversarial Challenge 2 (M6 APK)

## Objective
Empirically test installation viability, compatibility with Android OS versions, simulation vs hardware BLE runtime behavior, and edge-case resilience of the F91_Jepler Android companion APK.

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
1. **Runtime Driver Selection Edge Cases**:
   - Check `App.tsx` driver initialization: what happens when `Capacitor.isNativePlatform()` is false (web dev server / unit tests)? What happens when true (Android APK)?
   - Verify that all 327 unit tests pass without breakage.
2. **Package & Intent Filter Validation**:
   - Verify Android package manager compatibility: inspect the compiled `AndroidManifest.xml` (via `aapt dump xmltree ... AndroidManifest.xml`).
   - Check whether `intent-filter` has action `android.intent.action.MAIN` and category `android.intent.category.LAUNCHER`.
   - Check whether `theme` exists in resources (`res/values/styles.xml`).
3. **Reproducibility of Sideloading Commands**:
   - Test `adb version` and formulate the precise installation command string (`adb install -r -t -g ...`).
   - Confirm whether all options (`-r`, `-t`, `-g`) are valid for standard Android Package Manager.
4. **Verdict**:
   - Conclude with an explicit verdict (`APPROVE` or `REJECT`).

## Output
Write your findings to:
`/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/challenger_m6_2/handoff.md`
Report back when complete.


## 2026-10-05T15:23:39Z
You are Challenger 2 for Milestone M6: Sideloadable Android APK Build & Verification.

Your working directory is:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/challenger_m6_2

Read your assigned task in:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/challenger_m6_2/DISPATCH.md
And you MUST read the original user request before starting work:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md

Empirically challenge:
- Runtime driver selection edge cases in App.tsx (native vs web vs test environments)
- Verify all 327 unit/integration tests pass cleanly
- Verify Android package manager compatibility (xmltree badging, launcher intent filter, styles/theme)
- Reproducibility of sideloading commands (adb install flags, manual transfer instructions)

Write your report with an explicit verdict (APPROVE or REJECT) to:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/challenger_m6_2/handoff.md
Send a message back when complete.
