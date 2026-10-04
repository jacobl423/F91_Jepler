# F91 Jepler — KiCad A0 draft

Open `f91_jepler.kicad_pro` in KiCad 10. The schematic and PCB are editable.
This is an **unrouted electrical-core and placement draft, not a complete watch
board or a fabrication release**. The original DipTrace files are unchanged.

## Captured circuitry

- nRF52840-QIAA, Nordic AQFN73, based on Nordic reference configuration 6:
  normal VDD supply, internal LDO, no USB. VDDH joins VDD; VBUS joins ground.
  Firmware must disable the MCU DC/DC converters for this circuit.
- 32 MHz crystal circuit with reference load capacitors. Exact crystal MPN
  and loading remain to be selected; the footprint is provisional.
- ABS07-32.768KHZ-7-T between XL1/XL2, with provisional 9 pF load capacitors.
  See [clock requirements](../../../CLOCKING.md). PCB parasitics require verification.
- TPS78230DDC 3.0 V regulator, input/output capacitors, and pads for a protected
  single-cell LiPo's factory-fitted leads. This regulator is **not** a charger
  or battery protection circuit. Do not solder directly to a bare pouch cell.
- SWD, reset, and power pads; reference RF matching network with a test pad,
  **no antenna**; provisional I2C display signal pads, **no OLED connector**.
- C10, C13 and C22 are unpopulated reference options. C9's 820 pF is for older
  MCU revisions; Nordic says it is unnecessary for build code Fxx and later.

## Buttons and bracket

| Position | Button/key | Proposed GPIO | Pad |
|---|---|---|---|
| Top left | A / 1 | P0.11 | TP3 |
| Bottom left | B / 2 | P0.12 | TP4 |
| Bottom right | C / 3 | P0.24 | TP5 |

These match the existing emulator assignments, **not a verified physical PCB**.
The proposal uses active-low inputs with firmware pull-ups. TP16 is a proposed
ground return for discrete switches. It does not establish that the original
bracket is grounded or that the existing spring contacts are compatible.
No footprint or copper connection represents the actual bracket. Charging
contacts are not assigned to the button contacts or bracket.

The user does not have the bracket available for measurement. Its continuity,
spring geometry, retention points, and battery clearance remain provisional.
Do not cut or electrically modify it on the basis of this draft.

## Mechanical assumptions

The 24 × 23.5 mm chamfered outline and 0.8 mm PCB thickness are planning
assumptions. They were **not** recovered from the DipTrace board or validated
against a case. The movement-holder mesh has an outer bounding box of about
26.18 × 25.47 × 4.40 mm; this is not the usable PCB or battery cavity.

The drawing-layer rectangle is a **16 × 12 mm rear battery space study**.
It is not a selected battery, copper keepout, or proof of fit. Battery thickness,
protection circuit, wires, insulation, swelling allowance, mounting adhesive,
and clearance from the metal bracket all still need a mechanical stack-up.
No mounting holes or bracket slots have been invented.

## Work required before a prototype order

1. Establish the actual case/holder cavity and bracket connections, then replace
   the provisional outline, contact pads, and battery envelope with measured geometry.
2. Select the protected LiPo and its permitted charge current and temperature
   limits. Capture the BQ25100 charger, temperature sensing, ESD/input protection,
   charging connector and system-load isolation or power path. These are **not
   implemented**. BQ25100 alone does not supply a complete power path; system
   load can affect charge termination. There is no working charging input yet.
3. Resolve the display discrepancy: firmware currently uses I2C, while the
   purchasing link describes SPI. Verify the exact OLED variant, supply rails,
   reset, pinout, FPC land pattern and pull-ups before wiring it.
4. Select the RF antenna and design its keepout/matching for the actual case,
   battery and metal bracket. The RF test pad is not a working antenna.
5. Complete the four-layer stack-up and copper routing. This draft has no
   tracks, vias or ground pours. Decoupling, RF return paths and crystal layout
   must be designed together. Confirm the board house can assemble AQFN73.
6. Select final passive ratings and crystal part numbers; review firmware power
   configuration, battery-voltage monitoring and low-battery behavior. Then run
   full ERC/DRC and hardware bring-up. Passing ERC alone does not validate a circuit.

`components.csv` is an inventory of the draft, not a purchasing BOM. Test pads
are copper features, not separate parts. Optional accelerometer and external
flash are not included in A0.

## References and verification

- [Nordic official QIAA reference layout v1.3](https://nsscprodmedia.blob.core.windows.net/prod/software-and-other-downloads/reference-layouts/nrf52840/nrf52840-qiaa-reference-layout-1_3.zip),
  configuration 6 schematic. The reference PCB was imported only for reading
  its component/net assignments; its routing is **not** reused in this draft.
- [TI TPS782 datasheet](https://www.ti.com/lit/ds/symlink/tps782.pdf).
- [TI BQ25100 datasheet](https://www.ti.com/lit/ds/symlink/bq25100.pdf),
  for the pending charging design.
- Standard KiCad 10 symbols and footprints are embedded in the design files.

Review outputs and manufacturer downloads live under `build/hardware-reference/`
inside this repository. See `VALIDATION.md` for the recorded check results.

`tools/create_draft.py` generated this initial version using KiCad's bundled
Python and standard libraries. It requires the Nordic config6 PCB imported at
`build/hardware-reference/nordic-config6.kicad_pcb`. **Do not rerun it after
editing the design**: it overwrites the schematic, PCB, project and inventory.
Future design work should edit the native KiCad files.
