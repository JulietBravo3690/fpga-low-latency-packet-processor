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
