# A0 draft verification — 2026-10-03

Checked with KiCad 10.0.6:

| Check | Result |
|---|---|
| Schematic loads and exports | Passed |
| Electrical rules check | 0 errors, 0 warnings |
| PCB loads and exports | Passed |
| Schematic/PCB parity | 0 issues |
| PCB geometric/rule checks, excluding unrouted connections | 0 violations |
| Unrouted connections | **76 — unresolved** |
| Physical fit, power/charging operation, RF performance | **Not verified** |

The overall PCB is **not DRC-clean or fabrication-ready**: it has no copper
routing. ERC checks connectivity conventions, not functional completeness.
There is no onboard charging circuit, selected antenna, or verified display
connector in this draft. See README.md for the remaining design work.

The schematic and PCB exports were rendered and visually inspected. Manufacturer
reference pin/net assignments were checked against Nordic's configuration 6
schematic. The battery rectangle and outline are labeled provisional.

Reports and review renders are in `build/hardware-reference/` at repository root:
`erc.rpt`, `drc.rpt`, `schematic-review.png`, and `board-review.png`.

From repository root, regenerate checks with:

```sh
kicad-cli sch erc --exit-code-violations \
  -o build/hardware-reference/erc.rpt \
  Hardware/KiCad/drafts/f91_jepler/f91_jepler.kicad_sch
kicad-cli pcb drc --schematic-parity --exit-code-violations \
  -o build/hardware-reference/drc.rpt \
  Hardware/KiCad/drafts/f91_jepler/f91_jepler.kicad_pcb
```

The PCB command is expected to return nonzero until routing is finished.
On this Mac, `kicad-cli` is at
`/Applications/KiCad/KiCad.app/Contents/MacOS/kicad-cli`.
