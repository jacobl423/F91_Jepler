# Forensic Audit Report: Milestone 2 — BLE Engine & GATT Serialization Core

**Author**: Forensic Auditor M2  
**Target**: Milestone 2 (`Software/companion_app`)  
**Profile**: General Project  
**Integrity Mode**: Development (per `ORIGINAL_REQUEST.md` line 8)  
**Verdict**: **CLEAN**  

---

## 1. Observation

### 1.1 Firmware Specification & GATT Contract Comparison
A direct comparison was performed between the Zephyr RTOS firmware source files and `src/ble/gattConstants.ts`:
- **Zephyr Firmware Header** (`Firmware/zephyr/src/services/clock_service.h` lines 8-17, 25-28):
  - Service UUID: `fa35b2f0-7989-11eb-9439-0242ac130002`
  - Time Characteristic UUID: `fa35b2f1-7989-11eb-9439-0242ac130002` (4-byte `uint32_t`)
  - Timezone Characteristic UUID: `fa35b2f2-7989-11eb-9439-0242ac130002` (2-byte `uint16_t` / signed `int16_t`)
  - Time Mode Characteristic UUID: `fa35b2f3-7989-11eb-9439-0242ac130002` (1-byte `uint8_t`)
  - DST Characteristic UUID: `fa35b2f4-7989-11eb-9439-0242ac130002` (1-byte `uint8_t`)
- **Zephyr Implementation Validation** (`Firmware/zephyr/src/services/clock_service.c` lines 28-30, 56-58, 84-86, 111-113):
  - In each characteristic write handler, incoming payload length is verified:
    `if (offset != 0 || len != sizeof(...)) { return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET); }`
  - Protocol error constant is `BT_ATT_ERR_INVALID_OFFSET` (0x07).
- **TypeScript Constants** (`Software/companion_app/src/ble/gattConstants.ts` lines 18-75):
  - UUIDs match the Zephyr firmware bitwise.
  - `CLOCK_PAYLOAD_LENGTHS`: `{ TIME: 4, TIMEZONE: 2, TIMEMODE: 1, DST: 1 }`.
  - `BT_ATT_ERR_INVALID_OFFSET = 0x07`.

### 1.2 Source Code Analysis (Phase 1)
- **GATT Serializer** (`Software/companion_app/src/ble/gattSerializer.ts`):
  - `serializeTime` (lines 43-60): allocates `new Uint8Array(4)`, initializes `new DataView(buffer.buffer)`, and executes `view.setUint32(0, Math.floor(timestamp), true)` (little-endian flag set to `true`). Rejects negative or > 0xFFFFFFFF values with `RangeError`.
  - `deserializeTime` (lines 66-75): verifies `bytes.byteLength === 4`, initializes `new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength)`, and returns `view.getUint32(0, true)`.
  - `serializeTimezone` (lines 81-98): allocates `new Uint8Array(2)`, initializes `new DataView(buffer.buffer)`, and executes `view.setInt16(0, Math.round(offsetMinutes), true)`. Rejects values outside `[-32768, 32767]` with `RangeError`.
  - `deserializeTimezone` (lines 104-113): verifies `bytes.byteLength === 2`, initializes `new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength)`, and returns `view.getInt16(0, true)`.
  - `serializeTimeMode` & `serializeDst` (lines 119-160): encodes boolean or numeric flags into 1-byte arrays.
  - Zero hardcoded test return values, zero look-up tables with pre-computed test answers, and zero facade methods.
- **Hardware Abstraction Layer & Mock BLE Service** (`Software/companion_app/src/ble/mockBleService.ts`):
  - Implements `BleClientInterface` with authentic internal state:
    - Maintains simulated clock registers (`watchState.clockTime`, `watchState.clockTimezone`, `watchState.clockTimeMode`, `watchState.clockDst`).
    - Maintains an in-memory GATT database (`Map<string, Uint8Array>`).
    - Enforces Zephyr RTOS error behavior: in lines 195-221, writes with invalid payload lengths throw `GATT Error 0x7 (BT_ATT_ERR_INVALID_OFFSET)`.
    - Tracks chronological write history in `writeHistory` array.
    - Provides programmable fault injection (`failNextConnection`, `failNextWrite`, `setWriteLatency`, `simulateDisconnect`).
- **Production BLE Service** (`Software/companion_app/src/ble/capacitorBleService.ts`):
  - Implements `BleClientInterface` delegating to `@capacitor-community/bluetooth-le` `BleClient`.
  - Converts data formats faithfully between `Uint8Array` and `DataView` (lines 154, 174).
  - Handles dual-criteria scanning (localName `F91_Jepler` or Clock Service UUID `fa35b2f0-7989-11eb-9439-0242ac130002`).
- **Pre-populated Artifact Check**:
  - `find /Users/jacobloesch/Documents/F91_Jepler/Software/companion_app -name '*.log' -o -name '*result*' -o -name '*output*'`:
  - Output contained only standard dependencies inside `node_modules` and vitest build cache. No pre-populated test report, mock logs, or attestation files were present in `src/` or `tests/`.

### 1.3 Behavioral Verification (Phase 2 Tool Runs)
Independent execution of test, typecheck, and build commands in `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app`:

1. **Test Suite Execution (`npm test`)**:
   ```
   > f91-jepler-companion@1.0.0 test
   > vitest run

    RUN  v5.0.3 /Users/jacobloesch/Documents/F91_Jepler/Software/companion_app

    ✓ tests/serialization.test.ts (20 tests) 5ms
    ✓ tests/mockBleService.test.ts (25 tests) 35ms
    ✓ tests/smoke.test.ts (6 tests) 24ms
    ✓ tests/challenge_m1.test.ts (16 tests) 100ms
    ✓ tests/challenge_m2.test.ts (28 tests) 571ms
      ✓ Challenger M2 Empirical Adversarial Stress Suite (28)
        ✓ C1: Serialization Boundary Conditions & Little-Endian Oracles (13)
          ✓ exhaustively verifies all 65,536 int16 timezone offsets against signed two-complement Little-Endian oracle 529ms

    Test Files  5 passed (5)
         Tests  95 passed (95)
      Start at  23:06:04
      Duration  1.06s
   ```

