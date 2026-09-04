# Architecture

## Flow-Controlled Data Plane

```text
Ingress ready/valid byte stream
          |
          +--> Ethernet parser --+
          +--> IPv4 parser ------+--> metadata completion --> classifier
          +--> UDP parser -------+                              |
          +--> TCP parser -------+                         allow / drop
          +--> market decoder                                   |
          +--> latency tracker                                  v
          +--------------------------------------------> packet gate
                                                               |
                                             allowed: full frame forwarded
                                             dropped: zero output bytes
```

All parsing state advances only on an accepted ingress handshake. The packet
gate buffers a complete frame because classification occurs after header bytes
have arrived. It does not expose any packet byte until a decision exists. The
single-packet store-and-forward architecture provides simple, verifiable
backpressure at the cost of buffer storage and whole-frame latency.

## Metadata and Layer 4 Selection

Ethernet and IPv4 metadata are cleared at each accepted SOP. UDP completion
selects UDP ports; TCP completion selects TCP ports. Other IPv4 protocols are
classified after the IPv4 header with zero layer-4 ports, preventing stale port
metadata from creating false DNS or control matches. TCP parsing supports the
fixed IPv4 IHL=5 fast path, extracts ports, data offset, and flags, and validates
a minimum 20-byte TCP header.

Classification events feed both traffic statistics and the packet gate. The
market decoder remains attached only to market-port UDP payloads. Latency tracks
ingress SOP through parser and decision milestones; it does not include buffered
egress drain time.

## Hardware Demonstration

`hardware_demo_top` connects the reusable reference source to the flow-controlled
processor. `start_ready` indicates when a source transaction can be accepted.
The egress is always ready in this wrapper, while the processor interface itself
supports downstream stalls. Sticky status remains available for future board
observation.
