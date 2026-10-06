# Handoff Report: Functional Requirements, State Machine, GATT Protocol & 4-Tier Test Hierarchy

**Author**: Survey Explorer 3 (Requirements & Testing Explorer)  
**Recipient**: Orchestrator / Lead Team (`597ea6c0-a703-4980-a746-5cc67a9a63e2`)  
**Workspace**: `/Users/jacobloesch/Documents/F91_Jepler`  
**Target Module**: `/Users/jacobloesch/Documents/F91_Jepler/Software/companion_app`  
**Timestamp**: 2026-10-05T03:13:00Z  

---

## 1. Observation

Direct observations from inspection of the repository specifications, firmware implementations, and configuration files:

### 1.1 Original Request Specifications
- **File**: `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md`
  - Lines 12-17:
    ```markdown
    - **Device Name**: `F91_Jepler`
    - **Clock Service UUID**: `fa35b2f0-7989-11eb-9439-0242ac130002`
    - **Time Characteristic UUID**: `fa35b2f1-7989-11eb-9439-0242ac130002` (uint32 Unix epoch seconds, little-endian)
    - **Timezone Characteristic UUID**: `fa35b2f2-7989-11eb-9439-0242ac130002` (uint16 offset in minutes or minutes from UTC, little-endian)
    - **Time Mode Characteristic UUID**: `fa35b2f3-7989-11eb-9439-0242ac130002` (uint8: 0 for 12-hour, 1 for 24-hour)
    - **DST Characteristic UUID**: `fa35b2f4-7989-11eb-9439-0242ac130002` (uint8: 0 for standard time, 1 for daylight saving time)
    ```
  - Lines 42-56 (Acceptance Criteria):
    ```markdown
    - Scan mechanism filters for peripheral name `F91_Jepler` or Clock Service UUID `fa35b2f0-7989-11eb-9439-0242ac130002`.
    - Connection manager accurately reflects `disconnected`, `scanning`, `connecting`, and `connected` states.
    - Disconnection events update UI status cleanly without throwing unhandled exceptions.
    - Time payload encodes current Unix epoch seconds as a 4-byte unsigned integer in little-endian format.
    - Timezone payload encodes the timezone offset as a 2-byte unsigned integer in little-endian format.
    - Timemode and DST payloads serialize as 1-byte unsigned values conforming to firmware definitions.
    - Manual sync action sends writes to the corresponding GATT characteristics in sequence.
    - Unit test suite executes and passes 100% of tests.
    - Serialization tests validate exact byte arrays against fixed timestamp and timezone test vectors.
    ```

### 1.2 Zephyr RTOS Firmware Clock Service Implementation
- **File**: `/Users/jacobloesch/Documents/F91_Jepler/Firmware/zephyr/src/services/clock_service.h`
  - Lines 8-17:
    ```c
    #define BT_UUID_CLOCK_SERVICE_VAL \
    	BT_UUID_128_ENCODE(0xfa35b2f0, 0x7989, 0x11eb, 0x9439, 0x0242ac130002)
    #define BT_UUID_CLOCK_TIME_CHAR_VAL \
    	BT_UUID_128_ENCODE(0xfa35b2f1, 0x7989, 0x11eb, 0x9439, 0x0242ac130002)
    #define BT_UUID_CLOCK_TIMEZONE_CHAR_VAL \
    	BT_UUID_128_ENCODE(0xfa35b2f2, 0x7989, 0x11eb, 0x9439, 0x0242ac130002)
    #define BT_UUID_CLOCK_TIMEMODE_CHAR_VAL \
    	BT_UUID_128_ENCODE(0xfa35b2f3, 0x7989, 0x11eb, 0x9439, 0x0242ac130002)
    #define BT_UUID_CLOCK_DST_CHAR_VAL \
    	BT_UUID_128_ENCODE(0xfa35b2f4, 0x7989, 0x11eb, 0x9439, 0x0242ac130002)
    ```
  - Lines 25-28:
    ```c
    typedef void (*clock_time_write_cb_t)(uint32_t timestamp);
    typedef void (*clock_timezone_write_cb_t)(uint16_t tz);
    typedef void (*clock_timemode_write_cb_t)(uint8_t mode);
    typedef void (*clock_dst_write_cb_t)(uint8_t dst);
    ```

- **File**: `/Users/jacobloesch/Documents/F91_Jepler/Firmware/zephyr/src/services/clock_service.c`
  - Lines 28-39 (`write_clock_time`):
    ```c
    if (offset != 0 || len != sizeof(uint32_t)) {
        return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
    }
    clock_time_val = *((const uint32_t *)buf);
    ```
  - Lines 56-67 (`write_clock_timezone`):
    ```c
    if (offset != 0 || len != sizeof(uint16_t)) {
        return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
    }
    clock_timezone_val = *((const uint16_t *)buf);
    ```
  - Lines 84-95 (`write_clock_timemode`):
    ```c
    if (offset != 0 || len != sizeof(uint8_t)) {
        return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
    }
    clock_timemode_val = *((const uint8_t *)buf);
    ```
  - Lines 111-122 (`write_clock_dst`):
    ```c
    if (offset != 0 || len != sizeof(uint8_t)) {
        return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
    }
    clock_dst_val = *((const uint8_t *)buf);
    ```

