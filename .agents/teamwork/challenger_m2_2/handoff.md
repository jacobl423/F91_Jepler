# Handoff Report: Milestone 2 — Empirical Adversarial Challenge (Challenger 2)

**Author**: Challenger M2-2 (Empirical Challenger & Adversarial Critic)  
**Recipient**: Orchestrator (`6b5ed2d8-2b1d-40f1-8ab6-ad53a69017cd`)  
**Workspace**: `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/challenger_m2_2`  
**Verdict**: **REJECT**  
**Timestamp**: 2026-10-05T21:40:40Z  

---

## 1. Observation

### 1.1 Specification Baseline & Contract Requirements
- **Interface Contract (`PROJECT.md`)**:
  - Line 7: `Leading Pane: Collapsible ProjectSidebarView (minWidth: 230, idealWidth: 280, maxWidth: 380) with dedicated dropzone cards...`
  - Line 15: `All asset paths and UI state (sidebar visibility, width, active view mode) are persisted via UserDefaults.`
  - Line 49–56: `EmulatorSession` contract specifies `isSidebarVisible: Bool`, `sidebarWidth: CGFloat`, `revertAssetToDefault`, `reloadAsset`.
- **Challenger Dispatch (`DISPATCH.md`)**:
  - `EmulatorSession` sidebar persistence: test toggling `isSidebarVisible` across multiple simulated launches; verify synchronization between `jepler.sidebar.visible` and `jepler.sidebar.isVisible`.
  - Width persistence and clamping: verify `sidebarWidth` is constrained within `minWidth: 230` and `maxWidth: 380`.
  - Reverting assets: verify `revertAssetToDefault` resets paths, clears persistence overrides, and re-loads embedded defaults.
  - Non-modal action safety: test calling `reloadAsset` on non-existent, corrupt, and valid asset files.

### 1.2 Code Inspection Observations

#### 1. `Software/macOS_App/F91JeplerEmulator/Models/SessionAsset.swift`
Lines 10–13 define the persistence keys:
```swift
public static let isSidebarVisible = "jepler.sidebar.isVisible"
public static let sidebarVisible = "jepler.sidebar.visible"
public static let sidebarVisibleAlternate = "jepler.sidebar.visible"
public static let legacyIsSidebarVisible = "jepler.sidebar.isVisible"
```

#### 2. `Software/macOS_App/F91JeplerEmulator/Models/EmulatorSession.swift`
- Lines 38–42 define `isSidebarVisible`:
```swift
@Published public var isSidebarVisible: Bool = true {
    didSet {
        userDefaults.set(isSidebarVisible, forKey: SessionPersistenceKeys.isSidebarVisible)
    }
}
```
**Observation**: `didSet` updates `SessionPersistenceKeys.isSidebarVisible` (`"jepler.sidebar.isVisible"`). It does NOT update `SessionPersistenceKeys.sidebarVisible` (`"jepler.sidebar.visible"`).
- Lines 234–240 in `init`:
```swift
// 1. Restore Sidebar Visibility
if userDefaults.object(forKey: SessionPersistenceKeys.isSidebarVisible) != nil {
    self.isSidebarVisible = userDefaults.bool(forKey: SessionPersistenceKeys.isSidebarVisible)
} else {
    self.isSidebarVisible = true
}
```
**Observation**: `init` only inspects `SessionPersistenceKeys.isSidebarVisible`. If only `SessionPersistenceKeys.sidebarVisible` is present, it is completely ignored, falling back to `true`.
- Lines 44–48 define `sidebarWidth`:
```swift
@Published public var sidebarWidth: CGFloat = 280 {
    didSet {
        userDefaults.set(Double(sidebarWidth), forKey: SessionPersistenceKeys.sidebarWidth)
    }
}
```
**Observation**: `sidebarWidth` contains no validation or clamping logic against `minWidth: 230` or `maxWidth: 380`. Values such as `150`, `600`, `-100`, or `0` are directly written to memory and `UserDefaults`.
- Lines 242–247 in `init`:
```swift
// 2. Restore Sidebar Width
let savedWidth = CGFloat(userDefaults.double(forKey: SessionPersistenceKeys.sidebarWidth))
if savedWidth >= 230 && savedWidth <= 380 {
    self.sidebarWidth = savedWidth
} else {
    self.sidebarWidth = 280
}
```
**Observation**: Out-of-range values in `UserDefaults` cause `sidebarWidth` to snap all the way back to default `280`, instead of clamping to the nearest bound (`230` or `380`).

