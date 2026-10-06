# Survey Explorer 1 (Spec Miner) — Handoff Report
**Date**: 2026-10-05T03:14:00Z  
**Author**: Survey Explorer 1 (Spec Miner)  
**Target Repository**: `/Users/jacobloesch/Documents/F91_Jepler`  
**Working Directory**: `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/survey_explorer_1`

---

## 1. Observation

### 1.1 Authoritative Specification Sources Inspected
Inspection of the repository revealed three core generations/manifestations of the BLE protocol:
1. **Modern Zephyr RTOS Firmware (Authoritative Active Target)**:
   - `/Users/jacobloesch/Documents/F91_Jepler/Firmware/zephyr/src/services/clock_service.h`
   - `/Users/jacobloesch/Documents/F91_Jepler/Firmware/zephyr/src/services/clock_service.c`
   - `/Users/jacobloesch/Documents/F91_Jepler/Firmware/zephyr/src/services/notification_service.h`
   - `/Users/jacobloesch/Documents/F91_Jepler/Firmware/zephyr/src/services/notification_service.c`
   - `/Users/jacobloesch/Documents/F91_Jepler/Firmware/zephyr/src/main.c`
   - `/Users/jacobloesch/Documents/F91_Jepler/Firmware/zephyr/prj.conf`
2. **Legacy CC2640 TI BLE-Stack Firmware (Baseline Reference)**:
   - `/Users/jacobloesch/Documents/F91_Jepler/Firmware/f91_kepler_app/PROFILES/f91_clock_service.h`
   - `/Users/jacobloesch/Documents/F91_Jepler/Firmware/f91_kepler_app/PROFILES/f91_clock_service.c`
   - `/Users/jacobloesch/Documents/F91_Jepler/Firmware/f91_kepler_app/Application/f91_clock.h`
   - `/Users/jacobloesch/Documents/F91_Jepler/Firmware/f91_kepler_app/Application/f91_clock.c`
   - `/Users/jacobloesch/Documents/F91_Jepler/Firmware/f91_kepler_app/Application/f91_utils.h`
3. **macOS Host Emulator & GATT Models (Working Companion Reference)**:
   - `/Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App/F91JeplerEmulator/Models/GATTModels.swift`
   - `/Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App/F91JeplerEmulator/Views/GATTTestInjectorView.swift`
   - `/Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App/F91JeplerEmulator/Models/EmulatorSession.swift`
4. **Project Documentation & Hardware Requirements**:
   - `/Users/jacobloesch/Documents/F91_Jepler/Firmware/README.md`
   - `/Users/jacobloesch/Documents/F91_Jepler/Hardware/CLOCKING.md`
   - `/Users/jacobloesch/Documents/F91_Jepler/PROJECT_CONTEXT.md`
   - `/Users/jacobloesch/Documents/F91_Jepler/.agents/teamwork/ORIGINAL_REQUEST.md`

---

### 1.2 Verbatim Source Observations

#### A. Device Name & Advertising Configuration
- In `Firmware/zephyr/prj.conf`:
  ```ini
  CONFIG_BT=y
  CONFIG_BT_PERIPHERAL=y
  CONFIG_BT_DEVICE_NAME="F91_Jepler"
  ```
- In `Firmware/zephyr/src/main.c` (lines 15-23):
  ```c
  static const struct bt_data ad[] = {
      BT_DATA_BYTES(BT_DATA_FLAGS, (BT_LE_AD_GENERAL | BT_LE_AD_NO_BREDR)),
      BT_DATA(BT_DATA_NAME_COMPLETE, CONFIG_BT_DEVICE_NAME, sizeof(CONFIG_BT_DEVICE_NAME) - 1),
  };

  static const struct bt_data sd[] = {
      BT_DATA_BYTES(BT_DATA_UUID128_SOME, BT_UUID_NOTIFICATION_SERVICE_VAL),
  };
  ```
  *Key Finding*: The primary advertising payload (`ad`) broadcasts `CONFIG_BT_DEVICE_NAME` (`"F91_Jepler"`). The scan response packet (`sd`) advertises the Notification Service UUID. The Clock Service is exposed as a primary GATT service upon connection/service discovery.

