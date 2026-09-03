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
# Low-Latency FPGA Packet Processor

A synthesizable SystemVerilog portfolio project that accepts an 8-bit packet stream and extracts Ethernet II, fixed-header IPv4, and UDP metadata. The integrated design classifies packets, updates telemetry counters, decodes a small demonstrator market-data payload, and reports cycle counts for parser milestones.

No device-specific timing or throughput result is claimed: this repository contains simulation-oriented functional verification, not a published synthesis or timing-closure report.

## Implemented Functionality

- Ethernet II, IPv4 (version 4, IHL 5), and UDP fixed-offset parsing
- Classification of malformed, non-IPv4, market-data-port, DNS, web, control, trusted, and unknown traffic
- Configurable allow/drop handling for unknown packets
- Per-class counters, IPv4 byte totals, and a register-style statistics read interface
- Fixed 17-byte market message decoding (type, four-character symbol, price, quantity, and sequence)
- Cycle counters from accepted start-of-packet to Ethernet, IPv4, UDP, classification, and statistics events
- End-to-end verification that a Python-generated market frame is parsed,
  classified, decoded, counted as 45 IPv4 bytes, and latency-instrumented at the
  top level
- Self-checking SystemVerilog tests, Python packet-vector tests, and GitHub
  Actions CI that runs the complete verification suite
- Self-checking SystemVerilog tests and Python packet-vector tests

## Architecture

```text
8-bit packet stream
       +--> Ethernet parser --> IPv4 parser --> UDP parser
       |                              |
       |                              +--> metadata classifier --> statistics
       |                                             |
       +--> latency tracker                         allow/drop
       |
       +--> market-data payload decoder (market UDP packets only)
```

The parser modules observe the same input stream; their registered metadata is assembled by `top_packet_processor`. See [the architecture notes](docs/architecture.md), [packet format](docs/packet_format.md), and [verification plan](docs/verification_plan.md).

## Running Verification

The RTL suite requires Icarus Verilog with SystemVerilog 2012 support and Python 3:

```bash
make test-all
```

Individual targets include `test-stream`, `test-eth`, `test-ipv4`, `test-udp`, `test-classifier`, `test-stats`, `test-latency`, `test-market`, `test-top`, and `test-python`.

Generate a readable vector or binary frame:

```bash
python3 scripts/generate_market_packet.py
python3 scripts/generate_market_packet.py --symbol MSFT --price 41750 --output /tmp/market.bin
python3 scripts/generate_market_packet.py --hex-output sim/market_packet.hex
python3 scripts/generate_market_packet.py --sv-array
```

## Scope and Roadmap

The following are **not implemented** and remain roadmap work:

- Ethernet FCS validation, VLAN tags, IPv4 options, fragmentation/reassembly, TCP parsing, and UDP checksum validation
- Backpressure or a ready/valid flow-control interface
- Multiple market-message schemas or exchange protocol compatibility
- Hardware synthesis, place-and-route, board integration, measured clock frequency, or measured wire-to-decision latency
- Software-accessible bus integration for statistics
