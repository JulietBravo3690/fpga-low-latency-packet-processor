# Packet Format Notes

This project initially supports Ethernet II frames carrying IPv4 packets with UDP payloads.

The FPGA will receive one byte of packet data per clock cycle. Parser modules will extract fields from fixed byte positions.

## High-Level Packet Layout

```text
Ethernet Header | IPv4 Header | UDP Header | Payload
14 bytes        | 20 bytes    | 8 bytes    | variable