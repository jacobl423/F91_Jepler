# Dispatch to Worker 5 (Milestone 5: Final Verification & E2E Test Suite)

## Objective
Implement the comprehensive end-to-end integration test suite in `Software/companion_app/tests/e2eIntegration.test.ts`, publish `TEST_READY.md`, and verify all project acceptance criteria per `ORIGINAL_REQUEST.md` and `PROJECT.md`.

## Mandatory Reading
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md`
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/PROJECT.md`
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/TEST_INFRA.md`
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m4/handoff.md`

## Mandatory Integrity Warning
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## Tasks & Scope
You exclusively own:
- `tests/e2eIntegration.test.ts`
- `/Users/jacobloesch/Documents/F91_Jepler/TEST_READY.md`
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/TEST_READY.md`

### Specifications:
1. **`tests/e2eIntegration.test.ts`**:
   - Implement end-to-end opaque-box integration tests spanning all 4 tiers:
     - Tier 1: Baseline feature flow (cold launch, driver selection, discovery filter for `F91_Jepler` and `fa35b2f0...`, connect, sequential GATT writes in exact order with responses, disconnect).
     - Tier 2: Boundary conditions (epoch 0, max uint32 epoch, negative timezone offsets, fractional timezones, rejection of invalid byte lengths).
     - Tier 3: Pairwise feature interactions (12h/24h x DST permutations, unexpected link drops during active sync steps, scan timeout recovery).
     - Tier 4: Real-world workload scenarios (complete user journey from discovery to watch LCD synchronization, consecutive time synchronizations, timezone shift handling, state resilience).
2. **`TEST_READY.md`**:
   - Document the test runner command (`npm test`), expected exit code 0, coverage summary table per tier, and acceptance criteria checklist.
3. **Verification**:
   - Run `npm test` and ensure 100% of all tests pass.
   - Run `npm run typecheck` (`tsc --noEmit`) and ensure 0 errors.
   - Run `npm run build` and ensure clean bundle in `dist/`.
   - Run `npx cap copy` and ensure clean sync to `android/` and `ios/`.
4. Write your handoff report to `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m5/handoff.md` and notify orchestrator when done.


## 2026-10-05T04:40:54Z
You are Worker 5 for Milestone 5 (Final Verification & E2E Test Suite).
Your task is defined in `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m5/DISPATCH.md`.

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

MANDATORY: You MUST read `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md`, `PROJECT.md`, `TEST_INFRA.md`, and `worker_m4/handoff.md`.

You exclusively own:
- `Software/companion_app/tests/e2eIntegration.test.ts`
- `/Users/jacobloesch/Documents/F91_Jepler/TEST_READY.md`
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/TEST_READY.md`

Implement the 4-tier E2E integration test suite, publish TEST_READY.md, and run all verification commands (`npm test`, `npm run typecheck`, `npm run build`, `npx cap copy`).
Write your handoff report to `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m5/handoff.md` and notify orchestrator when done.
