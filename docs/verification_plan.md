# Verification Plan

The design will be verified using Python-generated packets and SystemVerilog or cocotb testbenches.

## Initial Test Cases

- Valid Ethernet frame
- Valid Ethernet + IPv4 packet
- Valid Ethernet + IPv4 + UDP packet
- Invalid EtherType
- Short Ethernet frame
- Unsupported protocol
- Market-data UDP packet

## Verification Goals

- Confirm extracted fields match expected packet fields
- Confirm malformed packets are detected
- Confirm packet classification is correct
- Measure cycle-level latency through the pipeline