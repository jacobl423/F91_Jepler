# Dispatch to Worker 4 (Milestone 4: User Interface & Visual Synchronization Panel)

## Objective
Implement the complete mobile user interface and visual synchronization panel in `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app` per `PROJECT.md` and `ORIGINAL_REQUEST.md`.

## Mandatory Reading
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md`
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/PROJECT.md`
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m3/handoff.md`

## Mandatory Integrity Warning
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## Tasks & Scope
You exclusively own:
- `src/components/DeviceDiscovery.tsx`
- `src/components/ConnectionStatusBadge.tsx`
- `src/components/ClockSyncPanel.tsx`
- `src/components/MockWatchPreview.tsx`
- `src/App.tsx`
- `src/App.css`
- `tests/uiComponents.test.tsx`

### Specifications:
1. **`DeviceDiscovery.tsx`**:
   - Allows users to scan for nearby watches, inspect found devices (`F91_Jepler`), initiate connect/disconnect actions, observe RSSI/signal strength.
2. **`ConnectionStatusBadge.tsx`**:
   - Renders live connection state (`disconnected`, `scanning`, `connecting`, `connected`, `syncing`, `error`) with distinct visual indicators and device info.
3. **`ClockSyncPanel.tsx`**:
   - Dedicated manual time synchronization button with visual feedback.
   - Live local system clock display, timezone offset, 12h/24h toggle, and DST status.
   - Visual progress bar and "Last Synced" timestamp display showing successful sync.
4. **`MockWatchPreview.tsx`**:
   - Visual F-91W inspired digital LCD display panel reflecting simulated watch registers when using `MockBleService`.
5. **`App.tsx` & `App.css`**:
   - Mobile-optimized layout, clean responsive cards, driver toggle between "Hardware BLE" and "Simulated Watch", error alerts.
6. **`tests/uiComponents.test.tsx`**:
   - React Testing Library tests verifying scan triggers, device list rendering, connection controls, manual sync button click, and visual sync confirmation.
7. Verify `npm test`, `npm run typecheck`, and `npm run build` execute cleanly with 100% pass rate.

Write your handoff report to `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m4/handoff.md` and notify orchestrator when done.


## 2026-10-05T04:24:34Z
You are Worker 4 for Milestone 4 (User Interface & Visual Synchronization Panel).
Your task is defined in `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m4/DISPATCH.md`.

MANDATORY INTEGRITY WARNING:
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

MANDATORY: You MUST read `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md`, `PROJECT.md`, and `worker_m3/handoff.md`.

You exclusively own in `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app`:
- `src/components/DeviceDiscovery.tsx`
- `src/components/ConnectionStatusBadge.tsx`
- `src/components/ClockSyncPanel.tsx`
- `src/components/MockWatchPreview.tsx`
- `src/App.tsx`
- `src/App.css`
- `tests/uiComponents.test.tsx`

Implement the full mobile companion UI fulfilling requirements R4 and acceptance criteria.
Write component tests in tests/uiComponents.test.tsx.
Verify `npm test`, `npm run typecheck`, and `npm run build` execute cleanly with 100% pass rate.

Write your handoff report to `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m4/handoff.md` and notify orchestrator when done.