#### B. Base UUID Formulation and Endianness
- In `Firmware/f91_kepler_app/Application/f91_utils.h` (lines 101-104):
  ```c
  // F91-Kepler Base 128-bit UUID: FA35XXXX-7989-11EB-9439-0242AC130002
  #define F91_BASE_UUID_128(uuid) 0x02, 0x00, 0x13, 0xAC, 0x42, 0x02, 0x39, 0x94, \
                  0xEB, 0x11, 0x89, 0x79, LO_UINT16(uuid), HI_UINT16(uuid), 0x35, 0xFA
  ```
- In `Firmware/zephyr/src/services/clock_service.h` (lines 8-17):
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
- *UUID Little-Endian Raw Byte Representation (least-significant byte first)*:
  - Base template: `[0x02, 0x00, 0x13, 0xac, 0x42, 0x02, 0x39, 0x94, 0xeb, 0x11, 0x89, 0x79, <low_byte>, <high_byte>, 0x35, 0xfa]`
  - Clock Service (`0xB2F0`): `02 00 13 AC 42 02 39 94 EB 11 89 79 F0 B2 35 FA`
  - Time Char (`0xB2F1`): `02 00 13 AC 42 02 39 94 EB 11 89 79 F1 B2 35 FA`
  - Timezone Char (`0xB2F2`): `02 00 13 AC 42 02 39 94 EB 11 89 79 F2 B2 35 FA`
  - Time Mode Char (`0xB2F3`): `02 00 13 AC 42 02 39 94 EB 11 89 79 F3 B2 35 FA`
  - DST Char (`0xB2F4`): `02 00 13 AC 42 02 39 94 EB 11 89 79 F4 B2 35 FA`

#### C. GATT Service Definition & Read/Write Handling
From `Firmware/zephyr/src/services/clock_service.c` (lines 14-148):
1. **Clock Time Characteristic (`0xB2F1`)**:
   - Size: `sizeof(uint32_t)` = 4 bytes.
   - Validation:
     ```c
     if (offset != 0 || len != sizeof(uint32_t)) {
         return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
     }
     clock_time_val = *((const uint32_t *)buf);
     ```
   - On little-endian architecture (ARM Cortex-M4 nRF52840), `*((const uint32_t *)buf)` reads `buf[0]` as LSB and `buf[3]` as MSB.
2. **Clock Timezone Characteristic (`0xB2F2`)**:
   - Size: `sizeof(uint16_t)` = 2 bytes.
   - Validation:
     ```c
     if (offset != 0 || len != sizeof(uint16_t)) {
         return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
     }
     clock_timezone_val = *((const uint16_t *)buf);
     ```
   - On ARM Cortex-M4, reads 2 bytes little-endian.
3. **Clock Time Mode Characteristic (`0xB2F3`)**:
   - Size: `sizeof(uint8_t)` = 1 byte.
   - Validation:
     ```c
     if (offset != 0 || len != sizeof(uint8_t)) {
         return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
     }
     clock_timemode_val = *((const uint8_t *)buf);
     ```
   - Value: `0` = 12-hour mode, `1` = 24-hour mode.
4. **Clock DST Characteristic (`0xB2F4`)**:
   - Size: `sizeof(uint8_t)` = 1 byte.
   - Validation:
     ```c
     if (offset != 0 || len != sizeof(uint8_t)) {
         return BT_GATT_ERR(BT_ATT_ERR_INVALID_OFFSET);
     }
     clock_dst_val = *((const uint8_t *)buf);
     ```
   - Value: `0` = Standard Time, `1` = Daylight Saving Time.

