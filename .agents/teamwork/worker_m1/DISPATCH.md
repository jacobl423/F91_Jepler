# Dispatch for Worker M1

## Identity
- Role: Asset Models & Session Integration Worker
- Type: teamwork_preview_worker
- Working directory: /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m1
- Parent Orchestrator: /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/orchestrator_macos
- Authoritative User Request: /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md
- Project Scope Document: /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/orchestrator_macos/PROJECT.md

## Exclusive Write Ownership
You own the following files exclusively:
1. `Software/macOS_App/F91JeplerEmulator/Models/SessionAsset.swift` (create new)
2. `Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift` (create new)
3. `Software/macOS_App/F91JeplerEmulator/Engine/RenodeScriptGenerator.swift` (update)
4. `Software/macOS_App/F91JeplerEmulator/Engine/RenodeProcessManager.swift` (update)
5. `Software/macOS_App/F91JeplerEmulator/Models/EmulatorSession.swift` (update)

Do NOT touch any other source or view files.

## Mission & Implementation Details
Implement Milestone 1 (Asset Models, Metadata Engine & Session Integration) using the verified designs and drop-in implementations from the Explorers:
- `.agents/teamwork/explorer_m1_1/handoff.md` (and `proposed_SessionAsset.swift`, `proposed_AssetInspector.swift`)
- `.agents/teamwork/explorer_m1_2/handoff.md` (and `proposed_RenodeScriptGenerator.swift`, `proposed_RenodeProcessManager.swift`, `renode_dynamic_loading.patch`)
- `.agents/teamwork/explorer_m1_3/handoff.md` (exact `EmulatorSession.swift` integration with `UserDefaults` persistence, backwards-compatible computed properties, and quick actions)

### Tasks
1. Create `Software/macOS_App/F91JeplerEmulator/Models/SessionAsset.swift`:
   - Define `SessionAssetKind` (`.pcb`, `.appFirmware`, `.bootloader`, `.rescScript`), `AssetLoadState`, `AssetMetadata`, `DetectedAssetFormat`, and `SessionAsset`.
2. Create `Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift`:
   - Implement asynchronous, non-blocking header and metadata extraction supporting MCUboot magic `0x96F3B83D`, ELF32 Little-Endian ARM Cortex-M `\x7fELF` + `0x0028`, Intel HEX `:`, KiCad PCB `(kicad_pcb`, and Renode scripts.
3. Update `Software/macOS_App/F91JeplerEmulator/Engine/RenodeScriptGenerator.swift`:
   - Implement `BinaryFormat` enum (`.elf`, `.hex`, `.binary`) and dynamic command formatting (`sysbus LoadELF`, `sysbus LoadHEX`, `sysbus LoadBinary ... 0x0c000` / `0x00000`).
4. Update `Software/macOS_App/F91JeplerEmulator/Engine/RenodeProcessManager.swift`:
   - Preserve original file extensions during workspace staging (`safeAppName`, `safeBlName`) in `f91_renode_<UUID>`.
5. Update `Software/macOS_App/F91JeplerEmulator/Models/EmulatorSession.swift`:
   - Integrate `assets: [SessionAssetKind: SessionAsset]`, `isSidebarVisible: Bool`, `sidebarWidth: CGFloat`.
   - Add `UserDefaults` state persistence (`SessionPersistenceKeys`) with path validation on startup.
   - Add quick action methods: `updateAsset(kind:url:)`, `revertAssetToDefault(kind:)`, `reloadAsset(kind:)`, `revealAssetInFinder(kind:)`.
   - Preserve backwards compatibility for `customPCBURL`, `customAppBinURL`, `customBootloaderURL`, `customRescURL` as computed properties `{ get set }` backed by `assets`.
   - Ensure in-memory PCB hot reloading (`reloadPCB`) does not stop or restart the running Renode session.
6. Verify compilation: Run `swift build` in `Software/macOS_App` and verify zero errors (exit code 0).
7. Write your handoff report to `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m1/handoff.md`.

## Mandatory Integrity Warning
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A forensic auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.


## 2026-10-05T20:17:04Z
[Message] timestamp=2026-10-05T20:17:04Z sender=6b5ed2d8-2b1d-40f1-8ab6-ad53a69017cd priority=MESSAGE_PRIORITY_HIGH content=You are the Asset Models & Session Integration Worker for Milestone 1 of the F91_Jepler project.
Your working directory is /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m1.
Read /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md, /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/orchestrator_macos/PROJECT.md, and /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m1/DISPATCH.md before starting work.
Also study the reports and drop-in code in:
- /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_m1_1/handoff.md
- /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_m1_2/handoff.md
- /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_m1_3/handoff.md

Exclusive Write Ownership:
1. Software/macOS_App/F91JeplerEmulator/Models/SessionAsset.swift
2. Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift
3. Software/macOS_App/F91JeplerEmulator/Engine/RenodeScriptGenerator.swift
4. Software/macOS_App/F91JeplerEmulator/Engine/RenodeProcessManager.swift
5. Software/macOS_App/F91JeplerEmulator/Models/EmulatorSession.swift

Implement SessionAsset.swift, AssetInspector.swift, dynamic binary loading in RenodeScriptGenerator/RenodeProcessManager, and EmulatorSession.swift updates with UserDefaults persistence and quick action helpers.
Verify with `swift build` inside Software/macOS_App ensuring exit code 0.
Write your complete handoff report to /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m1/handoff.md and report back when complete.

DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A forensic auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.