- **File**: `/Users/jacobloesch/Documents/F91_Jepler/Firmware/zephyr/prj.conf`
  - Line 11:
    ```ini
    CONFIG_BT_DEVICE_NAME="F91_Jepler"
    ```

- **File**: `/Users/jacobloesch/Documents/F91_Jepler/Firmware/zephyr/src/main.c`
  - Lines 15-22:
    ```c
    static const struct bt_data ad[] = {
        BT_DATA_BYTES(BT_DATA_FLAGS, (BT_LE_AD_GENERAL | BT_LE_AD_NO_BREDR)),
        BT_DATA(BT_DATA_NAME_COMPLETE, CONFIG_BT_DEVICE_NAME, sizeof(CONFIG_BT_DEVICE_NAME) - 1),
    };
    static const struct bt_data sd[] = {
        BT_DATA_BYTES(BT_DATA_UUID128_SOME, BT_UUID_NOTIFICATION_SERVICE_VAL),
    };
    ```

### 1.3 Legacy TI-RTOS Implementation
- **File**: `/Users/jacobloesch/Documents/F91_Jepler/Firmware/f91_kepler_app/Application/f91_clock.h`
  - Lines 51-57:
    ```c
    #define DEFAULT_TIME    758505600
    #define TZ_HST          36000
    #define TZ_AKST         32400
    #define TZ_PST          28800
    #define TZ_MST          25200
    #define TZ_CST          21600
    #define TZ_EST          18000
    ```
- **File**: `/Users/jacobloesch/Documents/F91_Jepler/Firmware/f91_kepler_app/Application/f91_clock.c`
  - Lines 350-356:
    ```c
    t1 = time(NULL);
    t1 = t1 - _F91Clock_getTimeZone();
    if(_F91Clock_getDst()){
        t1 += 3600;
    }
    ```

---

## 2. Logic Chain

1. **Strict Payload Length Constraints**:
   - `write_clock_time`, `write_clock_timezone`, `write_clock_timemode`, and `write_clock_dst` in `clock_service.c` explicitly check `len != sizeof(...)` and `offset != 0`, immediately returning `BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET)` on any mismatch.
   - Therefore, the companion app GATT serializer **must strictly output exact byte buffers**:
     - Time: exactly 4 bytes (`uint32` little-endian).
     - Timezone: exactly 2 bytes (`uint16` little-endian).
     - Time Mode: exactly 1 byte (`uint8`).
     - DST: exactly 1 byte (`uint8`).
   - Any off-by-one or oversized write will fail with an ATT protocol error on the watch.

2. **BLE Discovery Dual Filter Requirement**:
   - `Firmware/zephyr/src/main.c` lines 15-22 shows the peripheral broadcasts `CONFIG_BT_DEVICE_NAME` ("F91_Jepler") in its primary advertisement packet (`ad`), while service UUIDs may reside in the scan response data or GATT profile.
   - Therefore, the scanner must implement dual-criteria filtering: accept peripherals matching local name `F91_Jepler` OR advertising Clock Service UUID `fa35b2f0-7989-11eb-9439-0242ac130002`.

3. **Sequential GATT Write Protocol Requirement**:
   - The Bluetooth Low Energy Attribute Protocol (ATT) typically restricts sequential GATT Write Requests to one unacknowledged request at a time per link (requiring ATT Write Response before sending next).
   - Therefore, the manual synchronization workflow must execute sequentially with asynchronous chaining (`write(Time) -> await ACK -> write(Timezone) -> await ACK -> write(TimeMode) -> await ACK -> write(DST) -> await ACK`).