#### 3. `Software/macOS_App/F91JeplerEmulator/Views/ContentView.swift`
- Lines 124–129:
```swift
.onChange(of: session.isSidebarVisible) { visible in
    UserDefaults.standard.set(visible, forKey: SessionPersistenceKeys.sidebarVisibleAlternate)
}
.onAppear {
    UserDefaults.standard.set(session.isSidebarVisible, forKey: SessionPersistenceKeys.sidebarVisibleAlternate)
    setupKeyboardMonitoring()
    session.startSession()
}
```
**Observation**: Dual-key sync is only performed via SwiftUI `.onChange` against `UserDefaults.standard`. If `EmulatorSession` is initialized or modified outside this view hierarchy, `jepler.sidebar.visible` is never written. Furthermore, if a user persisted `jepler.sidebar.visible = false`, `EmulatorSession.init` ignores it (setting `session.isSidebarVisible = true`), and then `ContentView.onAppear` overwrites the saved `jepler.sidebar.visible` setting with `true`.

### 1.3 Verbatim Empirical Test Harness Results
The empirical challenger harness was written in `Software/macOS_App/scripts/empirical_challenger_m2_2_harness.swift` and executed directly against native Swift compilation:

Command:
```bash
swiftc -suppress-warnings -target arm64-apple-macos13.0 -parse-as-library \
  F91JeplerEmulator/Models/*.swift \
  F91JeplerEmulator/Engine/*.swift \
  F91JeplerEmulator/Utils/*.swift \
  scripts/empirical_challenger_m2_2_harness.swift \
  -o /tmp/m2_2_harness && /tmp/m2_2_harness
```

