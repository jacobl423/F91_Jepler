# Dispatch to E2E Test Writer (E2E Testing Track)

## Objective
Design and implement the automated E2E test suite across Tiers 1-4 for the F91_Jepler mobile companion app per `TEST_INFRA.md` and `ORIGINAL_REQUEST.md`.

## Mandatory Reading
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md`
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/PROJECT.md`
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/TEST_INFRA.md`
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/survey_explorer_1/handoff.md`
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/survey_explorer_3/handoff.md`

## Mandatory Integrity Warning
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A teamwork_preview_auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## Tasks & Scope
1. Review the test case requirements across all 4 Tiers:
   - Tier 1: Feature Coverage (Serialization for Time, TZ, Mode, DST; Scan filtering; State Machine states; Sequential sync execution; UI feedback)
   - Tier 2: Boundary & Corner Cases (Epoch 0, Max Uint32, Negative/Half-hour/Large TZ offsets, invalid lengths, long writes rejection)
   - Tier 3: Pairwise Combinations (Mode x DST pairs, disconnect during sync, timeout recovery)
   - Tier 4: Real-World Scenarios (Full cold-start sync cycle, reconnection, state persistence)
2. Create modular test suites in `Software/companion_app/tests/`:
   - `tests/serialization.test.ts`
   - `tests/stateMachine.test.ts`
   - `tests/mockBleService.test.ts`
   - `tests/e2eIntegration.test.ts`
   (Note: wait until M1 creates `Software/companion_app` or create standalone test definitions ready to run with Vitest).
3. Validate tests run cleanly once the corresponding components are implemented.
4. Publish `TEST_READY.md` summarizing test counts and coverage per tier when complete.
5. Write your report to `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/test_writer_e2e/handoff.md`.