4. **Timezone Representation Strategy**:
   - `ORIGINAL_REQUEST.md` specifies `uint16 offset in minutes or minutes from UTC, little-endian`.
   - In standard UTC offsets: minutes offset can be negative (e.g. UTC-8 is -480 minutes). In standard two's complement 16-bit, `-480` is `0xFE20` (65056). Alternatively, positive magnitude or legacy second offsets (`28800` = `0x7080`) exist in legacy firmware.
   - Therefore, the testing suite must include test vectors for standard minutes offset (both two's complement and magnitude) as well as boundary values.

5. **Automated Testing Without Hardware**:
   - Since development occurs in an emulated / host development environment without dedicated physical Bluetooth radios attached, testing must rely on an injectable `MockBleAdapter` that accurately simulates device advertising, state transitions, GATT read/write responses, and fault injections (timeouts, mid-sync disconnections).

---

## 3. Caveats

1. **Timezone Representation Variance**:
   - The original specification notes `uint16 offset in minutes or minutes from UTC`. Legacy TI code (`f91_clock.h`) used seconds (`28800` for PST). The modern Zephyr firmware simply stores and passes `uint16_t tz` to `clock_cbs->tz_cb`.
   - The serializer should default to standard minutes offset from UTC (as required by `ORIGINAL_REQUEST.md`), while test suites should validate exact byte encodings for both minute-based test vectors and edge cases.
2. **Write Response Types (Write Request vs Write Command)**:
   - In Zephyr, `BT_GATT_PERM_WRITE` permits both Write with Response (`BT_ATT_OP_WRITE_REQ`) and Write without Response (`BT_ATT_OP_WRITE_CMD`). For reliability and synchronicity, the companion app should use Write with Response.
3. **OS Permission Sandboxes**:
   - iOS and Android impose strict runtime permission requirements (Bluetooth scan/connect and location). In unit and mock testing, mock adapters simulate permission granted/denied states directly.

---

## 4. Conclusion & Complete Requirements Specification

### 4.1 Connection State Machine Specification

```
                               +-------------------+
                               |                   |
                               |   DISCONNECTED    |<--------------------+
                               |                   |                     |
                               +-------------------+                     |
                                 |               ^                       |
                   START_SCAN    |               | STOP_SCAN /           |
                   (BT enabled)  |               | SCAN_TIMEOUT          |
                                 v               |                       |
                               +-------------------+                     |
                               |                   |                     |
                               |     SCANNING      |                     |
                               |                   |                     |
                               +-------------------+                     |
                                 |                                       |
                   SELECT_DEVICE | (Target F91_Jepler)                   |
                                 v                                       |
                               +-------------------+                     |
                               |                   |                     |
                               |    CONNECTING     |---------------------+
                               |                   | CONNECT_FAILED /    |
                               +-------------------+ TIMEOUT             |
                                 |                                       |
                   CONNECT_OK &  |                                       |
                   SERVICES_DISC |                                       |
                                 v                                       |
                               +-------------------+                     |
                   +---------->|                   |                     |
                   |           |     CONNECTED     |---------------------+
                   |           |                   | USER_DISCONNECT /   |
                   |           +-------------------+ LINK_LOST           |
                   |             |               ^                       |
        SYNC_DONE  |  START_SYNC |               | SYNC_FAIL             |
        (All 4 ACK)|             v               | (Timeout/GATT err)    |
                   |           +-------------------+                     |
                   +-----------|      SYNCING      |---------------------+
                               |   (GATT Writes)   | LINK_LOST (mid-sync)|
                               +-------------------+                     |
                                                                         |
                               +-------------------+                     |
                               |       ERROR       |---------------------+
                               +-------------------+   DISMISS / RESET
```

#### Detailed State Transition Matrix

| Current State | Trigger / Event | Precondition / Guard | Target State | Internal Actions & UI Feedback |
|---|---|---|---|---|
| `DISCONNECTED` | `START_SCAN` | Bluetooth adapter Powered On | `SCANNING` | Clear previous device list; start scan timer (15s timeout); invoke BLE scan API. UI shows blue pulsing status and spinner. |
| `DISCONNECTED` | `START_SCAN` | Bluetooth Powered Off / Unauthorized | `ERROR` | Set error message ("Bluetooth is powered off or unauthorized"). UI shows alert banner. |
| `SCANNING` | `STOP_SCAN` | Scan active | `DISCONNECTED` | Stop BLE scan API; cancel scan timer. UI reverts to idle disconnected. |
| `SCANNING` | `SCAN_TIMEOUT` | 15s elapsed without user selection | `DISCONNECTED` | Stop BLE scan API. Discovered devices remain in list for selection. UI indicates scan completed. |
| `SCANNING` | `SELECT_DEVICE` | Target peripheral selected | `CONNECTING` | Stop scanner; call connect API with peripheral ID; start connect timer (15s). UI shows amber spinner on device row. |
| `CONNECTING` | `CONNECT_SUCCESS` | Link established, Clock Service found | `CONNECTED` | Discover and cache 4 characteristic handles (`0xB2F1-0xB2F4`). Cancel timer. UI displays green "Connected" badge and enables "Sync Clock" button. |
| `CONNECTING` | `CONNECT_FAILED` | Timeout (15s) or GATT link error | `ERROR` / `DISCONNECTED` | Clear pending connection handle. Display error notification ("Failed to connect to F91_Jepler"). |
| `CONNECTING` | `MISSING_SERVICE` | Peripheral lacks Clock Service UUID | `ERROR` | Teardown link. Display error ("Device is not an F91_Jepler watch"). |
| `CONNECTED` | `USER_DISCONNECT` | User clicks Disconnect button | `DISCONNECTED` | Invoke disconnect API; reset characteristic handles. UI disables "Sync Clock" button and clears active device. |
| `CONNECTED` | `LINK_LOST` | Watch out-of-range, rebooted, or power loss | `DISCONNECTED` | Detect GATT disconnection callback cleanly without exception; clean state. UI displays banner ("Connection lost"). |
| `CONNECTED` | `START_SYNC` | User taps "Sync Clock Now" | `SYNCING` | Lock sync button (prevent double-taps); initialize sequence at Step 1 (Time). UI displays active sync progress bar. |
| `SYNCING` | `WRITE_ACK` | Current characteristic write succeeds | `SYNCING` / `CONNECTED` | Advance to next characteristic (Time -> Timezone -> Mode -> DST). If step 4 completes, transition to `CONNECTED`. Update "Last synced: [timestamp]" badge. |
| `SYNCING` | `WRITE_TIMEOUT` | Characteristic write hangs (>5s) or error | `CONNECTED` | Log GATT failure; display error badge ("Sync failed: Timeout"); keep link open. Re-enable sync button. |
| `SYNCING` | `LINK_LOST` | Watch disconnects during sequence | `DISCONNECTED` | Abort sequence; clear pending operations; show error ("Disconnected during sync"). |

---

### 4.2 GATT Characteristics Specifications & Exact Test Vectors

#### GATT Characteristics Table

| Characteristic | UUID | Data Type | Byte Length | Endianness | Permitted Values | Firmware Target Variable |
|---|---|---|---|---|---|---|
| **Time** | `fa35b2f1-7989-11eb-9439-0242ac130002` | `uint32` | 4 bytes | Little-Endian | `0` to `4294967295` (Unix epoch sec) | `clock_time_val` |
| **Timezone** | `fa35b2f2-7989-11eb-9439-0242ac130002` | `uint16` | 2 bytes | Little-Endian | `0` to `65535` (Minutes from UTC or two's comp) | `clock_timezone_val` |
| **Time Mode**| `fa35b2f3-7989-11eb-9439-0242ac130002` | `uint8`  | 1 byte  | N/A | `0` (12-hour), `1` (24-hour) | `clock_timemode_val` |
| **DST**      | `fa35b2f4-7989-11eb-9439-0242ac130002` | `uint8`  | 1 byte  | N/A | `0` (Standard), `1` (Daylight Saving) | `clock_dst_val` |

#### Exact Serialization Test Vectors

##### Test Vector 1: Standard Current Dispatch Timestamp (2026-10-05T03:08:48Z, UTC-5 EST, 12h Mode, Standard Time)
- **Time**: `1791169728` (`0x6AC66AC0`) -> LE Bytes: `[0xC0, 0x6A, 0xC6, 0x6A]` (4 bytes)
- **Timezone**: `-300` minutes (UTC-5 EST) -> Two's comp uint16: `65236` (`0xFED4`) -> LE Bytes: `[0xD4, 0xFE]` (2 bytes)
  - *(Alternative magnitude representation)*: `300` minutes (`0x012C`) -> LE Bytes: `[0x2C, 0x01]`
- **Time Mode**: `0` (12-hour) -> Byte: `[0x00]` (1 byte)
- **DST**: `0` (Standard time) -> Byte: `[0x00]` (1 byte)

##### Test Vector 2: Historical Default Timestamp (1994-01-14T00:00:00Z, UTC-8 PST, 24h Mode, DST Active)
- **Time**: `758505600` (`0x2D3BF080`, `DEFAULT_TIME` in firmware) -> LE Bytes: `[0x80, 0xF0, 0x3B, 0x2D]` (4 bytes)
- **Timezone**: `-480` minutes (UTC-8 PST) -> Two's comp uint16: `65056` (`0xFE20`) -> LE Bytes: `[0x20, 0xFE]` (2 bytes)
  - *(Legacy firmware seconds representation `TZ_PST` = 28800 = `0x7080`)*: LE Bytes: `[0x80, 0x70]`
- **Time Mode**: `1` (24-hour) -> Byte: `[0x01]` (1 byte)
- **DST**: `1` (DST Active) -> Byte: `[0x01]` (1 byte)

##### Test Vector 3: UTC / GMT Reference (2000-01-01T00:00:00Z, UTC 0, 12h Mode, Standard Time)
- **Time**: `946684800` (`0x386D4380`) -> LE Bytes: `[0x80, 0x43, 0x6D, 0x38]` (4 bytes)
- **Timezone**: `0` minutes -> LE Bytes: `[0x00, 0x00]` (2 bytes)
- **Time Mode**: `0` (12-hour) -> Byte: `[0x00]` (1 byte)
- **DST**: `0` (Standard time) -> Byte: `[0x00]` (1 byte)

##### Test Vector 4: Positive / Non-Standard Timezone (Tokyo JST UTC+9, 24h Mode, Standard Time)
- **Time**: `1700000000` (`0x6553E200`) -> LE Bytes: `[0x00, 0xE2, 0x53, 0x65]` (4 bytes)
- **Timezone**: `+540` minutes -> uint16: `540` (`0x021C`) -> LE Bytes: `[0x1C, 0x02]` (2 bytes)
- **Time Mode**: `1` (24-hour) -> Byte: `[0x01]` (1 byte)
- **DST**: `0` (Standard time) -> Byte: `[0x00]` (1 byte)

##### Test Vector 5: Fractional Timezone (Kathmandu NPT UTC+5:45, 12h Mode, Standard Time)
- **Time**: `1725148800` (`0x66D3A900`) -> LE Bytes: `[0x00, 0xA9, 0xD3, 0x66]` (4 bytes)
- **Timezone**: `+345` minutes -> uint16: `345` (`0x0159`) -> LE Bytes: `[0x59, 0x01]` (2 bytes)
- **Time Mode**: `0` (12-hour) -> Byte: `[0x00]` (1 byte)
- **DST**: `0` (Standard time) -> Byte: `[0x00]` (1 byte)

##### Test Vector 6: Boundary Extremes (Epoch Zero & Maximum 32-bit Limits)
- **Epoch Zero (1970-01-01T00:00:00Z)**:
  - Time: `0` -> LE Bytes: `[0x00, 0x00, 0x00, 0x00]`
- **Year 2038 Rollover (2038-01-19T03:14:07Z, `0x7FFFFFFF`)**:
  - Time: `2147483647` -> LE Bytes: `[0xFF, 0xFF, 0xFF, 0x7F]`
- **Year 2106 Max uint32 (2106-02-07T06:28:15Z, `0xFFFFFFFF`)**:
  - Time: `4294967295` -> LE Bytes: `[0xFF, 0xFF, 0xFF, 0xFF]`
- **Extreme Timezone Negative (Baker Island UTC-12 = -720 min)**:
  - Two's comp: `64816` (`0xFD30`) -> LE Bytes: `[0x30, 0xFD]`
- **Extreme Timezone Positive (Kiritimati UTC+14 = +840 min)**:
  - uint16: `840` (`0x0348`) -> LE Bytes: `[0x48, 0x03]`

---

### 4.3 UI Elements, Interactions & Wireframe Specification

#### Visual Layout Hierarchy

```
+-------------------------------------------------------------+
|                     F91 Jepler Companion                   |
+-------------------------------------------------------------+
|                                                             |
|  [ CONNECTION STATUS BADGE ]                                |
|  Status: [ CONNECTED ] (Green pill / Pulse)                 |
|  Device: F91_Jepler (D4:36:39:AA:BB:CC)                     |
|                                                             |
+-------------------------------------------------------------+
|  BLUETOOTH CONTROLS                                         |
|                                                             |
|  [ Start Scan ]   [ Stop Scan ]    [ Disconnect ]           |
|                                                             |
|  Nearby Devices:                                            |
|  +-------------------------------------------------------+  |
|  | (*) F91_Jepler          RSSI: -62 dBm    [ Connect ]  |  |
|  |     ID: D4:36:39:AA:BB:CC  (Clock Svc Found)          |  |
|  +-------------------------------------------------------+  |
|                                                             |
+-------------------------------------------------------------+
|  CLOCK SYNCHRONIZATION                                      |
|                                                             |
|  Local Phone Time:  2026-10-05 03:08:48                     |
|  Unix Timestamp:    1791169728                              |
|  Timezone Offset:   UTC-05:00 (-300 min)                    |
|  Time Mode:         [ (o) 12-Hour   ( ) 24-Hour ]           |
|  Daylight Saving:   [ [x] DST Active ]                      |
|                                                             |
|  +-------------------------------------------------------+  |
|  |                 [ SYNC CLOCK NOW ]                    |  |
|  +-------------------------------------------------------+  |
|                                                             |
|  Last Synced: 2026-10-05 03:08:49 (All 4 writes verified)   |
|  Sync Progress: [====================] 100%                 |
|                                                             |
+-------------------------------------------------------------+
|  DIAGNOSTIC LOG (Collapsible)                               |
|  [03:08:48] Connected to F91_Jepler                         |
|  [03:08:49] Wrote Time (4B: C0 6A C6 6A) -> OK              |
|  [03:08:49] Wrote Timezone (2B: D4 FE)   -> OK              |
|  [03:08:49] Wrote TimeMode (1B: 00)      -> OK              |
|  [03:08:49] Wrote DST (1B: 00)           -> OK              |
+-------------------------------------------------------------+
```

#### Detailed Interaction Rules
1. **Scan Button (`btn_scan`)**:
   - Enabled only when state is `DISCONNECTED`.
   - On tap: triggers `START_SCAN`, transitions state to `SCANNING`, activates spinner, disables button, clears stale device list.
2. **Device Discovery Item (`device_row`)**:
   - Each discovered item renders Device Name (`F91_Jepler`), RSSI indicator bar (`-62 dBm`), and UUID / MAC address.
   - Tap "Connect" button on item: triggers `SELECT_DEVICE`, stops scanner, transitions to `CONNECTING`.
3. **Connect / Disconnect Button (`btn_connect_disconnect`)**:
   - When connected: displays "Disconnect" (destructive/red action).
   - On tap: calls `USER_DISCONNECT`, cleanly tears down GATT connection, resets to `DISCONNECTED`.
4. **Manual Sync Button (`btn_sync_now`)**:
   - Enabled **strictly** when state is `CONNECTED`.
   - Disabled with opacity when `DISCONNECTED`, `SCANNING`, `CONNECTING`, or `SYNCING`.
   - On tap: triggers sequential GATT write pipeline:
     - Updates progress indicator: 25% (Time) -> 50% (Timezone) -> 75% (Mode) -> 100% (DST).
     - Upon completion: displays success toast / badge with exact synchronization timestamp.
     - Upon error: displays inline warning alert ("Sync failed: [reason]") and leaves connection intact.

---

### 4.4 Automated Testing Suite Architecture (Mock BLE Abstraction)

```
+---------------------------------------------------------+
|                  Companion Application                  |
|    (UI Components, State Machine, ClockSyncService)     |
+---------------------------------------------------------+
                            |
                            | calls
                            v
+---------------------------------------------------------+
|                IBleAdapter (Interface)                  |
|  - startScan(filter): Observable<BleDevice>             |
|  - stopScan(): Promise<void>                            |
|  - connect(deviceId): Promise<void>                     |
|  - disconnect(deviceId): Promise<void>                  |
|  - writeCharacteristic(devId, svc, chr, data): Promise  |
|  - readCharacteristic(devId, svc, chr): Promise<Buffer> |
+---------------------------------------------------------+
            /                                 \
           / implements                        \ implements
          v                                     v
+-----------------------+             +-----------------------+
|    NativeBleAdapter   |             |     MockBleAdapter    |
| (Uses OS BLE drivers) |             | (In-memory simulator  |
|                       |             |  for 100% test pass)  |
+-----------------------+             +-----------------------+
                                                  |
                                                  | features:
                                                  | - Device simulation
                                                  | - RSSI updates
                                                  | - Error injection
                                                  | - Byte capture verification
```

#### Mock BLE Adapter Capabilities
- **Scriptable Discovered Devices**: Register mock devices matching `F91_Jepler` and Clock Service UUID.
- **Simulated Connection Latency**: Configurable artificial delay for connection and service discovery.
- **GATT Attribute Store**: In-memory attribute table mimicking `clock_service.c` (validating byte lengths and offsets).
- **Fault Injection Hooks**:
  - `failNextConnection(reason: BleError)`
  - `disconnectDuringSync(afterCharacteristic: string)`
  - `timeoutOnWrite(characteristic: string)`
  - `injectUnexpectedLinkLoss()`
- **Recorded I/O Inspection**: Exposes `getWrittenValues(characteristicUuid)` returning array of received byte buffers for deterministic assertions.

---

### 4.5 Four-Tier Test Case Hierarchy

```
========================================================================================
                              4-TIER TEST CASE HIERARCHY
========================================================================================

    [ Tier 1: Feature Functionality (Happy Path Core Workflows) ]
    ------------------------------------------------------------------------------------
    - T1.1: Scanner initialization and dual-criteria device filtering
    - T1.2: Connection establishment & GATT Clock Service discovery
    - T1.3: End-to-end 4-step Clock Synchronization sequence execution
    - T1.4: UI state and button reactivity across lifecycle transitions
    - T1.5: Clean user-initiated disconnection and teardown

    [ Tier 2: Boundary & Corner Cases ]
    ------------------------------------------------------------------------------------
    - T2.1: Epoch seconds boundary serialization (0, 0x7FFFFFFF, 0xFFFFFFFF)
    - T2.2: Timezone offset boundary serialization (UTC 0, -720 min, +840 min, fractional)
    - T2.3: Time Mode boundary validation (0, 1, sanitize out-of-range values)
    - T2.4: DST flag boundary validation (0, 1, sanitize out-of-range values)
    - T2.5: Zero devices found / scan timeout handling
    - T2.6: Strict byte buffer length validation (prevent BT_ATT_ERR_INVALID_OFFSET)

    [ Tier 3: Pairwise Combinations & Configuration Cross-Products ]
    ------------------------------------------------------------------------------------
    - T3.1: Timezone (Neg / Zero / Pos) × Time Mode (12h / 24h) × DST (0 / 1)
    - T3.2: Scan trigger state (Cold start / Post-disconnect) × Device RSSI levels
    - T3.3: Connection retry sequence (Failed attempt 1 -> Retry attempt 2 -> Success)
    - T3.4: Timezone minute format vs legacy seconds format compatibility

    [ Tier 4: Real-World Workloads & Fault Tolerance ]
    ------------------------------------------------------------------------------------
    - T4.1: Unexpected link loss mid-GATT sync (watch out-of-range / battery pull)
    - T4.2: GATT write timeout / non-responsive peripheral during sync
    - T4.3: Connection attempt to non-watch peripheral (missing Clock Service)
    - T4.4: Rapid UI interaction stress (spamming Scan and Sync buttons)
    - T4.5: Immediate re-scan and reconnect after unhandled link drop
    - T4.6: Bluetooth radio disabled by OS mid-operation
========================================================================================
```

#### Detailed Test Case Specifications

| ID | Test Case Title | Tier | Description & Setup | Input / Trigger | Expected Output & Verification |
|---|---|---|---|---|---|
| **TC-1.1** | BLE Peripheral Scanning & Dual Filter | Tier 1 | `MockBleAdapter` initialized with 3 devices: "F91_Jepler" (matching name & UUID), "Other_Watch" (unrelated), and "Watch_Unnamed" (matching UUID only). | Tap "Start Scan" | Exactly 2 matching devices appear in scan list; unrelated peripheral is excluded. Scanner state is `SCANNING`. |
| **TC-1.2** | BLE Connection & Service Discovery | Tier 1 | Scanner active with discovered `F91_Jepler`. | Select `F91_Jepler` and tap "Connect" | Scanner stops; state transitions `SCANNING -> CONNECTING -> CONNECTED`; all 4 characteristic handles resolved; UI shows "Connected". |
| **TC-1.3** | Sequential Clock Synchronization | Tier 1 | State is `CONNECTED`; system time set to fixed test vector (2026-10-05T03:08:48Z, UTC-5). | Tap "Sync Clock Now" | State transitions to `SYNCING`; writes executed in order: Time -> TZ -> Mode -> DST; exactly 4 writes recorded; UI updates last sync timestamp and returns to `CONNECTED`. |
| **TC-1.4** | User Disconnect Teardown | Tier 1 | State is `CONNECTED`. | Tap "Disconnect" | BLE disconnect API called; characteristic cache flushed; state transitions to `DISCONNECTED`; "Sync" button disabled. |
| **TC-2.1** | Timestamp Serialization Boundaries | Tier 2 | Serializer tested in isolation against boundary timestamps. | Timestamps: `0`, `2147483647`, `4294967295`. | Byte outputs match exact LE hex: `[00 00 00 00]`, `[FF FF FF 7F]`, `[FF FF FF FF]`; buffers are exactly 4 bytes. |
| **TC-2.2** | Timezone Offset Boundaries | Tier 2 | Serializer tested against global timezone extremes. | Offsets: 0 min (UTC), -480 min (PST), +540 min (JST), +345 min (NPT), -720 min, +840 min. | Byte outputs match exact LE hex; 2 bytes length; handles signed negative values via two's complement uint16. |
| **TC-2.3** | Time Mode Clamping & Sanitization | Tier 2 | Serializer receives edge inputs for time format. | Inputs: `0`, `1`, `2`, `-1`, `255`. | Inputs `0` and `1` serialize to `[0x00]` and `[0x01]`; invalid values are safely clamped to `0` or `1` without throwing exception. |
| **TC-2.4** | DST Flag Clamping & Sanitization | Tier 2 | Serializer receives edge inputs for DST flag. | Inputs: `false`/`0`, `true`/`1`, `null`, `undefined`, `99`. | Serializes cleanly to single byte `[0x00]` or `[0x01]`. |
| **TC-2.5** | Scan Timeout with Zero Devices | Tier 2 | `MockBleAdapter` configured to discover no devices. | Tap "Start Scan" | Scanner times out after 15s; state cleanly transitions `SCANNING -> DISCONNECTED`; empty state message displayed without errors. |
| **TC-2.6** | Payload Buffer Strict Length Checks | Tier 2 | Verifies serializer output against firmware size guards. | Serialize complete sync payload. | `time.length === 4`, `tz.length === 2`, `mode.length === 1`, `dst.length === 1`. Prevents `BT_ATT_ERR_INVALID_OFFSET`. |
| **TC-3.1** | Pairwise Matrix: TZ × Mode × DST | Tier 3 | Systematic matrix of 12 parameter combinations (3 timezones × 2 modes × 2 DST states). | Trigger sync across all 12 tuples. | All 12 payloads serialize correctly, send without error, and are accepted by mock GATT attributes. |
| **TC-3.2** | Pairwise Matrix: Scan State × Signal Strength | Tier 3 | Combinations of Cold Scan vs Re-scan after disconnect × Strong (-45 dBm), Medium (-75 dBm), Weak (-95 dBm) RSSI. | Initiate scan under each configuration. | RSSI indicators render appropriate visual bars; device deduplication prevents duplicate rows. |
| **TC-3.3** | Connection Retry Sequence | Tier 3 | Mock configured to fail attempt 1 with `CONNECTION_TIMEOUT`, then succeed attempt 2. | User attempts connection, fails, taps retry. | Attempt 1 transitions `CONNECTING -> ERROR`; alert shown; Attempt 2 succeeds and transitions to `CONNECTED`. No memory leaks. |
| **TC-3.4** | Dual Format Timezone Verification | Tier 3 | Test vectors for both minutes-based offset (`fa35b2f2`) and legacy seconds-based constants (`f91_clock.h`). | Verify serialization of both PST modes (-480 min vs 28800 sec). | Both format encoders generate valid 2-byte LE buffers (`[20 FE]` and `[80 70]`). |
| **TC-4.1** | Fault Tolerance: Mid-Sync Link Loss | Tier 4 | `MockBleAdapter` drops connection immediately after Time characteristic write succeeds. | Tap "Sync Clock Now" | Step 1 completes; Step 2 throws link lost; state machine immediately catches error, aborts remaining writes, updates state to `DISCONNECTED`; UI shows "Disconnected during sync" alert without crashing. |
| **TC-4.2** | Fault Tolerance: GATT Write Timeout | Tier 4 | `MockBleAdapter` hangs on Timezone write response (>5s). | Tap "Sync Clock Now" | Write timeout triggers after 5s; sync aborted; state remains `CONNECTED`; UI displays "Sync failed: Request timed out"; sync button re-enabled. |
| **TC-4.3** | Fault Tolerance: Missing Clock Service | Tier 4 | Peripheral connects successfully but advertises only Battery Service (no `fa35b2f0...`). | Connect to rogue device. | Service discovery discovers missing UUID; initiates graceful disconnect; transitions to `ERROR`; informs user device is incompatible. |
| **TC-4.4** | Stress: Rapid UI Button Spamming | Tier 4 | User rapidly taps "Scan" 10 times in 200ms, or "Sync" 10 times during active sync. | Rapid concurrent event emissions. | Debounce / state guards ignore redundant clicks; only one scan/sync pipeline executes; zero race conditions. |
| **TC-4.5** | Stress: Back-to-Back Sequential Syncs | Tier 4 | User executes 10 successive syncs in rapid succession upon each completion. | 10 consecutive sync completions. | All 10 complete successfully; 40 total characteristic writes recorded; no unhandled promise rejections or leaked listeners. |
| **TC-4.6** | System Event: Bluetooth Radio Power Off | Tier 4 | OS Bluetooth adapter turned off while in `CONNECTED` state. | Mock fires adapter state `POWERED_OFF`. | Connection manager catches event; transitions to `DISCONNECTED`; clears active peripheral; prompts user to enable Bluetooth. |

---

## 5. Verification Method

To independently verify the completeness, accuracy, and rigor of this requirements and testing specification:

1. **Firmware Consistency Check**:
   - Inspect `/Users/jacobloesch/Documents/F91_Jepler/Firmware/zephyr/src/services/clock_service.c` (lines 28, 56, 84, 111):
     Confirm that `offset != 0` or invalid buffer length causes `BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET)`.
   - Inspect `/Users/jacobloesch/Documents/F91_Jepler/Firmware/zephyr/src/services/clock_service.h` (lines 8-23):
     Confirm matching 128-bit UUIDs for Service (`0xfa35b2f0...`) and Characteristics (`0xfa35b2f1...` through `0xfa35b2f4...`).
   - Inspect `/Users/jacobloesch/Documents/F91_Jepler/Firmware/zephyr/prj.conf` (line 11):
     Confirm `CONFIG_BT_DEVICE_NAME="F91_Jepler"`.

2. **Serialization Math Verification**:
   - Time test vector: `1791169728` in hex is `0x6AC66AC0`. Little-endian bytes: `0xC0, 0x6A, 0xC6, 0x6A`.
   - Timezone test vector (EST -300 min): `65536 - 300 = 65236` = `0xFED4`. Little-endian bytes: `0xD4, 0xFE`.
   - Timezone test vector (PST -480 min): `65536 - 480 = 65056` = `0xFE20`. Little-endian bytes: `0x20, 0xFE`.
   - Historical Default Time: `758505600` in hex is `0x2D3BF080`. Little-endian bytes: `0x80, 0xF0, 0x3B, 0x2D`.

3. **Downstream Test Execution (Once Implemented)**:
   - When the companion application test suite is implemented in `Software/companion_app`:
     - Command: `npm test` (or `yarn test` / `vitest run`).
     - Expected result: 100% tests passing across all 4 tiers (Tiers 1 through 4), with zero dependence on physical Bluetooth hardware.
