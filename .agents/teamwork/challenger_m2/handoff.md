# Handoff Report: Challenger M2 — Empirical Adversarial Challenge

**Author**: Challenger M2 (Empirical Challenger & Adversarial Critic)  
**Recipient**: Orchestrator (`597ea6c0-a703-4980-a746-5cc67a9a63e2`)  
**Workspace**: `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app`  
**Verdict**: **APPROVE**  
**Timestamp**: 2026-10-05T04:06:30Z  

---

## 1. Observation

### 1.1 Specification Baseline & Implementation Review
- **Firmware Specifications (`Firmware/zephyr/src/services/clock_service.[ch]`)**:
  - `BT_UUID_CLOCK_SERVICE_VAL` = `fa35b2f0-7989-11eb-9439-0242ac130002`
  - `BT_UUID_CLOCK_TIME_CHAR_VAL` = `fa35b2f1-7989-11eb-9439-0242ac130002` (4-byte `uint32_t` little-endian epoch seconds)
  - `BT_UUID_CLOCK_TIMEZONE_CHAR_VAL` = `fa35b2f2-7989-11eb-9439-0242ac130002` (2-byte `uint16_t` signed int16 minutes)
  - `BT_UUID_CLOCK_TIMEMODE_CHAR_VAL` = `fa35b2f3-7989-11eb-9439-0242ac130002` (1-byte `uint8_t`: 0=12h, 1=24h)
  - `BT_UUID_CLOCK_DST_CHAR_VAL` = `fa35b2f4-7989-11eb-9439-0242ac130002` (1-byte `uint8_t`: 0=std, 1=dst)
  - Strict length guard in `write_clock_time`, `write_clock_timezone`, `write_clock_timemode`, `write_clock_dst`:
    ```c
    if (offset != 0 || len != sizeof(...)) {
        return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
    }
    ```
    Where `BT_ATT_ERR_INVALID_OFFSET = 0x07`.

- **Companion App Implementation (`Software/companion_app/src/ble/`)**:
  - `gattConstants.ts`: Declares UUIDs, payload lengths, and `BT_ATT_ERR_INVALID_OFFSET = 0x07`.
  - `gattSerializer.ts`: Implements little-endian serialization using `DataView(..., true)` and length/range guards throwing `RangeError` / `Error`.
  - `mockBleService.ts`: Simulates Zephyr GATT server with strict 0x07 error code matching, defensive copying of byte buffers, fault injection, and chronological write logging.
  - `capacitorBleService.ts`: Implements production BLE driver wrapping `@capacitor-community/bluetooth-le`.

### 1.2 Adversarial Test Suite Execution (`tests/challenge_m2.test.ts`)
Created and executed `tests/challenge_m2.test.ts` containing 28 stress tests across 5 challenge suites:
- `C0`: Protocol constants and GATT specification conformance (lengths, enums, error code 0x07).
- `C1`: Serialization boundaries and Little-Endian oracles:
  - Epoch 0 (`[0x00, 0x00, 0x00, 0x00]`) and Max uint32 `0xFFFFFFFF` (`[0xFF, 0xFF, 0xFF, 0xFF]`).
  - Signed 32-bit overflow boundary `0x80000000` (`[0x00, 0x00, 0x00, 0x80]`) and Y2038 boundary `0x7FFFFFFF` (`[0xFF, 0xFF, 0xFF, 0x7F]`).
  - Fractional float truncation via `Math.floor`.
  - Out-of-bounds timestamp rejection (`-1`, `4294967296`, `NaN`, `Infinity`).
  - Little-endian byte decomposition oracle across test vectors.
  - 10,000-iteration randomized uint32 fuzzing round-trip oracle.
  - **Exhaustive int16 timezone oracle: sweeps all 65,536 integers from -32,768 to +32,767 against two's complement little-endian bit formulas**.
  - Real-world global fractional and negative timezones: India (+330 min / UTC+5:30), Nepal (+345 min / UTC+5:45), Eucla (+525 min / UTC+8:45), Adelaide (+570 min / UTC+9:30), Chatham (+765 min / UTC+12:45), Kiritimati (+840 min / UTC+14:00), Newfoundland (-210 min / UTC-3:30), Marquesas (-570 min / UTC-9:30), Baker Island (-720 min / UTC-12:00), and int16 extremes (-32768, +32767).
  - Out-of-bounds timezone rejection (`-32769`, `32768`, `NaN`).
  - Sliced buffer offset support (`byteOffset > 0`).
  - Composite `ClockSyncData` roundtrip with extreme vectors.
- `C2`: Strict Zephyr GATT length enforcement:
  - Time payload rejects lengths 0, 1, 2, 3, 5, 6, 7, 8, 16, 64 bytes.
  - Timezone payload rejects lengths 0, 1, 3, 4, 5, 8 bytes.
  - Time Mode rejects lengths 0, 2, 3, 4, 8 bytes.
  - DST rejects lengths 0, 2, 3, 4, 8 bytes.
