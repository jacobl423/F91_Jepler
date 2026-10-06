# Dispatch for Worker M1 Iteration 2

## Identity
- Role: Asset Models Remediation Worker
- Type: teamwork_preview_worker
- Working directory: /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m1_it2
- Parent Orchestrator: /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/orchestrator_macos
- Authoritative User Request: /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md
- Project Scope Document: /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/orchestrator_macos/PROJECT.md

## Exclusive Write Ownership
You own the following files exclusively:
1. `Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift`
2. `Software/macOS_App/F91JeplerEmulator/Engine/RenodeScriptGenerator.swift`
3. `Software/macOS_App/F91JeplerEmulator/Models/EmulatorSession.swift`

Do NOT touch any other source or view files.

## Mission & Implementation Details
Remediate the critical Intel HEX bounds defect identified by Challenger 1 using the verified drop-in code and patches produced by the Iteration 2 Explorers:
- `.agents/teamwork/explorer_m1_it2_1/handoff.md` (and `asset_inspector_bounds.patch`, `proposed_AssetInspector.swift`)
- `.agents/teamwork/explorer_m1_it2_2/handoff.md` (and `proposed_AssetInspector.swift` which includes `loadUnaligned` and Data slice bounds safety)
- `.agents/teamwork/explorer_m1_it2_3/handoff.md` (hardened HEX detection in `RenodeScriptGenerator.swift` and startup inspection isolation in `EmulatorSession.swift`)

### Tasks
1. Update `Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift`:
   - Replace with the fully hardened implementation from `.agents/teamwork/explorer_m1_it2_2/proposed_AssetInspector.swift`.
   - Ensure lines with record types 04 and 05 check `line.count >= 13` and `line.count >= 17` and use `limitedBy: line.endIndex` so `:0000000400` and similar truncated lines never trigger SIGTRAP.
2. Update `Software/macOS_App/F91JeplerEmulator/Engine/RenodeScriptGenerator.swift`:
   - Harden `detectFormat(path:)` so lines starting with `:` only classify as `.hex` if the payload is valid hex.
3. Update `Software/macOS_App/F91JeplerEmulator/Models/EmulatorSession.swift`:
   - Ensure startup asset inspection handles errors gracefully so corrupt files never cause crash loops.
4. Verify compilation:
   - Run `swift build` in `Software/macOS_App` (must exit code 0).
5. Verify empirical challenge suite:
   - Run the Challenger harness:
     ```bash
     swiftc -plugin-path /Applications/Xcode.app/Contents/Developer/Platforms/MacOSX.platform/Developer/usr/lib/swift/host/plugins \
       -parse-as-library $(find Software/macOS_App/F91JeplerEmulator -name "*.swift" ! -name "App.swift") \
       Software/macOS_App/scripts/empirical_challenger_harness.swift \
       -o /tmp/run_empirical_test && /tmp/run_empirical_test
     ```
   - Must output 32/32 tests passed (0 failed).
6. Write your handoff report to `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m1_it2/handoff.md`.

## Mandatory Integrity Warning
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A forensic auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.

## 2026-10-05T20:47:09Z
Received message from 6b5ed2d8-2b1d-40f1-8ab6-ad53a69017cd:
You are the Asset Models Remediation Worker for Milestone 1 Iteration 2 of the F91_Jepler project.
Your working directory is /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m1_it2.
Read /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md, /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/orchestrator_macos/PROJECT.md, and /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m1_it2/DISPATCH.md before starting work.
Study the reports and drop-in code in:
- /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_m1_it2_1/handoff.md
- /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_m1_it2_2/handoff.md (and proposed_AssetInspector.swift)
- /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_m1_it2_3/handoff.md

Exclusive Write Ownership:
1. Software/macOS_App/F91JeplerEmulator/Engine/AssetInspector.swift
2. Software/macOS_App/F91JeplerEmulator/Engine/RenodeScriptGenerator.swift
3. Software/macOS_App/F91JeplerEmulator/Models/EmulatorSession.swift

## 2026-10-05T21:00:43Z
**Context**: Milestone 1 Iteration 2 Remediation
**Content**: Please continue your task: apply the hardened implementations to `AssetInspector.swift`, `RenodeScriptGenerator.swift`, and `EmulatorSession.swift`, run `swift build`, execute the 32-test challenger harness, and deliver your handoff report to `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m1_it2/handoff.md`.
**Action**: Complete implementation, verify tests, and send completion message.