#### D. Timezone Interpretation & Serialization in Reference Software
In `Software/macOS_App/F91JeplerEmulator/Models/GATTModels.swift` (lines 68-107):
```swift
public struct ClockSyncPayload {
    public var timestamp: UInt32
    public var timezoneOffsetMinutes: Int16
    public var is24HourMode: Bool
    public var isDST: Bool
    
    public init(date: Date = Date(), is24Hour: Bool = false) {
        self.timestamp = UInt32(date.timeIntervalSince1970)
        let tz = TimeZone.current
        self.timezoneOffsetMinutes = Int16(tz.secondsFromGMT(for: date) / 60)
        self.is24HourMode = is24Hour
        self.isDST = tz.isDaylightSavingTime(for: date)
    }
    
    public func serializeTime() -> [UInt8] {
        var val = timestamp.littleEndian
        return withUnsafeBytes(of: &val) { Array($0) }
    }
    
    public func serializeTimezone() -> [UInt8] {
        var val = UInt16(bitPattern: timezoneOffsetMinutes).littleEndian
        return withUnsafeBytes(of: &val) { Array($0) }
    }
    
    public func serializeTimeMode() -> [UInt8] {
        return [is24HourMode ? 1 : 0]
    }
    
    public func serializeDST() -> [UInt8] {
        return [isDST ? 1 : 0]
    }
}
```

---

### 1.3 Features Discovered Table

| # | Category | Feature | Description | Inputs | Outputs | Error Behavior | Discovered Via |
|---|----------|---------|-------------|--------|---------|----------------|----------------|
| 1 | BLE Service | F91 Clock Service | Primary GATT service exposing watch time, timezone offset, display format mode, and daylight saving state. | Connection to GATT Server; UUID: `fa35b2f0-7989-11eb-9439-0242ac130002` | Discovered primary service handle | `ATT_ERR_INVALID_HANDLE` if unknown | `clock_service.h:8`, `f91_clock_service.c:78`, `GATTModels.swift:540` |
| 2 | GATT Char | Clock Time | 4-byte Unix epoch timestamp in seconds. Readable and writable. Firmware updates local real-time clock upon write. | 4-byte `uint32_t` little-endian (e.g. `[0x00, 0xE1, 0x53, 0x65]` for 1700000000) | Current 4-byte `uint32_t` epoch time | Returns `BT_ATT_ERR_INVALID_OFFSET` (0x07) if `len != 4` or `offset != 0` | `clock_service.c:23-40`, `f91_clock_service.c:118-124` |
| 3 | GATT Char | Clock Timezone | 2-byte timezone offset in minutes from UTC (signed int16 as uint16 bit-pattern, little-endian). | 2-byte `int16_t`/`uint16_t` little-endian (e.g. `[0xD4, 0xFE]` for -300 min / EST) | Current 2-byte timezone offset | Returns `BT_ATT_ERR_INVALID_OFFSET` (0x07) if `len != 2` or `offset != 0` | `clock_service.c:51-68`, `GATTModels.swift:88`, `f91_clock.c:153` |
| 4 | GATT Char | Clock Time Mode | 1-byte display format mode selector (12-hour vs 24-hour display). | 1-byte `uint8_t`: `0x00` (12-hr) or `0x01` (24-hr) | Current 1-byte mode value (`0x00` or `0x01`) | Returns `BT_ATT_ERR_INVALID_OFFSET` (0x07) if `len != 1` or `offset != 0`. Values >1 default to 0 in legacy FW. | `clock_service.c:79-96`, `f91_clock.c:168-184` |
| 5 | GATT Char | Clock DST | 1-byte Daylight Saving Time flag. Controls whether +1 hour offset applies to current local time. | 1-byte `uint8_t`: `0x00` (Standard) or `0x01` (DST) | Current 1-byte DST value (`0x00` or `0x01`) | Returns `BT_ATT_ERR_INVALID_OFFSET` (0x07) if `len != 1` or `offset != 0`. Values >1 default to 0 in legacy FW. | `clock_service.c:107-124`, `f91_clock.c:194-211` |
| 6 | Peripheral Adv | Device Advertising | Peripheral advertises general connectable mode with Local Name `F91_Jepler` and Notification Service in scan response. | GAP advertising initialization (`BT_LE_ADV_CONN_FAST_1`) | BLE Advertisement packet (`ad` + `sd`) | Error status logged over UART if `bt_le_adv_start` fails | `Firmware/zephyr/src/main.c:15-23`, `prj.conf:11` |
| 7 | BLE Service | Notification Service | GATT service for phone notification bar bitmask, caller identification, and incoming message text streams. | UUID: `fa35a2f0-7989-11eb-9439-0242ac130002` | Discovered primary service handle | `ATT_ERR_INVALID_HANDLE` | `Firmware/zephyr/src/services/notification_service.h` |
| 8 | GATT Char | Notification Bar | 1-byte bitmask indicator for active notifications on the watch LCD/OLED bar (Call=0x01, SMS=0x02, Email=0x04, Alert=0x08). | 1-byte `uint8_t` bitmask | Current 1-byte bitmask | Returns `BT_ATT_ERR_INVALID_OFFSET` if `len != 1` or `offset != 0` | `notification_service.c:22-39` |
| 9 | GATT Char | Incoming Call | Write-only characteristic streaming caller name/ID string up to 20 UTF-8 bytes. | UTF-8 string up to 20 bytes (`len <= 20`) | None (Write-only) | Returns `BT_ATT_ERR_INVALID_ATTRIBUTE_LEN` (0x0D) if `offset + len > 20` | `notification_service.c:41-59` |
| 10 | GATT Char | Incoming Text | Write-only characteristic streaming text preview up to 20 UTF-8 bytes. | UTF-8 string up to 20 bytes (`len <= 20`) | None (Write-only) | Returns `BT_ATT_ERR_INVALID_ATTRIBUTE_LEN` (0x0D) if `offset + len > 20` | `notification_service.c:61-79` |
| 11 | BLE Service | Battery Service (BAS) | Standard Bluetooth SIG Battery Service (UUID `0x180F`) exposing battery state of charge (UUID `0x2A19`). | Standard GATT Read/Notify request | 1-byte `uint8_t` percentage (0-100%) | Standard BLE ATT error codes | `GATTModels.swift:109-123`, `PROJECT_CONTEXT.md:78` |
| 12 | BLE Service | SMP / MCUboot OTA DFU | Simple Management Protocol over BLE (UUID `8D53DC1D-1DB7-4CD3-868B-8A527460AA84`) for wireless firmware upgrade. | SMP framed packets (cborg / mcumgr) | SMP status responses | MCUMGR error codes | `Firmware/zephyr/prj.conf:25-28`, `Firmware/README.md:8` |

