# Handoff Report: Reviewer M2 — Milestone 2 Review & Adversarial Audit

**Author**: Reviewer M2 (Reviewer & Adversarial Critic)  
**Recipient**: Orchestrator (`597ea6c0-a703-4980-a746-5cc67a9a63e2`)  
**Workspace**: `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app`  
**Target Milestone**: Milestone 2 (BLE Engine & GATT Serialization Core)  
**Date**: 2026-10-05T04:07:00Z  
**Verdict**: **APPROVE**

---

## 1. Observation

### 1.1 Firmware Baseline Verification
Direct inspection of firmware files confirms the GATT protocol contracts:
- `Firmware/zephyr/src/services/clock_service.h`:
  - Line 9: `#define BT_UUID_CLOCK_SERVICE_VAL BT_UUID_128_ENCODE(0xfa35b2f0, 0x7989, 0x11eb, 0x9439, 0x0242ac130002)`
  - Line 11: `#define BT_UUID_CLOCK_TIME_CHAR_VAL BT_UUID_128_ENCODE(0xfa35b2f1, 0x7989, 0x11eb, 0x9439, 0x0242ac130002)`
  - Line 13: `#define BT_UUID_CLOCK_TIMEZONE_CHAR_VAL BT_UUID_128_ENCODE(0xfa35b2f2, 0x7989, 0x11eb, 0x9439, 0x0242ac130002)`
  - Line 15: `#define BT_UUID_CLOCK_TIMEMODE_CHAR_VAL BT_UUID_128_ENCODE(0xfa35b2f3, 0x7989, 0x11eb, 0x9439, 0x0242ac130002)`
  - Line 17: `#define BT_UUID_CLOCK_DST_CHAR_VAL BT_UUID_128_ENCODE(0xfa35b2f4, 0x7989, 0x11eb, 0x9439, 0x0242ac130002)`
- `Firmware/zephyr/src/services/clock_service.c`:
  - Lines 28-32:
    ```c
    if (offset != 0 || len != sizeof(uint32_t)) {
        return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
    }
    clock_time_val = *((const uint32_t *)buf);
    ```
    Confirms Time is strictly 4 bytes (`sizeof(uint32_t)`). Little-endian ARM Cortex-M4 pointer dereference requires byte 0 as LSB.
  - Lines 56-60:
    ```c
    if (offset != 0 || len != sizeof(uint16_t)) {
        return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
    }
    clock_timezone_val = *((const uint16_t *)buf);
    ```
    Confirms Timezone is strictly 2 bytes (`sizeof(uint16_t)`), little-endian.
  - Lines 84-88:
    ```c
    if (offset != 0 || len != sizeof(uint8_t)) {
        return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
    }
    clock_timemode_val = *((const uint8_t *)buf);
    ```
    Confirms Time Mode is strictly 1 byte (`sizeof(uint8_t)`).
  - Lines 111-115:
    ```c
    if (offset != 0 || len != sizeof(uint8_t)) {
        return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
    }
    clock_dst_val = *((const uint8_t *)buf);
    ```
    Confirms DST is strictly 1 byte (`sizeof(uint8_t)`).

### 1.2 Companion App Implementation Inspection
Inspected all source files in `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app`:
1. `src/ble/gattConstants.ts`:
   - Line 12: `F91_DEVICE_NAME = 'F91_Jepler'`
   - Lines 18-46: UUID constants match Zephyr definitions verbatim down to the casing.
   - Lines 55-60: `CLOCK_PAYLOAD_LENGTHS` defines `TIME: 4`, `TIMEZONE: 2`, `TIMEMODE: 1`, `DST: 1`.
   - Line 75: `BT_ATT_ERR_INVALID_OFFSET = 0x07` (standard Bluetooth ATT specification error code).
2. `src/ble/gattSerializer.ts`:
   - Lines 56-59: `serializeTime` uses `view.setUint32(0, Math.floor(timestamp), true)` — explicit little-endian flag.
   - Lines 66-75: `deserializeTime` validates `bytes.byteLength === 4`, and extracts `view.getUint32(0, true)` using `bytes.byteOffset` and `bytes.byteLength`.
   - Lines 94-97: `serializeTimezone` uses `view.setInt16(0, Math.round(offsetMinutes), true)` — explicit little-endian signed 16-bit integer.
   - Lines 104-113: `deserializeTimezone` validates `bytes.byteLength === 2` and extracts `view.getInt16(0, true)`.
   - Lines 120-130: `serializeTimeMode` produces 1 byte (0 for 12h, 1 for 24h).
   - Lines 150-160: `serializeDst` produces 1 byte (0 for standard, 1 for DST).
   - Lines 203-208: `isDateInDst` uses `Math.max(janOffset, julOffset)` to correctly handle both Northern and Southern hemispheres.
