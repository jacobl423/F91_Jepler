# Original User Request

## 2026-10-05T03:06:51Z

Build a cross-platform mobile companion application prototype (targeting Android and iOS) for the F91_Jepler smartwatch to handle BLE discovery, connection management, and manual clock synchronization.

Working directory: /Users/jacobloesch/Documents/F91_Jepler/Software/companion_app
Integrity mode: development

## Reference Specifications

- **Device Name**: `F91_Jepler`
- **Clock Service UUID**: `fa35b2f0-7989-11eb-9439-0242ac130002`
- **Time Characteristic UUID**: `fa35b2f1-7989-11eb-9439-0242ac130002` (uint32 Unix epoch seconds, little-endian)
- **Timezone Characteristic UUID**: `fa35b2f2-7989-11eb-9439-0242ac130002` (uint16 offset in minutes or minutes from UTC, little-endian)
- **Time Mode Characteristic UUID**: `fa35b2f3-7989-11eb-9439-0242ac130002` (uint8: 0 for 12-hour, 1 for 24-hour)
- **DST Characteristic UUID**: `fa35b2f4-7989-11eb-9439-0242ac130002` (uint8: 0 for standard time, 1 for daylight saving time)

## Requirements

### R1. Cross-Platform Mobile Application Setup
Establish a clean, cross-platform mobile project architecture capable of targeting both Android and iOS, selecting the most suitable framework based on environment compatibility and Bluetooth Low Energy support.

### R2. BLE Peripheral Discovery & Connection Management
Implement BLE peripheral scanning to discover the `F91_Jepler` device (or filter by Clock Service UUID), establish a reliable connection, gracefully handle disconnections, and maintain connection state.

### R3. Clock Synchronization Service
Implement the client-side GATT protocol for the F91_Jepler Clock Service, serializing current local system time, timezone offset, time format mode (12h/24h), and daylight saving time (DST) status into the exact byte layouts expected by the firmware characteristics.

### R4. Companion User Interface
Provide a mobile user interface allowing users to scan for nearby watches, inspect found devices, initiate connect/disconnect actions, observe live connection status, and trigger manual time synchronization via a dedicated button with visual feedback.

### R5. Automated Verification & State Machine Testing
Provide an automated test suite verifying the BLE connection state machine, GATT payload serialization (verifying little-endian byte ordering against known test vectors), and UI component state behavior using mock BLE abstractions.

## Acceptance Criteria

### Project Architecture & Build
- [ ] Mobile project build and bundle commands complete cleanly without errors.
- [ ] Project is fully contained within `Software/companion_app`.

### BLE Discovery & Connection
- [ ] Scan mechanism filters for peripheral name `F91_Jepler` or Clock Service UUID `fa35b2f0-7989-11eb-9439-0242ac130002`.
- [ ] Connection manager accurately reflects `disconnected`, `scanning`, `connecting`, and `connected` states.
- [ ] Disconnection events update UI status cleanly without throwing unhandled exceptions.

### Clock GATT Protocol & Serialization
- [ ] Time payload encodes current Unix epoch seconds as a 4-byte unsigned integer in little-endian format.
- [ ] Timezone payload encodes the timezone offset as a 2-byte unsigned integer in little-endian format.
- [ ] Timemode and DST payloads serialize as 1-byte unsigned values conforming to firmware definitions.
- [ ] Manual sync action sends writes to the corresponding GATT characteristics in sequence.

### Verification Suite
- [ ] Unit test suite executes and passes 100% of tests.
- [ ] Serialization tests validate exact byte arrays against fixed timestamp and timezone test vectors.


## 2026-10-05T05:03:02Z

Make it into an apk I can side load on my android


## 2026-10-05T19:52:40Z

Redesign the macOS companion and emulator app ("Jepler Dev") UI to introduce a thoughtful, intuitive collapsible left sidebar on the primary screen for uploading and managing PCBs, firmware binaries, and software scripts, seamlessly integrated with the emulator workbench and terminal.

Working directory: /Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App
Integrity mode: development

## Requirements

### R1. Collapsible Project & Asset Upload Sidebar
Implement an expandable and collapsible project sidebar on the primary screen that provides dedicated, visual dropzones and file pickers for:
- PCB Layouts (`.kicad_pcb`)
- Firmware Binaries (Application `.bin`/`.hex` and MCUboot `.elf`)
- Software & Emulation Scripts (`.resc` and companion tools)

### R2. Live Asset Status & Quick Management
Display current file metadata (filename, load status, and file attributes) for each uploaded asset in the sidebar, with quick actions to browse/replace, clear, reload, or reveal in Finder, updating the active emulator session automatically without requiring modal configuration sheets.

### R3. Ergonomic Workbench Layout & State Persistence
Integrate the sidebar with the existing main window layout (workbench panels and UART/Renode terminal) using smooth split view resizing, toolbar toggle controls, keyboard shortcuts, and state persistence so the user can easily collapse the sidebar when focusing on emulation and testing.

## Acceptance Criteria

### UI & Interaction
- [ ] The left sidebar is accessible directly on the primary screen with a dedicated toolbar toggle button and shortcut.
- [ ] Drag-and-drop targets accept `.kicad_pcb`, `.bin`, `.hex`, `.elf`, and `.resc` files with clear hover and drop feedback.
- [ ] Uploaded/selected files immediately update the underlying session configuration and display loaded file information.
- [ ] The central workbench (watch face, OLED canvas, GATT inspector, PCB viewer) and right terminal remain fully functional and resize fluidly when the sidebar is toggled.

### Build & Code Quality
- [ ] `swift build` in `Software/macOS_App` compiles cleanly with zero compilation errors.
- [ ] Existing emulator session controls (Start, Stop, Reboot, keyboard key monitors) remain functional.