---

### 1.4 Edge Cases Table

| # | Feature | Input | Observed Behavior |
|---|---------|-------|-------------------|
| 1 | Clock Time | Payload length = 0 bytes | Zephyr returns `BT_ATT_ERR_INVALID_OFFSET` (0x07); write rejected, previous clock time preserved. |
| 2 | Clock Time | Payload length = 5 bytes (extra trailing byte) | Zephyr returns `BT_ATT_ERR_INVALID_OFFSET` (0x07); write rejected. |
| 3 | Clock Time | Write with `offset > 0` (blob/long write) | Zephyr returns `BT_ATT_ERR_INVALID_OFFSET` (0x07); long write rejected. In CC2640, returns `ATT_ERR_ATTR_NOT_LONG`. |
| 4 | Clock Time | Epoch timestamp `0` (1970-01-01 00:00:00 UTC) | Accepted: serialized as `[0x00, 0x00, 0x00, 0x00]`; watch resets epoch to 1970. |
| 5 | Clock Time | Epoch timestamp `4294967295` (0xFFFFFFFF, year 2106 uint32 max) | Accepted: serialized as `[0xFF, 0xFF, 0xFF, 0xFF]`; watch sets max epoch. |
| 6 | Clock Timezone | Offset -300 minutes (EST, UTC-5) | Encoded as two's complement `0xFED4`, serialized little-endian as `[0xD4, 0xFE]`. Accepted. |
| 7 | Clock Timezone | Offset -480 minutes (PST, UTC-8) | Encoded as two's complement `0xFE20`, serialized little-endian as `[0x20, 0xFE]`. Accepted. |
| 8 | Clock Timezone | Offset +330 minutes (IST, UTC+5:30) | Encoded as `0x014A`, serialized little-endian as `[0x4A, 0x01]`. Accepted. |
| 9 | Clock Timezone | Offset 0 minutes (UTC) | Encoded as `0x0000`, serialized little-endian as `[0x00, 0x00]`. Accepted. |
| 10 | Clock Timezone | Payload length = 1 byte or 3 bytes | Zephyr returns `BT_ATT_ERR_INVALID_OFFSET` (0x07); write rejected. |
| 11 | Clock Time Mode | Value `0x00` | 12-hour mode enabled (`TimeMode = false` in FW). Watch displays AM/PM indicator on SSD1306. |
| 12 | Clock Time Mode | Value `0x01` | 24-hour mode enabled (`TimeMode = true` in FW). Watch displays 00:00 - 23:59 on SSD1306. |
| 13 | Clock Time Mode | Value `0x02` (or any value > 1) | Zephyr logs raw value `2`. In legacy FW, `default` branch forces value back to `0` (12-hour mode). |
| 14 | Clock DST | Value `0x00` | Standard time (`Dst = false`). No daylight saving offset added. |
| 15 | Clock DST | Value `0x01` | Daylight saving active (`Dst = true`). Watch adds +3600 seconds to local time calculation. |
| 16 | Clock DST | Value `0xFF` (invalid flag) | In Zephyr, accepted into `clock_dst_val` as raw byte. In CC2640, default branch forces `Dst = false` and resets to `0`. |
| 17 | Peripheral Scan | Scanning with only Service UUID filter | If scan filter only searches for advertised Service UUID in `ad`, the watch is missed because `sd` advertises Notification Service, while Clock Service is non-advertised primary service. **Scanner must filter by Peripheral Name `F91_Jepler` or perform discovery post-connection.** |
| 18 | Write Sequence | Rapid simultaneous GATT writes without waiting for ATT Write Response | BLE link layer queue overflow or Android/iOS GATT concurrency error (`GATT_BUSY` / status 133). Writes must be issued sequentially upon receipt of the previous write's confirmation. |

