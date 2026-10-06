# Task Assignment: Survey Web Build & Capacitor Android Sync Pipeline

## Objective
Investigate the web build and Capacitor sync pipeline for the F91_Jepler mobile companion app to ensure all modern web assets, Bluetooth Low Energy native plugins, and Android configurations are properly synced before building the APK.

## Context
- Project Root: `/Users/jacobloesch/Documents/F91_Jepler`
- Companion App Root: `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app`
- Android Project Directory: `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/android`
- Original Request: `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md`

## Specific Investigation Items
1. Inspect `package.json`, `capacitor.config.ts`, `vite.config.ts` in `Software/companion_app`.
2. Check `npm run build` output and `dist/` folder contents.
3. Check Capacitor sync workflow (`npx cap sync android` / `npx cap copy android`).
4. Check how plugins (specifically `@capacitor-community/bluetooth-le` or other BLE plugins) are linked into `Software/companion_app/android`.
   - Inspect `android/app/src/main/assets/public` (does it exist or is it populated by cap sync?).
   - Inspect `android/capacitor.settings.gradle` and plugin dependencies in `android/app/build.gradle`.
5. Identify any potential issues or missing sync steps before running Gradle build.

## Output
Write your findings and recommendations to `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/survey_apk_explorer_2/handoff.md`.
Report back when complete.


## 2026-10-05T05:04:56Z
You are the Capacitor Android Sync Explorer for surveying the web build and native sync pipeline for the F91_Jepler mobile companion app.

Your working directory is:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/survey_apk_explorer_2

Read your assigned task in:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/survey_apk_explorer_2/DISPATCH.md
And you MUST read the original user request before starting work:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md

Investigate:
1. Software/companion_app web build (package.json, vite.config.ts, capacitor.config.ts).
2. The current state of dist/ and whether npm run build generates all necessary web assets.
3. The Capacitor sync pipeline (npx cap sync android) and how it bundles web assets into android/app/src/main/assets/public.
4. Native plugin integration in android/, especially @capacitor-community/bluetooth-le.
5. Identify any missing steps or pre-requisites before invoking Gradle.

Document your verified findings and write your structured report to /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/survey_apk_explorer_2/handoff.md.
Send a message back when complete.
