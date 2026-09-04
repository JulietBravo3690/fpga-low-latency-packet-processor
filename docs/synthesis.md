# Generic Synthesis and RTL Lint

## Commands

```bash
make lint
make synth-check
```

`make lint` runs Verilator with `hardware_demo_top` as the design top. The lint
flow retains warnings for widths, inferred latches, case structure, and other
meaningful issues. Two warning classes are narrowly disabled in the Makefile:
optional top-level core ports are intentionally unconnected by the demonstration
wrapper (`PINMISSING`), and existing parser diagnostic/pass-through signals are
intentionally retained even when the integrated top does not consume them
(`UNUSEDSIGNAL`).

`make synth-check` reads all synthesizable RTL with Yosys SystemVerilog support,
synthesizes `hardware_demo_top`, and runs Yosys structural `check`. The command
writes a generated log under `build/`, which is ignored by Git. The flow was
executed locally with Yosys 0.33 and reported zero structural problems.

Yosys 0.33 reports that the packet buffer is lowered to registers in this
generic flow. This is a tool/mapping warning, not a structural failure. A chosen
FPGA flow must confirm whether the configured buffer maps to block RAM,
distributed RAM, or registers before device resource claims are made. The demo
uses a 128-byte buffer for a bounded generic synthesis check; the reusable
processor defaults to 2048 bytes.

## What This Proves

The checked RTL can be elaborated and converted into a generic synthesized
netlist by the stated open-source flow. It catches unsupported constructs,
multiple drivers, combinational loops reported by the tool, and other basic
structural synthesis failures.

## What This Does Not Prove

Generic synthesis is not device mapping, place-and-route, static timing
analysis, clock-domain analysis, or hardware validation. Generic cell counts
are not FPGA LUT/FF/BRAM utilization. This repository does not claim a target
device, clock frequency, timing closure, line rate, power, or measured latency.
