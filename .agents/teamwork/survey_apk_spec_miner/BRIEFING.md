# BRIEFING — 2026-10-05T05:13:00Z

## Mission
Survey, discover, and document the specifications, requirements, and verification tooling for building a sideloadable Android APK for F91_Jepler.

## 🔒 My Identity
- Archetype: Specification Miner
- Roles: APK Sideload Spec Miner, Teamwork specialist
- Working directory: /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/survey_apk_spec_miner
- Original parent: 73b327f6-797d-4e99-bde6-8417a8908ff9
- Milestone: M1 / APK Exploration & Specification Survey

## 🔒 Key Constraints
- Do NOT implement anything — read-only specification mining.
- Probe authoritative specifications (manifest, build configurations, gradle, SDK tools).
- Enumerate full interfaces, permissions, sideloading requirements, verification tooling, and edge cases.
- Write findings to handoff.md in working directory.
- Send completion message to parent via send_message.

## Current Parent
- Conversation ID: 73b327f6-797d-4e99-bde6-8417a8908ff9
- Updated: 2026-10-05T05:13:00Z

## Task Summary
- **What to build**: Specification report on APK sideloading requirements, AndroidManifest configuration, signing, verification tools, and user sideloading procedures.
- **Success criteria**: Exhaustive, verified specifications documenting permissions, intent filters, APK packaging/signing differences, SDK inspection tools, step-by-step sideload workflows, and edge cases.
- **Interface contracts**: /Users/jacobloesch/Documents/F91_Jepler/Software/companion_app/android/app/src/main/AndroidManifest.xml and related Gradle/Android configs.
- **Code layout**: /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/PROJECT.md

## Key Decisions Made
- Confirmed `com.f91jepler.companion` and `MainActivity` with `android:exported="true"`.
- Verified debug APK is optimal sideloading target due to automatic signing via `~/.android/debug.keystore` (verified valid to 2053 with 2048-bit RSA) and remote debuggability.
- Tested native inspection tools (`aapt`, `aapt2`, `apksigner`, `zipalign`, `unzip`, `file`, `adb`).
- Documented edge cases including Java 25 compatibility with Gradle and JAXB removal affecting legacy `apkanalyzer`.

## Artifact Index
- DISPATCH.md — Task assignment and instructions
- progress.md — Liveness heartbeat and task execution log
- handoff.md — Comprehensive findings, 25 discovered features, 8 edge cases, observations, logic chain, caveats, and verification methods
