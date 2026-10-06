# E2E Test Infra: F91_Jepler Mobile Companion App

## Test Philosophy
- Opaque-box, requirement-driven verification derived strictly from `ORIGINAL_REQUEST.md` and Zephyr firmware GATT specifications (`clock_service.c`).
- Dual verification channel:
  1. Headless Vitest runner executing 100% in Node 26 without physical device requirements.
  2. Byte-exact comparison against fixed little-endian test vectors and state transition assertions.

## Feature Inventory
| # | Feature | Source | Tier 1 (Coverage) | Tier 2 (Boundary) | Tier 3 (Pairwise) | Tier 4 (Scenario) |
|---|---------|--------|:-----------------:|:-----------------:|:-----------------:|:-----------------:|
| 1 | Time Serialization (4B LE) | R3, clock_service.c | ≥5 | ≥5 | ✓ | ✓ |
| 2 | Timezone Serialization (2B LE) | R3, clock_service.c | ≥5 | ≥5 | ✓ | ✓ |
| 3 | Time Mode Serialization (1B) | R3, clock_service.c | ≥5 | ≥5 | ✓ | ✓ |
| 4 | DST Serialization (1B) | R3, clock_service.c | ≥5 | ≥5 | ✓ | ✓ |
| 5 | BLE Peripheral Discovery Filter | R2, main.c | ≥5 | ≥5 | ✓ | ✓ |
| 6 | Connection State Machine | R2, R5 | ≥5 | ≥5 | ✓ | ✓ |
| 7 | Sequential GATT Sync Pipeline | R3, R5 | ≥5 | ≥5 | ✓ | ✓ |
| 8 | UI State & Feedback Behavior | R4, R5 | ≥5 | ≥5 | ✓ | ✓ |

## Test Architecture
- **Test Runner**: Vitest 5 (`npm run test`)
- **Assertions**: `expect(Uint8Array).toEqual(...)`, `expect(state).toBe(...)`
- **Mock BLE Engine**: Scriptable `MockBleService` simulating realistic connection latency, GATT responses, and failure injection.

## Coverage Thresholds
- **Tier 1 (Feature Coverage)**: ≥40 test cases (≥5 per feature across 8 features)
- **Tier 2 (Boundary & Corner Cases)**: ≥40 test cases (epoch 0, max uint32, negative/positive/half-hour timezones, off-by-one payload lengths)
- **Tier 3 (Cross-Feature Combinations)**: ≥15 test cases (mode x DST combinations, disconnect during active sync, scan timeout recovery)
- **Tier 4 (Real-World Application Scenarios)**: ≥5 realistic scenarios (cold launch to sync, reconnection after signal drop, manual multiple syncs, mock watch state persistence)
- **Total Minimum**: ≥100 test cases