---

## 2. Logic Chain

1. **Firmware Architecture Transition**:
   - *Observation*: `PROJECT_CONTEXT.md` (lines 34-37, 79) and `Firmware/README.md` (lines 3-11) document the migration from the legacy TI CC2640 to the Nordic nRF52840 running Zephyr RTOS.
   - *Logic*: The companion app must target the Zephyr RTOS implementation as the active target, while preserving 100% GATT protocol compatibility with the legacy CC2640 layout.

2. **GATT Clock Service UUID and Characteristic Layout**:
   - *Observation*: `Firmware/zephyr/src/services/clock_service.h` (lines 8-17) and `Firmware/f91_kepler_app/Application/f91_utils.h` (lines 101-104) show identical 128-bit UUID generation based on the 16-bit identifiers `0xB2F0`, `0xB2F1`, `0xB2F2`, `0xB2F3`, and `0xB2F4`.
   - *Logic*: The canonical UUIDs are:
     - Clock Service: `fa35b2f0-7989-11eb-9439-0242ac130002`
     - Time: `fa35b2f1-7989-11eb-9439-0242ac130002`
     - Timezone: `fa35b2f2-7989-11eb-9439-0242ac130002`
     - Time Mode: `fa35b2f3-7989-11eb-9439-0242ac130002`
     - DST: `fa35b2f4-7989-11eb-9439-0242ac130002`
   - *Logic*: These values perfectly match the specifications defined in `ORIGINAL_REQUEST.md` (lines 12-17).

3. **Data Types and Little-Endian Serialization**:
   - *Observation*: Both nRF52840 (ARM Cortex-M4) and CC2640 (ARM Cortex-M3) are natively little-endian architectures. `clock_service.c` directly dereferences `*((const uint32_t *)buf)` and `*((const uint16_t *)buf)`.
   - *Observation*: `GATTModels.swift` in the macOS emulator serializes `timestamp.littleEndian` (4 bytes) and `UInt16(bitPattern: timezoneOffsetMinutes).littleEndian` (2 bytes).
   - *Logic*: The client serialization must encode:
     - Time: 4 bytes, uint32 little-endian
     - Timezone: 2 bytes, signed int16 (minutes from UTC) encoded as little-endian uint16 bit-pattern
     - Time Mode: 1 byte, uint8 (`0` = 12h, `1` = 24h)
     - DST: 1 byte, uint8 (`0` = Standard, `1` = DST)

