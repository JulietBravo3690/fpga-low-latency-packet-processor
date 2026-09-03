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

## Hardware-Demo Reference Frame

`packet_rom_source` and the Makefile's Python-generated reference vector use the
same 59-byte frame: destination/source MAC `AA:BB:CC:DD:EE:FF` /
`11:22:33:44:55:66`, IPv4 addresses `192.168.1.10` / `192.168.1.20`, UDP ports
5000 / 6000, message type 1, symbol `AAPL`, price 18525, quantity 100, and
sequence number 42. The IPv4 total length is 45 and UDP length is 25.

## TCP Fast Path

For IPv4 protocol 6 with IHL=5, TCP begins at Ethernet offset 34. The parser
extracts source and destination ports at offsets 34–37, the data offset at byte
46, and flags at byte 47. It requires data offset >= 5 and a complete 20-byte
minimum header through byte 53. The fixed fast path requires data offset 5;
TCP options and checksum validation are not implemented.
