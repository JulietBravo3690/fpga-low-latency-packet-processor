# Verification Plan

## Automated Functional Coverage

`make test-all` runs the original parser, classifier, statistics, market,
latency, top-level, packet-source, hardware-demo, and Python tests plus:

- `test-tcp`: ports, data offset, flags, idle gaps, short TCP, and non-TCP input.
- `test-gate`: decision gating, exact forwarding, output stability under stall,
  complete drop suppression, reuse, and oversize-frame drain behavior.
- `test-flow`: eight sequential packets through the integrated processor.

The flow-controlled integration test covers an allowed market UDP frame, dropped
non-IPv4 and malformed frames, dropped and allowed unknown UDP modes, TCP HTTP,
TCP HTTPS, and TCP SSH/control. It inserts ingress idle gaps and deterministic
egress backpressure, compares every transmitted byte, checks SOP/EOP counts,
checks decision order, and verifies class and byte statistics. Testbench
invariants reject output changes during a stall, SOP/EOP without valid, and
simultaneous allow/drop.

Python standard-library tests cover generic UDP, TCP, non-IPv4, and deliberately
truncated frame builders in addition to the market vector formats.

CI runs functional simulation, Verilator lint, and generic Yosys synthesis and
structural checks.

## Remaining Verification Work

The suite is directed, not constrained-random. The single-packet gate has not
been proven formally. Future work includes assertions bound to the RTL,
randomized packet sequences, functional coverage, formal no-loss/no-duplication
properties, device memory inference review, timing analysis, and hardware tests.
## Automated Coverage

`make test-all` runs self-checking SystemVerilog tests for stream framing, every parser, classification, statistics, latency tracking, market decoding, and the integrated top level. It also runs standard-library Python tests that validate generated packet vectors at each protocol boundary. GitHub Actions runs `make clean` followed by this suite on every push and pull request.

The top-level test loads the hex file emitted by
`generate_market_packet.py`. It proves that the same 59-byte reference frame is
parsed with IPv4/UDP lengths 45/25, classified and allowed as market data,
decoded to the expected fields, counted as 45 IPv4 bytes, and observed at every
latency milestone in monotonic order.

Covered negative cases include missing packet boundaries, short headers,
unsupported EtherType or IP layouts, non-UDP input, counter clearing, early
market payload EOP, and short or overlong market UDP declarations. The decoder
also runs with continuous bytes and idle cycles between bytes and checks that
`message_valid` is a one-cycle pulse.

## Remaining Verification Work

`make test-all` runs self-checking SystemVerilog tests for stream framing, every parser, classification, statistics, latency tracking, market decoding, and the integrated top level. It also runs standard-library Python tests that validate generated packet vectors at each protocol boundary.

Covered negative cases include missing packet boundaries, short headers, unsupported EtherType or IP layouts, non-UDP input, counter clearing, and a too-short market payload declaration. The market decoder test checks every decoded field. The latency test checks milestone capture and completion behavior.

## Remaining Verification Work

The suite is directed rather than constrained-random. Future work includes assertions, functional coverage, randomized gaps and malformed frames, synthesis lint, formal parser properties, and post-place-and-route timing validation.
