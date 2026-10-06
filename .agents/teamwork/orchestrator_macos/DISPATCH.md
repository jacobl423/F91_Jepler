# Dispatch Record

## 2026-10-05T19:53:41Z
You are the Project Orchestrator for the F91_Jepler project.

Your assigned working directory is:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/orchestrator_macos

Authoritative user request record:
/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md
(Refer to the latest request dated 2026-10-05T19:52:40Z)

Task Summary:
Redesign the macOS companion and emulator app ("Jepler Dev") UI to introduce a thoughtful, intuitive collapsible left sidebar on the primary screen for uploading and managing PCBs, firmware binaries, and software scripts, seamlessly integrated with the emulator workbench and terminal.

Code Working Directory:
/Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App

Key Requirements:
- R1. Collapsible Project & Asset Upload Sidebar: Expandable/collapsible project sidebar on primary screen with dedicated visual dropzones and file pickers for `.kicad_pcb`, application `.bin`/`.hex`, MCUboot `.elf`, and `.resc`/companion scripts.
- R2. Live Asset Status & Quick Management: Display current file metadata (filename, load status, attributes), quick actions (browse/replace, clear, reload, reveal in Finder), automatically updating active emulator session configuration without modal sheets.
- R3. Ergonomic Workbench Layout & State Persistence: Integrate with main window layout (workbench panels & UART/Renode terminal) via smooth split view resizing, toolbar toggle button, keyboard shortcuts, and state persistence.

Acceptance Criteria:
- UI & Interaction: Accessible directly on primary screen with toolbar toggle & shortcut; drag-and-drop accepts specified filetypes with hover/drop feedback; selected files update session configuration immediately; workbench and terminal remain functional and resize fluidly.
- Build & Quality: `swift build` compiles cleanly with zero compilation errors; existing emulator session controls (Start, Stop, Reboot, key monitors) remain functional.
