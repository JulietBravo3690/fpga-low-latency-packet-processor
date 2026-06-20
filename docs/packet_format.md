# Packet Format Notes

This project will initially support Ethernet II frames carrying IPv4 packets with UDP payloads.

## Ethernet Header

| Field | Size |
|---|---:|
| Destination MAC | 6 bytes |
| Source MAC | 6 bytes |
| EtherType | 2 bytes |

EtherType for IPv4:

```text
0x0800