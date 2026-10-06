# BRIEFING — 2026-10-05T03:13:30Z

## Mission
Discover and document all firmware BLE characteristics, UUIDs, data layouts, endianness, timing logic, and constraints for F91_Jepler.

## 🔒 My Identity
- Archetype: Specification Miner
- Roles: Teamwork specialist, external domain expert
- Working directory: /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/survey_explorer_1
- Original parent: 597ea6c0-a703-4980-a746-5cc67a9a63e2
- Milestone: Survey & Spec Mining

## 🔒 Key Constraints
- Read-only: Do NOT implement anything
- Discover and document features by probing authoritative specification sources
- Probe ALL discovered features thoroughly (typical usage, edge cases, error behavior)
- Adhere to Teamwork file workspace rules (only write to /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/survey_explorer_1)
- Communicate via send_message to parent (597ea6c0-a703-4980-a746-5cc67a9a63e2)

## Current Parent
- Conversation ID: 597ea6c0-a703-4980-a746-5cc67a9a63e2
- Updated: 2026-10-05T03:08:48Z

## Task Summary
- **What to build**: Authoritative BLE Clock Service specification mining report for F91_Jepler companion app development.
- **Success criteria**: Comprehensive handoff report with exact UUIDs, payload layouts, endianness, write sequences, constraints, and edge cases.
- **Interface contracts**: /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md
- **Code layout**: /Users/jacobloesch/Documents/F91_Jepler

## Key Decisions Made
- Confirmed authoritative active firmware is Zephyr RTOS on nRF52840 (`Firmware/zephyr`), maintaining exact backward-compatible 128-bit UUIDs and layouts from legacy CC2640 (`Firmware/f91_kepler_app`).
- Clarified timezone offset encoding: 2-byte signed integer (minutes from UTC, e.g. -300 for EST) packed little-endian as uint16 bit-pattern (`0xD4, 0xFE`), matching both `ClockSyncPayload` in macOS app and `ORIGINAL_REQUEST.md`.
- Documented full discovery of Notification Service (`fa35a2f0...`), Battery Service (`0x180F`), and SMP DFU over BLE.

## Artifact Index
- /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/survey_explorer_1/handoff.md — Complete spec mining findings and handoff report
- /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/survey_explorer_1/progress.md — Liveness heartbeat and progress log
- /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/survey_explorer_1/DISPATCH.md — Task assignment and message log