Output:
```
==================================================================
 EMPIRICAL CHALLENGER STRESS HARNESS — MILESTONE 2
 Target: EmulatorSession, Layout Resizing & State Persistence
 Timestamp: 2026-10-05 21:37:49 +0000
==================================================================

--- SUITE 1: Sidebar Visibility Persistence & Dual-Key Sync ---
  [PASS] Default Sidebar Visibility - Starts visible (true) when no saved preference exists
  [PASS] Primary Key Persistence - Updating isSidebarVisible writes false to 'jepler.sidebar.isVisible'
  [FAIL] Dual-Key Sync on Toggle - Desync! isVisible: Optional(false), visible: nil
  [FAIL] Restore from Alternate Key - Ignored alternate key! isSidebarVisible is true instead of false
  [PASS] Restore from Primary Key - Restored false when 'jepler.sidebar.isVisible' was set to false
  [FAIL] Multi-Toggle Lockstep Sync - Dual keys failed lockstep across 5 alternating toggles

--- SUITE 2: Sidebar Width Bounds & Clamping ---
  [PASS] Default Sidebar Width - Initial width is 280
  [PASS] Valid Width Persistence - Saved width 320 into 'jepler.sidebar.width'
  [PASS] Relaunch Restores Valid Width - Restored width 320 correctly
  [PASS] Boundary Min Width 230 - Persisted and restored min boundary 230
  [PASS] Boundary Max Width 380 - Persisted and restored max boundary 380
    [DIAGNOSTIC] Width set to 150 -> In-memory: 150.0, Restored: 280.0
  [FAIL] Runtime Underflow Clamping - Width was not clamped at runtime: 150.0 (min is 230)
  [PASS] Relaunch Underflow Fallback - Restored width 280.0 is within [230, 380]
    [DIAGNOSTIC] Width set to 600 -> In-memory: 600.0, Restored: 280.0
  [FAIL] Runtime Overflow Clamping - Width was not clamped at runtime: 600.0 (max is 380)
  [PASS] Relaunch Overflow Fallback - Restored width 280.0 is within [230, 380]
  [FAIL] Negative Width Clamping - Negative width was not clamped: -100.0
  [FAIL] Zero Width Clamping - Zero width was not clamped: 0.0

--- SUITE 3: Asset Revert Safety ---
  [PASS] Asset Update [pcb] - Marked custom and persisted path to 'jepler.custom.pcb.path'
  [PASS] Asset Revert [pcb] - Cleared override and restored default state (isCustom=false)
  [PASS] Asset Update [appFirmware] - Marked custom and persisted path to 'jepler.custom.appBin.path'
  [PASS] Asset Revert [appFirmware] - Cleared override and restored default state (isCustom=false)
  [PASS] Asset Update [bootloader] - Marked custom and persisted path to 'jepler.custom.bootloader.path'
  [PASS] Asset Revert [bootloader] - Cleared override and restored default state (isCustom=false)
  [PASS] Asset Update [rescScript] - Marked custom and persisted path to 'jepler.custom.resc.path'
  [PASS] Asset Revert [rescScript] - Cleared override and restored default state (isCustom=false)
  [PASS] Computed Properties Set - All 4 custom URLs set via computed properties
  [PASS] Computed Properties Nil Revert - Setting nil reverted all 4 assets and cleared persistence keys
  [PASS] Batch Setup - All 4 custom asset paths persisted
  [PASS] loadEmbeddedDefaults() - All 4 persistence keys cleared and all 4 assets reverted to non-custom

--- SUITE 4: Non-Modal Action Safety ---
  [PASS] reloadAsset Non-Existent File - Safely caught missing file without crash; state: Optional(m2_2_harness.AssetLoadState.missing("File missing on disk"))
  [PASS] reloadAsset 0-Byte File - Inspected as Empty without throwing; badge: Empty
  [PASS] reloadAsset Corrupt File - Handled corrupted PCB without crashing; toast: Auto-reloaded 'corrupted.kicad_pcb' from KiCad
  [PASS] reloadAsset Nil Asset - Safely no-op'd when asset is nil
  [PASS] revealAssetInFinder Missing File - Set user-visible error banner safely: Cannot reveal in Finder: file does not exist at /var/folders/vd/j_f4q_2d7kl4j0qwnc9qyd440000gn/T/challenger_m2_actions_5FC189F0-8E01-4A10-BAE9-D2C6763F9FBD/missing_reveal.bin
  [PASS] Rapid Reloads (50x) - Survived 50 rapid successive reload calls without deadlock or crash

--- SUITE 5: ViewMode & Multi-Launch Simulated Cycles ---
  [PASS] ViewMode [Watch Console] - Persisted and restored across simulated launches
  [PASS] ViewMode [OLED Canvas] - Persisted and restored across simulated launches
  [PASS] ViewMode [GATT / BLE Harness] - Persisted and restored across simulated launches
  [PASS] ViewMode [Regression Tests] - Persisted and restored across simulated launches
  [PASS] ViewMode [KiCad PCB] - Persisted and restored across simulated launches
  [PASS] ViewMode [GDB / CPU] - Persisted and restored across simulated launches
  [PASS] ViewMode [Workbench Split] - Persisted and restored across simulated launches
  [PASS] Corrupt ViewMode Fallback - Safely fell back to default .split mode
  [PASS] Multi-Launch Cycle 1 - Recovered isSidebarVisible=false, width=310, viewMode=.gatt
  [PASS] Multi-Launch Cycle 2 - Recovered isSidebarVisible=true, width=260, viewMode=.watch

==================================================================
 EMPIRICAL CHALLENGE HARNESS COMPLETE
 Total Tests Run: 45
 Passed: 38
 Failed: 7
 Verdict: REJECT
==================================================================
```