2. **TypeScript Compilation Check (`npm run typecheck`)**:
   ```
   > f91-jepler-companion@1.0.0 typecheck
   > tsc --noEmit
   [Exit code: 0, 0 diagnostic errors]
   ```

3. **Production Bundle Build (`npm run build`)**:
   ```
   > f91-jepler-companion@1.0.0 build
   > tsc && vite build

   vite v8.3.2 building client environment for production...
   transforming (1894) index.html✓ 1896 modules transformed.
   rendering chunks (1)...computing gzip size...
   dist/index.html                   0.53 kB │ gzip:  0.35 kB
   dist/assets/index-D-DiZYDv.css    8.36 kB │ gzip:  2.61 kB
   dist/assets/index-Bo7QYUZt.js   226.67 kB │ gzip: 71.33 kB
   ✓ built in 266ms
   [Exit code: 0]
   ```

4. **Independent Mathematical Oracle Verification**:
   Executed independent Node.js script using `Buffer.writeUInt32LE` and `Buffer.writeInt16LE`:
   - Timestamp `1700000000` (`0x6553F100`) -> `[0x00, 0xF1, 0x53, 0x65]` -> MATCH
   - Timezone `-300` min (EST) (`0xFED4`) -> `[0xD4, 0xFE]` -> MATCH
   - Timestamp `1791169728` (`0x6AC314C0`) -> `[0xC0, 0x14, 0xC3, 0x6A]` -> MATCH
   - Timestamp `758505600` (`0x2D35E080`) -> `[0x80, 0xE0, 0x35, 0x2D]` -> MATCH
   - Timezone `-480` min (PST) (`0xFE20`) -> `[0x20, 0xFE]` -> MATCH

---

## 2. Logic Chain

1. **Absence of Prohibited Patterns**:
   - Observations 1.1 and 1.2 demonstrate that `gattSerializer.ts`, `mockBleService.ts`, and `capacitorBleService.ts` compute results dynamically using standard JavaScript `DataView` operations without fixed value lookup tables or hardcoded responses.
   - Observation 1.2 confirms that no pre-existing log files or fake result artifacts existed in the workspace prior to verification.
2. **Strict Adherence to Firmware Contract**:
   - Observations 1.1 and 1.2 show that `gattConstants.ts` defines identical UUIDs and payload lengths as `Firmware/zephyr/src/services/clock_service.h` and `clock_service.c`.
   - The Zephyr error code `BT_ATT_ERR_INVALID_OFFSET = 0x07` is accurately implemented and tested for payload length rejections in both serialization decoders and `MockBleService`.
3. **Execution Robustness & Completeness**:
   - Observation 1.3 shows that all 95 tests across 5 test suites pass cleanly.
   - The test suite includes 28 adversarial tests from `challenge_m2.test.ts` which exhaustively checked all 65,536 signed int16 timezone integers against a two's-complement LE bit-shifting oracle.
   - Typechecking and Vite production builds complete with exit code 0.
4. **Verdict Deduction**:
   - Because all forensic checks (Hardcoded output detection, Facade detection, Pre-populated artifact detection, Behavioral verification, and Mathematical oracle verification) pass without a single failure, the work product satisfies all integrity constraints under the Development mode baseline.

---

## 3. Caveats

- Physical Bluetooth hardware radio testing against a real nRF52840 SoC device was not executed (as physical hardware is external to this headless environment). However, `MockBleService` accurately simulates the firmware GATT server state machine, and `CapacitorBleService` is verified to link the native `@capacitor-community/bluetooth-le` plugin methods.

---

## 4. Conclusion

**Verdict: CLEAN**

Milestone 2 (BLE Engine & GATT Serialization Core) represents a genuine, mathematically sound, and specification-compliant implementation:
- Little-endian DataView encoding and decoding are fully implemented with boundary checks.
- Zephyr RTOS UUIDs, data lengths, and error responses match firmware contracts.
- HAL interface decoupling enables seamless swapping between simulated and native BLE drivers.
- All 95 tests pass, strict TypeScript compilation reports zero errors, and Vite production bundle builds cleanly.

---

## 5. Verification Method

To independently reproduce and verify this audit:

1. **Verify Test Suite**:
   ```bash
   cd /Users/jacobloesch/Documents/F91_Jepler/Software/companion_app
   npm test
   ```
   *Expected*: 5 test files pass (95/95 tests passed, 0 failed).

2. **Verify TypeScript Strict Compilation**:
   ```bash
   cd /Users/jacobloesch/Documents/F91_Jepler/Software/companion_app
   npm run typecheck
   ```
   *Expected*: Exit code 0, 0 errors.

3. **Verify Production Bundle**:
   ```bash
   cd /Users/jacobloesch/Documents/F91_Jepler/Software/companion_app
   npm run build
   ```
   *Expected*: Exit code 0, Vite builds `dist/` cleanly.

4. **Verify Independent Math Oracle**:
   ```bash
   node -e '
   const b1 = Buffer.alloc(4); b1.writeUInt32LE(1700000000, 0);
   console.log("Time LE:", Array.from(b1));
   const b2 = Buffer.alloc(2); b2.writeInt16LE(-300, 0);
   console.log("TZ LE:", Array.from(b2));
   '
   ```
   *Expected*: `[0, 241, 83, 101]` and `[212, 254]`.
