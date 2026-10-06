# BRIEFING — 2026-10-05T20:02:00Z

## Mission
Investigate the macOS companion app codebase in Software/macOS_App (main window layout, workbench views, terminal views, toolbar items, split view structure, keyboard shortcuts, modal sheets, and state persistence) and analyze how to introduce a collapsible left sidebar on the primary screen for PCB/firmware/script management.

## 🔒 My Identity
- Archetype: explorer
- Roles: [UI Layout Explorer, investigation, synthesis]
- Working directory: /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_survey_1
- Original parent: 6b5ed2d8-2b1d-40f1-8ab6-ad53a69017cd
- Milestone: UI Layout Exploration & Architecture Analysis

## 🔒 Key Constraints
- Read-only investigation — do NOT implement
- Investigate codebase in Software/macOS_App
- Synthesize findings and write handoff report to handoff.md

## Current Parent
- Conversation ID: 6b5ed2d8-2b1d-40f1-8ab6-ad53a69017cd
- Updated: 2026-10-05T20:02:00Z

## Investigation State
- **Explored paths**:
  - `Package.swift`: Swift 5.9, macOS v13+ platform, single executable target `F91JeplerEmulator`.
  - `F91JeplerEmulator/App.swift`: `WindowGroup("Jepler Dev")`, `.windowStyle(.titleBar)`, `.windowToolbarStyle(.unified)`.
  - `F91JeplerEmulator/Views/ContentView.swift`: `AppTopBarView` inside `VStack`, 2-pane `HSplitView` (Workbench + Terminal), global `.onDrop`, toolbar gear icon, modal `HardwareSetupView` sheet.
  - `F91JeplerEmulator/Views/HardwareSetupView.swift`: Current modal sheet for file selection and paths.
  - `F91JeplerEmulator/Views/ToolbarControlsView.swift`: Alternate unintegrated toolbar control view.
  - `F91JeplerEmulator/Views/TerminalView.swift`: Right-pane terminal with `ConsoleTerminalTextView`.
  - `F91JeplerEmulator/Views/CasioWatchFrameView.swift`: Responsive scaling watch frame with live OLED and tactile buttons.
  - `F91JeplerEmulator/Views/KiCadPcbView.swift`: 6-tab PCB workbench with internal `HSplitView`.
  - `F91JeplerEmulator/Models/EmulatorSession.swift`: Central `@MainActor` observable object holding active state, process manager, socket client, and file URLs.
  - `F91JeplerEmulator/Utils/KeyboardMonitor.swift`: Intercepts physical hotkeys 1/2/3 without blocking command modifiers.
  - `F91JeplerEmulator/Engine/ResourceLoader.swift` & `KiCadToolService.swift`: Asset resolution and Finder/tool integration.
- **Key findings**:
  - Main window currently has no sidebar; layout is strictly 2-pane `HSplitView` (Workbench + Terminal).
  - File configuration is split between a crude window-wide drop overlay and a modal sheet (`HardwareSetupView`).
  - Codebase currently lacks state persistence (`@AppStorage`, `UserDefaults`, `SceneStorage` are absent).
  - All workbench panels (`CasioWatchFrameView`, `OLEDCanvasView`, `KiCadPcbView`, etc.) and `TerminalView` are already built to resize fluidly.
  - Introducing `ProjectSidebarView` into `HSplitView` with `withAnimation` and `UserDefaults` backing provides clean collapse/expand without breaking existing layouts.
- **Unexplored areas**: None; full UI architecture and data flow surveyed.

## Key Decisions Made
- Architecture designed for dedicated `ProjectSidebarView` with 4 asset cards (PCB, App Bin, Bootloader, Renode Script) + Workspace section.
- Designed 3-pane `HSplitView` with conditional sidebar rendering and smooth transition.
- Defined state persistence keys in `UserDefaults` on `EmulatorSession`.
- Planned dual-toolbar controls: standard window toolbar (`ToolbarItem(placement: .navigation)`) and in-app top bar toggle button, plus `Cmd+0` and `Opt+Cmd+S` shortcuts.

## Artifact Index
- /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_survey_1/handoff.md — Final handoff report
- /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_survey_1/progress.md — Liveness heartbeat
