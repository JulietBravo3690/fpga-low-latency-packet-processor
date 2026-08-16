# Supported Packet Format

The implemented fast path accepts Ethernet II containing IPv4 with a 20-byte header (version 4, IHL 5), followed by UDP.

| Offset | Size | Field |
|---:|---:|---|
| 0 | 14 | Ethernet II header |
| 14 | 20 | IPv4 header |
| 34 | 8 | UDP header |
| 42 | variable | UDP payload |

Multi-byte values are network-byte-order (big endian). IPv4 options, VLAN headers, and fragmented layouts are outside the current parser scope.

## Demonstrator Market Message

A UDP packet whose source or destination port is in the inclusive range 5000–6000 can carry this fixed 17-byte payload:

| Payload offset | Size | Field |
|---:|---:|---|
| 0 | 1 | Message type (unsigned) |
| 1 | 4 | Symbol (four ASCII bytes) |
| 5 | 4 | Price (unsigned, application-defined units) |
| 9 | 4 | Quantity (unsigned) |
| 13 | 4 | Sequence number (unsigned) |

The decoder requires an exact UDP length of 25 bytes (8-byte UDP header plus
this payload). Shorter and longer declarations assert `decoder_error`; no
extended message schema is currently defined. It does not claim compatibility
with a real exchange protocol.
The decoder requires a UDP length of at least 25 bytes (8-byte UDP header plus this payload). It does not claim compatibility with a real exchange protocol.