---

## 2. Logic Chain

1. **Dual-Key Persistence Desynchronization (Observation 1.2, 1.3 - Suite 1)**:
   - *Premise*: The specification requires backward and cross-key compatibility between `jepler.sidebar.visible` and `jepler.sidebar.isVisible`.
   - *Observation*: `EmulatorSession.isSidebarVisible.didSet` only writes `SessionPersistenceKeys.isSidebarVisible`. `SessionPersistenceKeys.sidebarVisible` remains `nil`.
   - *Observation*: `EmulatorSession.init` only checks `SessionPersistenceKeys.isSidebarVisible`. When only `jepler.sidebar.visible` is populated, `isSidebarVisible` is erroneously initialized to `true`.
   - *Observation*: `ContentView.onAppear` writes `session.isSidebarVisible` into `jepler.sidebar.visible`, thereby overwriting previously saved user preferences.
   - *Inference*: `EmulatorSession` fails to maintain dual-key synchronization, violating the contract requirement.

2. **Unconstrained Width Clamping at Runtime (Observation 1.2, 1.3 - Suite 2)**:
   - *Premise*: `PROJECT.md` specifies that the sidebar frame is `minWidth: 230, idealWidth: 280, maxWidth: 380`, and the dispatch explicitly requires: `verify sidebarWidth is constrained within minWidth: 230 and maxWidth: 380`.
   - *Observation*: Setting `session.sidebarWidth = 150` sets the in-memory value to `150.0` and writes `150.0` to `UserDefaults`. It is not clamped to `230`.
   - *Observation*: Setting `session.sidebarWidth = 600` sets the in-memory value to `600.0` and writes `600.0` to `UserDefaults`. It is not clamped to `380`.
   - *Observation*: Negative values (`-100`) and zero (`0`) are similarly accepted and stored without clamping.
   - *Inference*: The state coordinator fails to enforce its invariant bounds at runtime.

3. **Robustness of Asset Revert and Non-Modal Safety (Observation 1.3 - Suites 3 & 4)**:
   - *Observation*: Individual asset reverts, computed property `nil` assignments, and `loadEmbeddedDefaults()` all cleanly purge `UserDefaults` overrides and restore default embedded assets.
   - *Observation*: Calling `reloadAsset` on non-existent, 0-byte, and corrupt files handles errors non-modally without throwing, crashing, or deadlock. 50 rapid concurrent calls execute safely.
   - *Inference*: Asset lifecycle and error handling are robust and approved.

---

## 3. Caveats

- **SwiftUI Layout Environment**: While `sidebarWidth` is unconstrained in `EmulatorSession`, `ContentView.swift` applies `.frame(minWidth: 230, idealWidth: session.sidebarWidth, maxWidth: 380)`. This prevents visual clipping in the rendered view, but the underlying model state and persisted values remain out of bounds.
- **Interactive Splitter Movement**: SwiftUI's `HSplitView` does not provide two-way binding on pane widths; divider movements by the user in AppKit do not automatically write back to `session.sidebarWidth`.

---

## 4. Conclusion & Explicit Verdict

### **Verdict: REJECT**

Milestone 2 cannot be approved in its current state due to 7 empirical test failures across 2 critical functional areas:
1. **Dual-Key Persistence Failure**: `EmulatorSession` does not synchronize `jepler.sidebar.visible` and `jepler.sidebar.isVisible`, causing state desynchronization and potential preference clobbering.
2. **Missing Runtime Width Clamping**: `EmulatorSession.sidebarWidth` accepts values outside `[230, 380]` (`150`, `600`, `-100`, `0`) and persists invalid values to `UserDefaults`.

### Challenge Summary

**Overall risk assessment**: **HIGH**

### Challenges

