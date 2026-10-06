# Dispatch to Challenger M2

## Objective
Empirical challenge and adversarial testing of Milestone 2 (BLE Engine & GATT Serialization Core) in `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app`.

## Mandatory Reading
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md`
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/PROJECT.md`
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m2/handoff.md`

## Challenge Instructions
1. Test serialization edge cases: epoch 0, maximum uint32 (`0xFFFFFFFF`), negative timezone offsets, fractional timezones (e.g. UTC+5:30 = 330 min, UTC+5:45 = 345 min, UTC-3:30 = -210 min), invalid payload lengths (0 bytes, 3 bytes, 5 bytes).
2. Test `MockBleService` fault injection and write sequence verification.
3. Run `npm test`, `npm run typecheck`, and `npm run build`.
4. Issue an explicit verdict: APPROVE or CHALLENGE_FAILED.
5. Write your handoff to `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/challenger_m2/handoff.md` and notify orchestrator.

## 2026-10-05T04:00:06Z
You are Challenger M2.
Your task is defined in `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/challenger_m2/DISPATCH.md`.
Read `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md`, `PROJECT.md`, and `worker_m2/handoff.md`.
Adversarially challenge Milestone 2 serialization edge cases, fault injection in MockBleService, and little-endian representation.
Run `npm test`, `npm run typecheck`, and `npm run build`.
Issue an explicit verdict: APPROVE or CHALLENGE_FAILED.
Write your handoff to `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/challenger_m2/handoff.md` and send a message when done.
