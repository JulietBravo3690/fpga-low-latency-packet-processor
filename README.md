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