3. `src/ble/bleClientInterface.ts`:
   - Conforms 100% to `PROJECT.md` interface contracts, adding clean disconnect listener types and optional read support.
4. `src/ble/mockBleService.ts`:
   - Full simulated GATT database and watch registers (`clockTime`, `clockTimezone`, `clockTimeMode`, `clockDst`).
   - Lines 193-224: Validates payload lengths against `CLOCK_PAYLOAD_LENGTHS`, throwing `BT_ATT_ERR_INVALID_OFFSET` (0x07) error message matching Zephyr error semantics.
   - Fault injection API: `failNextConnection`, `failNextWrite`, `setWriteLatency`, `simulateDisconnect`.
5. `src/ble/capacitorBleService.ts`:
   - Production driver using `@capacitor-community/bluetooth-le`.
   - Lines 85-103: `matchesF91Jepler` executes dual-criteria scan filtering (matches name `F91_Jepler` OR Clock Service UUID `fa35b2f0-7989-11eb-9439-0242ac130002`).
   - Line 154: `const dataView = new DataView(data.buffer, data.byteOffset, data.byteLength);` properly passes offset and length.

### 1.3 Independent Verification Execution
Executed the test and build pipeline in `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app`:
- Command: `npm test`
  - Output:
    ```
    ✓ tests/serialization.test.ts (20 tests)
    ✓ tests/mockBleService.test.ts (25 tests)
    ✓ tests/smoke.test.ts (6 tests)
    ✓ tests/challenge_m1.test.ts (16 tests)

    Test Files  4 passed (4)
    Tests       67 passed (67)
    ```
- Command: `npm run typecheck`
  - Output: `tsc --noEmit` exited with code 0 and 0 errors.
- Command: `npm run build`
  - Output: `tsc && vite build` built `dist/` cleanly in 238ms with no warnings.

---

## 2. Logic Chain

1. **Little-Endian Endianness Conformance**:
   - Observation 1.1 establishes that Zephyr RTOS on ARM Cortex-M4 directly casts buffer pointers to `uint32_t` and `uint16_t`.
   - Observation 1.2 establishes that `gattSerializer.ts` explicitly sets the `littleEndian = true` flag on all `setUint32`, `getUint32`, `setInt16`, and `getInt16` calls.
   - Observation 1.3 demonstrates that test vectors covering positive, negative, zero, maximum uint32, and known timestamps (e.g. `1700000000` -> `0x00, 0xF1, 0x53, 0x65`; `-300` -> `0xD4, 0xFE`) pass bit-for-bit.
   - Therefore, byte ordering is verified bitwise compatible with the Zephyr firmware.

2. **Payload Size Guard Conformance**:
   - Observation 1.1 reveals that Zephyr `clock_service.c` aborts with `BT_ATT_ERR_INVALID_OFFSET` (0x07) if `len != sizeof(...)`.
   - Observation 1.2 demonstrates that `MockBleService` and deserializers validate `byteLength` against `CLOCK_PAYLOAD_LENGTHS` and throw `BT_ATT_ERR_INVALID_OFFSET` on length mismatch.
   - Observation 1.3 confirms tests `tests/serialization.test.ts` (T3) and `tests/mockBleService.test.ts` (S4) exercise boundary cases (0B, 1B, 2B, 3B, 5B) and verify expected rejection.
   - Therefore, payload validation is completely aligned with firmware behavior.

3. **Integrity & Authenticity Audit**:
   - Inspected source code for hardcoded test fixtures, facade mocks, or bypassed logic.
   - All transformations in `gattSerializer.ts` are pure binary operations via `DataView`.
   - `MockBleService` maintains a genuine in-memory GATT store, updates watch registers on write, and tracks chronological write records.
   - `CapacitorBleService` integrates with `@capacitor-community/bluetooth-le` APIs.
   - No signs of cheating, dummy facades, or shortcuts exist.

4. **Interface Contract Conformance**:
   - `PROJECT.md` §Interface Contracts defines `BleDevice`, `BleClientInterface`, `ClockSyncData`, and `SerializedClockPayload`.
   - Implementation files in `src/ble/` export all required types and function signatures without breaking variations.
   - Downstream Milestones (M3 State Machine, M4 UI) can safely consume these abstractions.

---

## 3. Caveats

