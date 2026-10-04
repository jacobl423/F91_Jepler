# nRF52840 timekeeping crystal

The redesign includes an external 32.768 kHz crystal. The nRF52840 supplies
its oscillator amplifier and RTC counters; no separate RTC IC is required.
The [KiCad A0 draft](KiCad/drafts/f91_jepler/README.md) captures this circuit with
provisional loading; physical routing is still pending. The existing DipTrace files describe the legacy CC2640 design.

## Components and connections

Select one **Abracon ABS07-32.768KHZ-7-T**: 7 pF load, ±20 ppm initial tolerance
at 25°C, 70 kΩ maximum ESR, 2 pF maximum shunt capacitance, and 0.5 µW maximum
drive. Its package is 3.2 × 1.5 × 0.9 mm. Temperature and aging add error beyond
initial tolerance. [Manufacturer datasheet](https://abracon.com/Resonators/ABS07.pdf)

Connect the crystal between `XL1` and `XL2`, with one equal-value C0G/NP0
capacitor from each terminal to ground. Reserve these pins for the crystal;
do not reuse them for buttons. Resolve physical pad numbers against the
chosen MCU package when capturing the schematic.

Nordic specifies limits of 12.5 pF load, 100 kΩ ESR, 2 pF shunt capacitance,
and 0.5 µW drive. The listed crystal parameters fit these limits. This is a
specification check, not validation of an assembled board.
[Nordic clock specification](https://docs.nordicsemi.com/r/bundle/ps_nrf52840/page/clock.html)

## Capacitors and placement

For symmetrical loading, calculate each external capacitor as:

`C_external = 2 × C_load − C_pin − C_PCB_per_pin`

Nordic lists typical pin capacitance of 4 pF. For this 7 pF crystal,
`C_external = 10 pF − C_PCB_per_pin`. For example, 1 pF of PCB capacitance
per side gives 9 pF external capacitors. This is an example, not a released
BOM value. Finalize both values after routing and validate startup and
frequency on hardware.
[Nordic load calculation](https://docs.nordicsemi.com/r/bundle/ps_nrf52840/page/clock.html)

Place the crystal and capacitors close to the MCU with short, balanced traces
and short ground returns. Keep switching-power and fast digital signals away.
Use the manufacturer land pattern subject to assembly rules. Assign reference
designators in the new schematic to avoid collisions with legacy components.

## Firmware and simulation

The common application overlay selects `k32src = "xtal"` at 32768 Hz.
The 50 ppm firmware declaration must be checked against the finished board's
loading, temperature and aging budget; it does not guarantee total accuracy.
The separate 32 MHz high-frequency crystal remains in the design.

Renode already supplies an ideal 32768 Hz RTC timebase. It does not model
quartz drift, capacitor loading or analog startup. Firmware starts at
12:00:00 AM on each application boot and counts simulated elapsed seconds.
