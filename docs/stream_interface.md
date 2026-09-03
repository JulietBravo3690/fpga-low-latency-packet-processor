# Flow-Controlled Packet Stream

The integrated processor uses a byte-wide ready/valid interface.

## Ingress

A byte is accepted only on a rising edge where `valid_in && in_ready` is true.
`data_in`, `sop_in`, and `eop_in` must remain stable while `valid_in` is asserted
and `in_ready` is low. SOP and EOP are meaningful only with valid; SOP marks the
first accepted byte and EOP the last. Idle gaps are permitted within a packet.
All parsers, the market decoder, and latency start logic receive an internal
accepted-valid pulse, so none advances when ingress is stalled.

## Egress

A byte is transmitted only when `valid_out && out_ready` is true. While
`valid_out` is high and `out_ready` is low, data, SOP, and EOP remain stable.
The current store-and-forward gate accepts one packet, waits for classification,
and either forwards the entire buffered frame or emits no bytes for it.

Back-to-back ingress packets are possible only when `in_ready` remains high. The
single-packet gate deasserts `in_ready` while it forwards the previous allowed
packet, so an upstream producer must retain its next byte until ready returns.
Packets are never interleaved.

## Buffer Limit

`PACKET_BUFFER_DEPTH` defaults to 2048 bytes and is configurable with a matching
index width. Frames that exceed the configured depth are drained and discarded;
`packet_buffer_overflow` remains asserted until reset. The buffer is implemented
as a synthesizable storage array. Generic Yosys lowers it to registers; a device
flow must verify the intended memory mapping. Classification telemetry may have
already counted an oversize packet before the later overflow is known, so the
configured depth must cover the operational maximum frame size. This design
favors correctness and clear policy enforcement over cut-through latency.

## Reset and Framing Errors

`rst_n` is asynchronous and active low. Reset aborts capture or forwarding,
clears valid outputs and parser state, and discards any partial packet. Valid
data without SOP, premature EOP, and a new SOP inside an unfinished frame are
reported by parser error logic and classified as malformed where detectable.