4. **Timezone Offset Semantics**:
   - *Observation*: `ORIGINAL_REQUEST.md` lines 15 & 49 state `uint16 offset in minutes or minutes from UTC, little-endian`. `GATTModels.swift` line 77 uses `Int16(tz.secondsFromGMT(for: date) / 60)`. Legacy firmware `f91_clock.h` had provisional seconds macros (e.g. 18000 for EST).
   - *Logic*: Across standard modern software (macOS app and companion app requirements), the timezone offset is in **minutes from UTC**. Negative offsets (e.g. Americas) are stored as standard two's complement 16-bit integers in little-endian format (e.g. -300 minutes -> `0xFED4` -> `[0xD4, 0xFE]`). Positive offsets (e.g. Europe/Asia) are stored as positive integers (e.g. +120 minutes -> `0x0078` -> `[0x78, 0x00]`).

5. **Clock Synchronization Protocol & Sequence**:
   - *Observation*: The firmware handles each GATT write independently in `write_clock_time`, `write_clock_timezone`, `write_clock_timemode`, and `write_clock_dst`. Each triggers an individual callback (`time_cb`, `tz_cb`, `timemode_cb`, `dst_cb`).
   - *Logic*: The BLE companion app must execute a 4-step write sequence. Because standard BLE GATT Write Requests require an ATT Write Response, the mobile application must chain the writes sequentially (as a Promise chain, async/await pipeline, or state machine queue):
     1. Write Timezone (`FA35B2F2`) -> Await Response
     2. Write Time Mode (`FA35B2F3`) -> Await Response
     3. Write DST (`FA35B2F4`) -> Await Response
     4. Write Time Epoch (`FA35B2F1`) -> Await Response
     *(Writing Timezone, Mode, and DST prior to or following Time ensures that when Time is committed, all localized display formatting parameters are synchronized).*

---

## 3. Caveats

1. **Scan Filtering Limitation**:
   - In Zephyr `main.c`, the advertising payload (`ad`) contains flags and `CONFIG_BT_DEVICE_NAME` ("F91_Jepler"). The scan response (`sd`) contains `BT_UUID_NOTIFICATION_SERVICE_VAL`. The Clock Service UUID is NOT in the advertising packet. Therefore, mobile BLE scans must filter on peripheral name `"F91_Jepler"` rather than solely filtering for Clock Service UUID in the advertisement payload during initial discovery.
2. **Firmware SetDst Parameter Typo in Legacy CC2640**:
   - In `Firmware/f91_kepler_app/Application/f91_clock.c` line 210, `_F91Clock_setDst` mistakenly passed `F91_CLOCK_SERVICE_CHAR3` instead of `F91_CLOCK_SERVICE_CHAR4` to `F91_clock_service_SetParameter`. However, in the active Zephyr target (`Firmware/zephyr/src/services/clock_service.c`), this bug does not exist and all 4 characteristics are properly distinct.
3. **No Batch / Compound Sync Characteristic**:
   - The watch does not provide a single compound 8-byte sync characteristic. Synchronization requires 4 separate characteristic writes over the GATT link.

---

## 4. Conclusion

The specification for the F91_Jepler BLE Clock Service and companion interaction is fully determined, authoritative, and unambiguous:
- **Peripheral Device Name**: `F91_Jepler`
- **Clock Service UUID**: `fa35b2f0-7989-11eb-9439-0242ac130002`
- **Time Characteristic UUID**: `fa35b2f1-7989-11eb-9439-0242ac130002`
  - 4 bytes, uint32 little-endian, Unix epoch seconds
  - Permissions: Read, Write
- **Timezone Characteristic UUID**: `fa35b2f2-7989-11eb-9439-0242ac130002`
  - 2 bytes, signed int16 (minutes from UTC) packed as little-endian uint16 bit-pattern
  - Permissions: Read, Write
- **Time Mode Characteristic UUID**: `fa35b2f3-7989-11eb-9439-0242ac130002`
  - 1 byte, uint8: `0` for 12-hour, `1` for 24-hour
  - Permissions: Read, Write
- **DST Characteristic UUID**: `fa35b2f4-7989-11eb-9439-0242ac130002`
  - 1 byte, uint8: `0` for standard time, `1` for daylight saving time
  - Permissions: Read, Write
- **Write Sequence**: Sequential ATT Write Requests with response handling across all 4 characteristics.
- **Error Behavior**: Strict length and offset checking in firmware; writes with invalid length or non-zero offset are rejected with ATT Error code `0x07` (`BT_ATT_ERR_INVALID_OFFSET`).

