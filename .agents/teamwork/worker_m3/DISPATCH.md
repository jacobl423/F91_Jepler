# Dispatch to Worker 3 (Milestone 3: State Machine & Sequential Sync Service)

## Objective
Implement the reactive Connection State Machine, Clock Synchronization Service, and React integration hook in `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app`.

## Mandatory Reading
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md`
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/PROJECT.md`
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/survey_explorer_3/handoff.md`
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m2/handoff.md`

## Mandatory Integrity Warning
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## Tasks & Scope
You exclusively own:
- `src/state/connectionStateMachine.ts`
- `src/state/syncService.ts`
- `src/state/useBleConnection.ts`
- `tests/stateMachine.test.ts`
- `tests/syncService.test.ts`

### Specifications:
1. **`connectionStateMachine.ts`**:
   - Accurately model all states: `DISCONNECTED`, `SCANNING`, `CONNECTING`, `CONNECTED`, `SYNCING`, `ERROR`.
   - Implement clean transitions for: `START_SCAN`, `STOP_SCAN`, `DEVICE_FOUND`, `SELECT_DEVICE`, `CONNECT_SUCCESS`, `CONNECT_FAILURE`, `DISCONNECT`, `START_SYNC`, `SYNC_SUCCESS`, `SYNC_FAILURE`, `CLEAR_ERROR`.
   - Prevent invalid transitions and unhandled exceptions on disconnection.
2. **`syncService.ts`**:
   - Implement sequential GATT write execution:
     `write Time -> write Timezone -> write TimeMode -> write DST` with write acknowledgment.
   - Guard against disconnection during active sync.
   - Return structured sync summary (synced timestamp, local time, offset, mode, DST).
3. **`useBleConnection.ts`**:
   - Reactive hook integrating state machine, `BleClientInterface` (supporting both `MockBleService` and `CapacitorBleService`), device discovery list, connection status, and manual sync action.
4. **Tests**:
   - `tests/stateMachine.test.ts`: Verify all state transitions, invalid transition handling, and error recovery.
   - `tests/syncService.test.ts`: Verify sequential write sequence against `MockBleService`, disconnect handling during sync, and sync result validation.
5. Verify `npm test`, `npm run typecheck`, and `npm run build` pass cleanly with 100% success rate.

Write your handoff report to `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m3/handoff.md` and notify orchestrator when done.


## 2026-10-05T04:08:45Z
You are Worker 3 for Milestone 3 (State Machine & Sequential Sync Service).
Your task is defined in `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m3/DISPATCH.md`.

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

MANDATORY: You MUST read `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md`, `PROJECT.md`, `survey_explorer_3/handoff.md`, and `worker_m2/handoff.md`.

You exclusively own in `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app`:
- `src/state/connectionStateMachine.ts`
- `src/state/syncService.ts`
- `src/state/useBleConnection.ts`
- `tests/stateMachine.test.ts`
- `tests/syncService.test.ts`

Implement the 6-state connection state machine, the sequential GATT Clock sync service, and the useBleConnection React hook.
Write comprehensive unit tests in tests/stateMachine.test.ts and tests/syncService.test.ts.
Verify `npm test`, `npm run typecheck`, and `npm run build` execute cleanly with 100% pass rate.

Write your handoff report to `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m3/handoff.md` and notify orchestrator when done.
