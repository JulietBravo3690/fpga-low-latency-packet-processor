# Traffic Statistics Engine

The traffic statistics engine counts classified packet events produced by the packet classifier.

## Purpose

The packet processor should not only classify packets, but also report how much traffic has been processed and what types of packets have been seen.

This module adds hardware telemetry to the design.

## Inputs

| Signal | Meaning |
|---|---|
| `event_valid` | A packet classification event is valid |
| `packet_class` | Class assigned by the packet classifier |
| `allow_packet` | Packet was allowed |
| `drop_packet` | Packet was dropped |
| `packet_length` | Packet length used for byte counting |
| `packet_length_valid` | Indicates packet length is valid |
| `clear_counters` | Clears all counters |

## Counters

| Counter | Meaning |
|---|---|
| `total_packets` | Total classified packet events |
| `allowed_packets` | Packets allowed by classifier |
| `dropped_packets` | Packets dropped by classifier |
| `malformed_packets` | Packets with parser errors |
| `non_ipv4_packets` | Ethernet frames that are not IPv4 |
| `market_data_packets` | Packets classified as market-data traffic |
| `dns_packets` | DNS packets |
| `web_packets` | Web traffic packets |
| `control_packets` | Control packets |
| `trusted_packets` | Trusted endpoint packets |
| `unknown_packets` | Packets that did not match a known rule |
| `total_ipv4_bytes` | Total counted bytes for valid length events |
| `last_packet_length` | Most recent valid packet length |

## Register Read Interface

The statistics engine includes a simple register-style read interface.

| Address | Register |
|---:|---|
| 0 | Total packets |
| 1 | Allowed packets |
| 2 | Dropped packets |
| 3 | Malformed packets |
| 4 | Non-IPv4 packets |
| 5 | Market-data packets |
| 6 | DNS packets |
| 7 | Web packets |
| 8 | Control packets |
| 9 | Trusted packets |
| 10 | Unknown packets |
| 11 | Total IPv4 bytes |
| 12 | Last packet length |

## Design Importance

The statistics engine adds observability to the FPGA packet processor.

Instead of only producing a packet decision, the system can now report aggregate behavior over time. This is important for debugging, monitoring, performance analysis, and future software control.