- **Physical BLE Radio Testing**: Verification was performed against the Vitest unit/integration test suite, simulated GATT server (`MockBleService`), and mocked `@capacitor-community/bluetooth-le` driver. Over-the-air RF testing on physical hardware was not conducted during this software review (appropriate for software unit milestone).
- **Timezone Naming in Firmware**: In `clock_service.h`, timezone is typed as `uint16_t` while representing signed minutes from UTC (two's complement). `gattSerializer.ts` correctly handles this via `setInt16`/`getInt16`.

---

## 4. Conclusion

Milestone 2 (BLE Engine & GATT Serialization Core) is **APPROVED**.
The implementation satisfies all requirements from `ORIGINAL_REQUEST.md` (§R2, §R3, §R5) and `PROJECT.md`:
- Strict little-endian serialization matching Zephyr `clock_service.c` (4 bytes Time, 2 bytes Timezone, 1 byte Mode, 1 byte DST).
- Complete error enforcement returning `BT_ATT_ERR_INVALID_OFFSET` on size mismatch.
- Clean `BleClientInterface` HAL abstraction.
- Robust `MockBleService` with state tracking and fault injection for automated testing.
- Complete `CapacitorBleService` for native Android and iOS runtime.
- 100% test pass rate (67/67 tests), clean typecheck, and successful production build.

---

## 5. Verification Method

To independently reproduce this verification:

1. **Verify Unit Tests**:
   ```bash
   cd /Users/jacobloesch/Documents/F91_Jepler/Software/companion_app
   npm test
   ```
   *Expected*: 4 test files pass, 67 tests pass.

2. **Verify TypeScript Types**:
   ```bash
   cd /Users/jacobloesch/Documents/F91_Jepler/Software/companion_app
   npm run typecheck
   ```
   *Expected*: Exits with code 0.

3. **Verify Production Bundle Build**:
   ```bash
   cd /Users/jacobloesch/Documents/F91_Jepler/Software/companion_app
   npm run build
   ```
   *Expected*: Vite builds bundle to `dist/` cleanly.

4. **Inspect Firmware Matching Code**:
   - Inspect `Firmware/zephyr/src/services/clock_service.c` lines 28-115.
   - Compare with `Software/companion_app/src/ble/gattSerializer.ts` lines 43-167 and `Software/companion_app/src/ble/gattConstants.ts` lines 18-75.

---

## Review & Challenge Summary

### Review Summary
**Verdict**: **APPROVE**

### Findings
- **Minor Finding 1 (Code Quality / Documentation)**: In `clock_service.h`, `clock_timezone_val` is declared `uint16_t` while representing signed minutes. `gattSerializer.ts` handles this properly via signed int16 two's complement (`setInt16`/`getInt16`).
- **Commendation**: `gattSerializer.ts` correctly preserves `bytes.byteOffset` when constructing `DataView` instances (`new DataView(bytes.buffer, bytes.byteOffset, bytes.byteLength)`), preventing buffer-offset bugs when dealing with sliced byte arrays.
- **Commendation**: `isDateInDst` correctly accommodates both Northern and Southern hemisphere daylight saving rules via `Math.max(jan, jul)`.

### Verified Claims
- Little-endian byte ordering matches Zephyr `clock_service.c` (4B Time, 2B TZ, 1B Mode, 1B DST) → verified via `view_file` on `clock_service.c` and `npm test` → PASS.
- Serialization and deserialization round-trips for test vectors 1-9 → verified via `tests/serialization.test.ts` → PASS.
- Strict Zephyr ATT size error handling (`BT_ATT_ERR_INVALID_OFFSET` 0x07) → verified via `tests/mockBleService.test.ts` → PASS.
- Dual-criteria peripheral scan discovery → verified via `tests/mockBleService.test.ts` → PASS.
- Clean compilation and build → verified via `npm run typecheck` and `npm run build` → PASS.

### Coverage Gaps
- None for Milestone 2 scope.

### Adversarial Challenge Summary
**Overall risk assessment**: LOW
- **Assumption Tested**: Does DataView endianness match Cortex-M4 pointer dereference across negative numbers? Result: Two's complement bit patterns (`-300` -> `[0xD4, 0xFE]`) match bitwise.
- **Boundary Stress Tested**: Tested 0, 4294967295, negative numbers, NaNs, infinities, empty buffers, oversized buffers. All throw proper exceptions.
- **Fault Injection Tested**: Verified `failNextConnection`, `failNextWrite`, `setWriteLatency`, and unexpected disconnect listeners.
