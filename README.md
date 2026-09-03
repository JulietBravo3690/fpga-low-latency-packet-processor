# Flow-Controlled FPGA Packet Processor

A vendor-neutral SystemVerilog datapath for Ethernet II, fixed-header IPv4, UDP,
and TCP traffic. The processor accepts a byte-wide ready/valid stream, extracts
metadata, classifies each frame, updates telemetry, and then **physically
forwards or suppresses the buffered packet** according to the hardware decision.

The repository is simulation-verified and generically linted/synthesized. It has
not been deployed to a physical FPGA and contains no measured performance claim.

## Architecture

```text
Ingress data/valid/SOP/EOP <--> ready
             |
             +--> Ethernet + IPv4 + UDP/TCP parsers --> classifier
             +--> market decoder                         |
             +--> latency/statistics                 allow/drop
             |                                           |
             +--> store-and-forward packet buffer <------+
                              |
                    Egress data/valid/SOP/EOP <--> ready
```

No egress byte is exposed until a decision is available. Allowed packets are
forwarded byte-for-byte; dropped packets produce zero output bytes. The default
2048-byte, single-packet buffer provides downstream backpressure and deliberately
trades cut-through latency for enforceable policy and straightforward packet
ownership.

## Implemented and Verified

- Ethernet II and IPv4 version 4 with IHL=5 parsing
- UDP ports, length, and checksum-field extraction
- TCP source/destination ports, data offset, flags, and minimum-header validation
- Market UDP, DNS, TCP HTTP/HTTPS, control/SSH, trusted, unknown, non-IPv4, and malformed classes
- Protocol-qualified rules that prevent stale/default ports from causing false matches
- Configurable unknown allow/drop policy with actual datapath enforcement
- Stable ready/valid egress under downstream stalls and ingress backpressure
- Fixed 17-byte demonstrator market message decoding
- Per-class counters, IPv4 byte accounting, and cycle-level parser/decision latency
- Python builders for market UDP, generic UDP, TCP, non-IPv4, and malformed frames
- Board-agnostic packet-ROM demonstration and sticky hardware status
- Directed SystemVerilog/Python regression, Verilator lint, Yosys generic synthesis, and CI

## Run Verification

Dependencies: Python 3, Icarus Verilog, Verilator, and Yosys.

```bash
make help
make clean
make test-all
make lint
make synth-check
```

Focused targets include `test-tcp`, `test-gate`, `test-flow`, `test-top`,
`test-market`, and `test-hardware-demo`.

## Interface Contract

Ingress bytes are consumed only on `valid_in && in_ready`. Egress bytes transfer
only on `valid_out && out_ready`; output data and boundaries remain stable while
stalled. Idle gaps are legal. Packets cannot be interleaved, and the upstream
must hold a pending byte during backpressure. See
[docs/stream_interface.md](docs/stream_interface.md).

## Evidence and Limitations

### Simulation-verified

Directed tests verify exact allowed-frame forwarding, zero-byte suppression for
three drop cases, unknown allow mode, TCP HTTP/HTTPS/SSH classification, ingress
gaps, deterministic egress stalls, multiple sequential packets, market decoding,
statistics, and latency instrumentation.

### Generic synthesis-checked

Yosys elaborates and synthesizes the board-agnostic demonstration and runs a
structural check. Verilator provides RTL lint. These checks do not establish
device utilization, memory mapping quality, timing closure, or hardware behavior.

### Not hardware-validated

There is no selected FPGA, board clock, pin constraint, MAC, PHY, live Ethernet,
place-and-route result, measured frequency, measured throughput, or measured
latency. The market payload is a demonstration schema, not a production exchange
protocol. VLAN, IPv4 options, fragmentation, TCP checksum/state tracking, UDP
checksum validation, and multi-packet buffering remain outside the current scope.

See [architecture](docs/architecture.md), [packet format](docs/packet_format.md),
[verification](docs/verification_plan.md), and
[hardware integration](docs/hardware_integration.md).