- `C3`: MockBleService fault injection, write sequences, and memory isolation:
  - Rejects invalid write lengths throwing `BT_ATT_ERR_INVALID_OFFSET` (0x07).
  - Memory isolation: mutating caller buffers after write does NOT corrupt internal GATT DB or write history.
  - Defensive copying on `readCharacteristic` and `getCharacteristicValue`.
  - Targeted write fault injection: fails only specified characteristic UUID, consumes fault, allows subsequent write.
  - Link loss simulation: disconnects session, triggers disconnect listeners, rejects subsequent writes and reads.
  - Exception resilience in disconnect listeners: a throwing listener does not prevent other registered listeners from receiving the event.
  - Preserves write history and sequential ordering.
- `C4`: Dual-criteria peripheral discovery & case-insensitivity:
  - Matches device name `F91_Jepler`.
  - Matches uppercase and lowercase Clock Service UUIDs.

### 1.3 Test, Typecheck, and Build Tool Results
1. **`npm test`**:
   ```
   ✓ tests/serialization.test.ts (20 tests)
   ✓ tests/mockBleService.test.ts (25 tests)
   ✓ tests/smoke.test.ts (6 tests)
   ✓ tests/challenge_m1.test.ts (16 tests)
   ✓ tests/challenge_m2.test.ts (28 tests)

   Test Files  5 passed (5)
        Tests  95 passed (95)
     Duration  927ms
   ```
2. **`npm run typecheck`**:
   `tsc --noEmit` exited with code 0 (zero errors).
3. **`npm run build`**:
   `tsc && vite build` built production bundle in 244ms with zero errors or warnings.

---

## 2. Logic Chain

1. **Empirical Verification of Serialization Fidelity**:
   - Firmware `clock_service.c` runs on Nordic ARM Cortex-M4 (32-bit little-endian architecture).
   - In `challenge_m2.test.ts`, all 65,536 possible 16-bit integers and 10,000 randomized 32-bit unsigned integers were subjected to bitwise decomposition and roundtrip serialization.
   - Every single value matched the expected little-endian memory layout bit-for-bit without distortion or sign-extension corruption.
2. **Firmware Contract & Fault Alignment**:
   - `clock_service.c` explicitly returns `BT_ATT_ERR_INVALID_OFFSET` (0x07) whenever `len != sizeof(...)`.
   - `challenge_m2.test.ts` confirmed that both the deserializer methods in `gattSerializer.ts` and the GATT write handler in `MockBleService` immediately reject payloads of length 0, 1, 2, 3, 5, 8 bytes with error messages matching `0x07`.
3. **Simulation Robustness & Fault Isolation**:
   - `MockBleService` safely isolates memory by cloning Uint8Array instances upon write and read.
   - Fault injection targets (such as failing next write on a specific UUID or simulating mid-session link loss) behave deterministically, and exception-throwing callbacks do not crash the service.
4. **Build & Type Safety Integrity**:
   - The codebase passes strict TypeScript compilation (`noUnusedLocals`, `strict: true`) and produces a clean production bundle.

---

## 3. Caveats

- Testing of live radio transmission (RF physical layer, packet loss over the air, Bluetooth controller hardware queueing) is conducted against the `MockBleService` simulation abstraction, as physical nRF52840 hardware cannot be connected to this CI runner environment.
- On real Android and iOS hardware, OS Bluetooth permissions must be granted by the user; these permissions were previously validated in the native manifests during Milestone 1.

---

## 4. Conclusion & Explicit Verdict

**Verdict: APPROVE**

Milestone 2 (BLE Engine & GATT Serialization Core) meets and exceeds all specification criteria, passes all edge cases under adversarial testing, and adheres 100% to the Zephyr RTOS firmware contracts.

### Challenge Summary
- **Overall risk assessment**: **LOW**
- **Test pass rate**: 100% (95 of 95 tests passing across 5 suites).
- **TypeScript errors**: 0
- **Build status**: PASS (244ms)

---

## 5. Verification Method

To independently reproduce the empirical findings of Challenger M2:

1. **Execute Vitest Suite**:
   ```bash
   cd /Users/jacobloesch/Documents/F91_Jepler/Software/companion_app
   npm test
   ```
   *Expected outcome*: 5 test files pass with 95/95 passing tests.

2. **Execute TypeScript Typecheck**:
   ```bash
   cd /Users/jacobloesch/Documents/F91_Jepler/Software/companion_app
   npm run typecheck
   ```
   *Expected outcome*: Code 0 with no diagnostic errors.

3. **Execute Production Bundle**:
   ```bash
   cd /Users/jacobloesch/Documents/F91_Jepler/Software/companion_app
   npm run build
   ```
   *Expected outcome*: Vite builds `dist/` cleanly in under 1 second.