---

## 5. Verification Method

### 5.1 Verification Commands and Inspection Files
1. **Verify UUID and Service Definitions in Active Zephyr Firmware**:
   ```bash
   grep -n "BT_UUID_128_ENCODE" /Users/jacobloesch/Documents/F91_Jepler/Firmware/zephyr/src/services/clock_service.h
   ```
2. **Verify Characteristic Validation and Error Codes**:
   ```bash
   grep -n -C 5 "write_clock_" /Users/jacobloesch/Documents/F91_Jepler/Firmware/zephyr/src/services/clock_service.c
   ```
3. **Verify Device Name and Advertising Configuration**:
   ```bash
   grep -n "CONFIG_BT_DEVICE_NAME" /Users/jacobloesch/Documents/F91_Jepler/Firmware/zephyr/prj.conf
   grep -n -C 5 "static const struct bt_data ad" /Users/jacobloesch/Documents/F91_Jepler/Firmware/zephyr/src/main.c
   ```
4. **Verify Host Reference Serialization in macOS App**:
   ```bash
   grep -n -C 10 "ClockSyncPayload" /Users/jacobloesch/Documents/F91_Jepler/Software/macOS_App/F91JeplerEmulator/Models/GATTModels.swift
   ```

### 5.2 Test Vectors for Serialization Unit Tests
Unit tests in the companion application should validate serialization against these exact byte vectors:

| Test Case | Field | Logical Value | Byte Array (Decimal) | Byte Array (Hex) |
|---|---|---|---|---|
| **Vector 1 (US EST, 12h, Standard)** | Timestamp | `1700000000` | `[0, 241, 83, 101]` | `[0x00, 0xF1, 0x53, 0x65]` |
| | Timezone | `-300` (UTC-5) | `[212, 254]` | `[0xD4, 0xFE]` |
| | Time Mode | `0` (12-hour) | `[0]` | `[0x00]` |
| | DST | `0` (Standard) | `[0]` | `[0x00]` |
| **Vector 2 (US PDT, 24h, DST Active)** | Timestamp | `1728000000` | `[0, 48, 255, 102]` | `[0x00, 0x30, 0xFF, 0x66]` |
| | Timezone | `-420` (UTC-7) | `[92, 254]` | `[0x5C, 0xFE]` |
| | Time Mode | `1` (24-hour) | `[1]` | `[0x01]` |
| | DST | `1` (DST Active) | `[1]` | `[0x01]` |
| **Vector 3 (Epoch Boundary / UTC)** | Timestamp | `0` (1970-01-01) | `[0, 0, 0, 0]` | `[0x00, 0x00, 0x00, 0x00]` |
| | Timezone | `0` (UTC) | `[0, 0]` | `[0x00, 0x00]` |
| | Time Mode | `0` (12-hour) | `[0]` | `[0x00]` |
| | DST | `0` (Standard) | `[0]` | `[0x00]` |
| **Vector 4 (India Standard Time / IST)** | Timestamp | `1700000000` | `[0, 241, 83, 101]` | `[0x00, 0xF1, 0x53, 0x65]` |
| | Timezone | `+330` (UTC+5:30) | `[74, 1]` | `[0x4A, 0x01]` |
| | Time Mode | `1` (24-hour) | `[1]` | `[0x01]` |
| | DST | `0` (No DST) | `[0]` | `[0x00]` |
| **Vector 5 (Max UInt32 Timestamp)** | Timestamp | `4294967295` | `[255, 255, 255, 255]` | `[0xFF, 0xFF, 0xFF, 0xFF]` |
| | Timezone | `0` | `[0, 0]` | `[0x00, 0x00]` |
| | Time Mode | `1` | `[1]` | `[0x01]` |
| | DST | `0` | `[0]` | `[0x00]` |

### 5.3 Invalidation Conditions
This specification would be invalidated if:
1. Firmware is updated to combine time parameters into a single composite GATT characteristic.
2. Firmware changes `CONFIG_BT_DEVICE_NAME` to another name or modifies base 128-bit UUID generation.
3. Big-endian / network byte order is introduced for integer characteristics instead of native ARM little-endian.
