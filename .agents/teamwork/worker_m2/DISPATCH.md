# Dispatch for Worker M2

## Identity
- Role: Sidebar & MainWindow UI Worker
- Type: teamwork_preview_worker
- Working directory: /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m2
- Parent Orchestrator: /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/orchestrator_macos
- Authoritative User Request: /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md
- Project Architecture & Scope: /Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/orchestrator_macos/PROJECT.md

## Exclusive Write Ownership
1. `Software/macOS_App/F91JeplerEmulator/Views/ProjectSidebarView.swift` (CREATE)
2. `Software/macOS_App/F91JeplerEmulator/Views/ContentView.swift` (UPDATE)
3. `Software/macOS_App/F91JeplerEmulator/Utils/KeyboardMonitor.swift` (UPDATE)
4. `Software/macOS_App/F91JeplerEmulator/Models/SessionAsset.swift` (UPDATE)

## Reference Specifications & Explorer Handoffs
Review and integrate the designs and complete Swift code from:
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_m2_1/handoff.md` (ProjectSidebarView.swift full implementation)
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_m2_2/handoff.md` (ContentView.swift 3-pane HSplitView, drop overlay removal)
- `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/explorer_m2_3/handoff.md` (Toolbar toggle, AppTopBarView button, ⌘0 / ⌥⌘S shortcuts, KeyboardMonitor modifier fix)

## Tasks
1. **Create `Software/macOS_App/F91JeplerEmulator/Views/ProjectSidebarView.swift`**:
   - Implement `ProjectSidebarView` with `SidebarHeaderView`, scrollable cards, and footer.
   - Dedicated cards for `.pcb`, `.appFirmware`, `.bootloader`, `.rescScript`.
   - Native drag-and-drop: `.onDrop(of: [.fileURL], isTargeted: $isTargeted)` with visual feedback.
   - Live metadata display: formatted size, timestamp, format badges (`MCUboot Signed`, `ELF32 ARM`, `Intel HEX`, `KiCad PCB`, `Renode Script`), secondary details, SHA256 prefix, status pills (`CUSTOM`, `EMBEDDED`, `SCANNING`, `MISSING`).
   - Non-modal quick actions: Browse/Replace (`NSOpenPanel`), Reload, Revert to default, Reveal in Finder (`NSWorkspace`), and right-click context menu.
2. **Update `Software/macOS_App/F91JeplerEmulator/Views/ContentView.swift`**:
   - Convert `HSplitView` into 3 panes:
     - Leading: `ProjectSidebarView` wrapped in `if session.isSidebarVisible` with smooth `.easeInOut(duration: 0.2)` animation, `minWidth: 230, idealWidth: session.sidebarWidth, maxWidth: 380`, and `.layoutPriority(0)`.
     - Center: Workbench view with `.layoutPriority(1)`.
     - Trailing: Terminal view with `.layoutPriority(0)`.
   - Remove the intrusive window-wide `.overlay` and `.onDrop`.
   - Add `.navigation` toolbar item with `systemImage: "sidebar.leading"`, tooltip `"Toggle Project Sidebar (⌘0)"`, and `.keyboardShortcut("0", modifiers: .command)`.
   - Add secondary shortcut `⌥⌘S` (`.keyboardShortcut("s", modifiers: [.command, .option])`).
   - In `AppTopBarView`: add leading sidebar toggle button with visual active/highlight styling.
3. **Update `Software/macOS_App/F91JeplerEmulator/Utils/KeyboardMonitor.swift`**:
   - Filter out events where modifier flags contain `.command`, `.option`, or `.control` in `keyFrom(event:)` so hotkeys like `⌘0`, `⌥⌘S`, and `⌘1`..`⌘6` are never swallowed.
4. **Update `Software/macOS_App/F91JeplerEmulator/Models/SessionAsset.swift`**:
   - Add `public static let sidebarVisibleAlternate = "jepler.sidebar.visible"` to `SessionPersistenceKeys` to ensure dual-key persistence compatibility.

## Verification Requirements
1. Build verification: `swift build` in `Software/macOS_App` must compile cleanly with 0 errors (exit code 0).
2. Regression verification: Run the 32-test Challenger empirical harness (`Software/macOS_App/scripts/empirical_challenger_harness.swift`) and ensure all 32 tests pass (0 failures).
3. Write your handoff report to `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/worker_m2/handoff.md`.

## Mandatory Integrity Warning
DO NOT CHEAT. All implementations must be genuine. DO NOT hardcode test results, create dummy/facade implementations, or circumvent the intended task. A forensic auditor will independently verify your work. Integrity violations WILL be detected and your work WILL be rejected.