#### [High] Challenge 1: Dual-Key Synchronization Desynchronization
- **Assumption challenged**: The worker assumed syncing `sidebarVisibleAlternate` in `ContentView.swift` via `.onChange` is sufficient.
- **Attack scenario**: Any access to `EmulatorSession` outside `ContentView` (or prior to `onAppear`, or with a custom `UserDefaults` suite) fails to synchronize `jepler.sidebar.visible`. Furthermore, if `jepler.sidebar.visible = false` was set in preferences, launch restores `true` and overwrites the key.
- **Blast radius**: User sidebar collapse preference lost on relaunch if saved under `jepler.sidebar.visible`; inconsistency across configuration tooling.
- **Mitigation**: Update `EmulatorSession.swift`:
  ```swift
  @Published public var isSidebarVisible: Bool = true {
      didSet {
          userDefaults.set(isSidebarVisible, forKey: SessionPersistenceKeys.isSidebarVisible)
          userDefaults.set(isSidebarVisible, forKey: SessionPersistenceKeys.sidebarVisible)
      }
  }
  ```
  And in `EmulatorSession.init`:
  ```swift
  if let saved = userDefaults.object(forKey: SessionPersistenceKeys.isSidebarVisible) as? Bool {
      self.isSidebarVisible = saved
  } else if let savedAlt = userDefaults.object(forKey: SessionPersistenceKeys.sidebarVisible) as? Bool {
      self.isSidebarVisible = savedAlt
      userDefaults.set(savedAlt, forKey: SessionPersistenceKeys.isSidebarVisible)
  } else {
      self.isSidebarVisible = true
  }
  ```

#### [Medium] Challenge 2: Absence of Runtime Width Clamping
- **Assumption challenged**: The worker assumed SwiftUI view frame modifiers provide all needed width clamping.
- **Attack scenario**: Programmatic adjustments, external preferences, or drag events setting `session.sidebarWidth = 100` or `500` persist illegal values and corrupt state on relaunch.
- **Blast radius**: Model state contradicts architectural invariants; relaunch falls back to 280 rather than clamping to boundary values.
- **Mitigation**: Add clamping in `EmulatorSession.swift`:
  ```swift
  @Published public var sidebarWidth: CGFloat = 280 {
      didSet {
          let clamped = min(max(sidebarWidth, 230), 380)
          if sidebarWidth != clamped {
              sidebarWidth = clamped
              return
          }
          userDefaults.set(Double(clamped), forKey: SessionPersistenceKeys.sidebarWidth)
      }
  }
  ```
  And in `init`:
  ```swift
  if userDefaults.object(forKey: SessionPersistenceKeys.sidebarWidth) != nil {
      let savedWidth = CGFloat(userDefaults.double(forKey: SessionPersistenceKeys.sidebarWidth))
      self.sidebarWidth = min(max(savedWidth, 230), 380)
  } else {
      self.sidebarWidth = 280
  }
  ```

---

## 5. Verification Method

### 5.1 Project Compilation
Run from `Software/macOS_App`:
```bash
swift build
```
Expected result: Exit code 0.

### 5.2 Execute Empirical Test Harness
Run from `Software/macOS_App`:
```bash
swiftc -suppress-warnings -target arm64-apple-macos13.0 -parse-as-library \
  F91JeplerEmulator/Models/*.swift \
  F91JeplerEmulator/Engine/*.swift \
  F91JeplerEmulator/Utils/*.swift \
  scripts/empirical_challenger_m2_2_harness.swift \
  -o /tmp/m2_2_harness && /tmp/m2_2_harness
```
Expected result:
- Currently: 38 Passed, 7 Failed. Verdict: **REJECT**.
- After implementing mitigations in `EmulatorSession.swift`: 45 Passed, 0 Failed. Verdict: **APPROVE**.

### 5.3 Invalidation Conditions
- If `Dual-Key Sync on Toggle` passes and keeps both keys identical without `ContentView`.
- If `sidebarWidth` clamping constrains in-memory values to `[230, 380]` when assigned `150` or `600`.
