# Product Brief: F91 Jepler Smartwatch Companion App

## Product context

Build a cross-platform mobile companion app (Android + iOS, one codebase where practical) for the **F91 Jepler** smartwatch — an nRF52840-based device running Zephyr RTOS with a BLE radio, a 96×39 SSD1306 OLED display (39 rows), and three case buttons labeled **A**, **B**, **C**.

This app is for the **physical end product**, not just emulation. Its primary source of truth is a real BLE peripheral: a real nRF52840 watch on the owner's wrist. Emulation (Renode) and the browser framebuffer viewer at http://127.0.0.1:8085 are development conveniences the app should degrade gracefully around, not the main relationship.

## Scope and features

Design and implement data models and screens for all of these flows. Prioritize UX polish and correctness of the first three; the firmware-update flow is explicitly a UI/workflow sketch.

1. **Connection & device management**
   - Scan for and connect to an F91 Jepler over BLE using the platform's real BLE APIs (Android BluetoothGatt / iOS CoreBluetooth). Do not mock the BLE stack; design it to talk to a real peripheral and to degrade cleanly when none is present.
   - Show connection state clearly and continuously: disconnected / scanning / connecting / connected / disconnected-with-reason / error.
   - Support multiple named watch profiles/devices for a single owner, with the last-used device remembered for fast reconnect.
   - Local-only persistence of profiles, preferences, and recent event history. No backend, no accounts.

2. **Live telemetry / dev console**
   - A calm, glanceable live view of what the watch is doing: connection events, button A/B/C press and release events, and the current displayed time.
   - Represent the watch state faithfully and readably — this is a human-readable read of the watch's current situation, not a pixel clone of the 96×39 OLED.
   - A short event timeline/log the owner can glance at while iterating on firmware or using the watch.
   - A clear "no device connected" resting state that is calm and useful, not blank or alarming.

3. **Button assignment editor**
   - Reconfigurable assignment for the three physical buttons A/B/C. The app's button model must map cleanly onto the firmware's existing source of truth — the project exports `buttons.json` from the compiled devicetree, so the app's assignment vocabulary and storage should line up with that artifact rather than inventing a parallel one.
   - Provide a concrete, sensible default action vocabulary rather than free-form labels. Suggested baseline:
     - **A (top left):** primary action — e.g. select/confirm, or open the app's main action for the current screen.
     - **B (bottom left):** secondary/contextual action — e.g. back/cancel, or a contextual secondary action.
     - **C (bottom right):** tertiary action — e.g. shortcut to a frequent function, long-press variant, or a watch-specific action.
     - Support short vs long press as distinct actions where the firmware distinguishes them, and label them clearly.
   - The editor should feel tactile and intentional: obvious button labels, obvious pressed vs released/assigned state, minimal friction to reassign.

4. **Diagnostics & settings**
   - Diagnostics screen: BLE connection info (device name/address where available, connection state, RSSI where available), firmware version readouts where the peripheral exposes them, and a clear, calm error/reconnection guidance path.
   - Settings/profile screen: named device profiles, default reconnect behavior, any watch-facing preferences the firmware exposes, and the firmware-update workflow sketch.
   - Firmware update workflow is **not yet implemented in firmware** — show the UI and the intended flow (select a signed `.bin` such as `build/renode-app/app.signed.bin`, confirm, send) but mark it visibly as not yet functional rather than building a broken flow. Keep it honest.

## Design priorities (most important)

The owner's explicit request: **thoughtful, intuitive, clean UI design.** This is a small personal tool; it should feel considered and calm, not like generic CRUD.

- **Native per platform, cohesive across platforms.** Both Android and iOS should feel at home on their platform: sensible platform idioms, navigation, and interactions on each, while sharing a coherent visual language, palette, and typography so the app feels like one product on two platforms. Prefer platform-native feel over pixel-identical screens.
- **Calm, legible, restrained.** Generous spacing, clear hierarchy, one primary thing per screen. The live telemetry screen should read at a glance; the console should feel like a focused instrument, not a dense dashboard or spreadsheet.
- **Dark mode is first-class and watch-adjacent.** The watch uses an OLED screen, so the app's dark palette should feel related to an OLED watch face — deep blacks, restrained contrast, not a generic "dark theme." Dark mode is a primary target, not a toggle nobody uses. Light mode still needs to be clean and legible, but dark is the aesthetic anchor.
- **Clear state everywhere.** Every screen communicates what the app is doing (scanning, connected, waiting for BLE, offline, error, not-yet-implemented) without making the user guess. Empty and error states are designed, not an afterthought.
- **Buttons A/B/C feel physical and obvious.** Clear labels, obvious pressed/release and assigned/unassigned state, minimal friction. The button model should be consistent between the live console, the event log, and the assignment editor.
- **Typography and rhythm.** Clean type scale, consistent spacing, obvious hierarchy. The watch screen is tiny; the phone has room — use it well rather than crowding.
- **Quiet by default.** Fewer colors, more whitespace, clearer labels, calmer motion. This is a tool a hardware tinkerer keeps open while iterating on firmware — it should feel like a well-designed instrument.

## Platform and technical constraints

- **Targets:** Android and iOS, one codebase where practical. Prefer a cross-platform approach that can use each platform's real BLE APIs and produce a native-feeling UI on both (e.g., Kotlin Multiplatform with Compose Multiplatform + platform BLE, or Flutter with adaptive per-platform UI). Justify the choice briefly in the README, including how BLE is handled on each platform.
- **BLE is core and real.** Use the platform BLE APIs; design the BLE client layer to talk to a real nRF52840 peripheral. The same layer should degrade gracefully for development/emulation (no device, virtual link, or offline) without pretending a real RF link exists.
- **Syncs with existing firmware artifacts.** The button-assignment model, device profile naming, and any watch-facing preferences should map onto the existing firmware project's conventions — especially the `buttons.json` devicetree export — so the owner is not maintaining two separate sources of truth.
- **Local-only.** No server, no accounts. Persist profiles, preferences, and event history locally.
- **Android-primary dogfooding.** The owner will primarily run and test this on Android during development, so the Android path should be first-class and complete (BLE permissions/model, dark mode, navigation, edge cases). iOS should be genuinely supported and native-feeling, but the Android experience is the priority for day-to-day use.

## Deliverables

- A cross-platform Android + iOS app project in the chosen stack, with implementations (or clearly-marked stubs) for the four flows above.
- Clean, opinionated UI for: device connection/scan, live telemetry/console, button assignment editor, diagnostics, and a settings/profile screen.
- Dark mode that feels OLED-watch-adjacent, with light mode also clean and legible.
- Clear offline/no-device and emulation-aware states.
- A short README covering: stack choice and BLE approach per platform, how to run on Android and iOS, how the app relates to the Renode viewer and the firmware's `buttons.json`, and what is implemented vs stubbed.

## Non-goals

- A store-ready consumer app with onboarding fluff, accounts, or backend.
- A pixel-perfect replica of the OLED screen — instead, a clean, faithful read of the watch state.
- Implementing the actual firmware update or BLE time sync — sketch the UI/workflow and mark them clearly as not yet implemented.

## Style guidance

When in doubt: quieter. Fewer colors, more whitespace, clearer labels, calmer motion. This is a tool a hardware tinkerer keeps open while iterating on firmware — it should feel like a well-designed instrument, not a marketing site.
