# Packet Classification Rules

The packet classifier converts parsed packet metadata into a hardware classification decision.

## Inputs

The classifier receives metadata from earlier parser stages:

| Signal | Meaning |
|---|---|
| `ethertype` | Ethernet payload type |
| `ip_protocol` | IPv4 protocol field |
| `src_ip` | Source IPv4 address |
| `dst_ip` | Destination IPv4 address |
| `src_port` | UDP/TCP source port |
| `dst_port` | UDP/TCP destination port |
| `parser_error` | Indicates malformed packet or parser failure |
| `drop_unknown` | Controls whether unknown traffic is dropped |

## Output Classes

| Class ID | Class Name | Meaning |
|---:|---|---|
| 0 | Malformed | Packet had a parser error |
| 1 | Non-IPv4 | Ethernet frame was not IPv4 |
| 2 | Market Data | UDP packet using configured market-data port range |
| 3 | DNS | Packet uses port 53 |
| 4 | Web | TCP packet using port 80 or 443 |
| 5 | Control | Packet uses SSH, NTP, or custom control port |
| 6 | Trusted | Packet matches trusted IP rule |
| 7 | Unknown | Packet did not match any rule |

## Priority Order

Rules are evaluated in priority order:

1. Malformed packets
2. Non-IPv4 packets
3. Market-data packets
4. DNS packets
5. Web packets
6. Control packets
7. Trusted packets
8. Unknown packets

Malformed and non-IPv4 packets are dropped. Known traffic classes are allowed. Unknown traffic is controlled by the `drop_unknown` input.

## Market Data Rule

A packet is classified as market data if:

```text
IP protocol = UDP
AND source or destination port is between 5000 and 6000
```
