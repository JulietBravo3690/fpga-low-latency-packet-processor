# Architecture

## Streaming Data Plane

All three parsers observe the same one-byte-wide input stream (`data_in`, `valid_in`, `sop_in`, and `eop_in`). Parser outputs are registered. The top-level output stream is a direct copy of the input; this design produces metadata and decisions rather than rewriting packets.

```text
Input stream --+--> Ethernet parser --+
               +--> IPv4 parser ------+--> metadata completion --> classifier --> statistics
               +--> UDP parser -------+
               +--> latency tracker
               +--> market decoder (enabled after a market UDP header)
```

## Metadata Plane

`top_packet_processor` captures completed Ethernet, IPv4, and UDP fields. A malformed event, a non-IPv4 decision, or a complete UDP header triggers classification. The classifier emits a one-cycle class event consumed by the traffic statistics engine.

The decoder is technically separate from classification: the UDP parser's market-port detection enables it on the first payload byte. It implements only the payload documented in [packet format](packet_format.md).

The latency tracker timestamps parser and downstream event pulses relative to an accepted start-of-packet. Values are cycle counts in the actual simulation or implementation; they are observability outputs, not benchmark claims.
