# Dispatch for Explorer M2-1

## Identity
- Role: Sidebar Dropzone & Card UI Explorer
- Type: teamwork_preview_explorer
- Working directory: /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_m2_1
- Parent Orchestrator: /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/orchestrator_macos
- Authoritative User Request: /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md
- Project Architecture & Scope: /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/orchestrator_macos/PROJECT.md

## Mission & Scope
Investigate and design `Software/macOS_App/F91JeplerEmulator/Views/ProjectSidebarView.swift`:
1. Study `SessionAsset.swift`, `AssetInspector.swift`, and `EmulatorSession.swift` (already completed in Milestone 1).
2. Design dedicated card components for each `SessionAssetKind`:
   - `.pcb`: KiCad PCB layout (`.kicad_pcb`)
   - `.appFirmware`: Application firmware (`.bin`, `.hex`, `.elf`)
   - `.bootloader`: MCUboot bootloader (`.elf`, `.hex`, `.bin`)
   - `.rescScript`: Renode emulation script (`.resc`, `.txt`)
3. Design drag-and-drop mechanics for each card:
   - Visual dropzone area with `.onDrop(of: [.fileURL], isTargeted: $isTargeted)`.
   - Clear hover feedback (accent border, background tint, icon animation).
   - Validation on drop: extract file URL, verify file extension/type, call `session.updateAsset(kind: url:)`.
4. Design live metadata display on each card:
   - File name (truncated if long, full path tooltip).
   - Format badge (e.g., "MCUboot Signed", "ELF32 ARM", "Intel HEX", "KiCad PCB", "Renode Script").
   - File size formatted (e.g., "142.5 KB") and modification date formatted.
   - Secondary detail (e.g., "v2.1.3 · 128 KB payload", "nRF52840 · 45 lines", "64x48 mm · 2 layers").
   - Status indicators: Loaded / Ready / Embedded Default / Corrupt / Missing.
5. Design non-modal quick action controls for each card:
   - Browse / Replace: `NSOpenPanel` filtered to valid extensions.
   - Revert / Reset: Reset to default embedded asset (`session.revertAssetToDefault(kind:)`).
   - Reload: In-memory reload (`session.reloadAsset(kind:)`).
   - Reveal in Finder: Select file in Finder (`session.revealAssetInFinder(kind:)`).
6. Deliver complete, production-ready Swift code specifications in your handoff report:
   `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_m2_1/handoff.md`.


## 2026-10-05T21:09:33Z
You are Explorer 1 for Milestone 2 of the F91_Jepler project.
Your working directory is /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_m2_1.
Read /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md, /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/orchestrator_macos/PROJECT.md, and /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_m2_1/DISPATCH.md before starting work.
Investigate and design Software/macOS_App/F91JeplerEmulator/Views/ProjectSidebarView.swift:
- Dedicated dropzone cards for .pcb (.kicad_pcb), .appFirmware (.bin/.hex/.elf), .bootloader (.elf/.hex/.bin), and .rescScript (.resc).
- Visual dropzones with .onDrop(of: [.fileURL], isTargeted: $isTargeted) and drag-over visual feedback.
- Live metadata display: filename, format badge, formatted size, modification date, secondary detail, status badge.
- Non-modal quick actions: Browse/Replace via NSOpenPanel, Revert to default, In-memory reload, Reveal in Finder.
Write your complete analysis and production Swift code specification to /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_m2_1/handoff.md and report back when complete.
