# Hardware Integration and Bring-Up

## Current Board-Agnostic Demonstration

`hardware_demo_top` connects the synthesizable 59-byte reference source to the
flow-controlled `top_packet_processor` and sticky status snapshots. `start_ready`
qualifies a new demonstration request. The wrapper ties processor egress ready
high, while the reusable processor interface supports downstream backpressure.
No vendor primitive, physical constraint, or external memory file is required.

## Future Live-Ethernet Path

```text
Ethernet PHY --> Ethernet MAC --> width/framing adapter --> packet processor
                                                        --> downstream consumer
```

MII, GMII, RGMII, or a vendor MAC's AXI Stream can feed an adapter. The adapter
must translate frame boundaries to SOP/EOP, propagate ready correctly, and buffer
across any width or clock-domain conversion. AXI Stream has `tlast` but no SOP,
so SOP must be derived from adapter packet state. A MAC commonly handles
preamble/SFD and may check/remove FCS; that boundary must be explicit.

The new packet processor can backpressure an adapter, but this does not by itself
solve PHY/MAC elasticity or clock-domain crossing. Those choices depend on the
selected board and MAC.

## Bring-Up Roadmap

1. **Complete:** functional parsing, classification, decoding, statistics, and latency simulation.
2. **Complete:** store-and-forward policy enforcement with ready/valid flow control.
3. **Complete:** TCP fast-path parsing and protocol-qualified classification.
4. **Complete:** generic lint/synthesis and packet-ROM demonstration.
5. **Board-dependent:** clock/reset wrapper, constraints, and inferred-memory review.
6. **Board-dependent:** ILA/SignalTap observation and on-FPGA ROM test.
7. **Future:** MAC adapter, CDC/elastic buffering, PHY connection, and live capture.
8. **Future:** device timing closure and measured latency/throughput.

Only stages 1–4 are evidenced here; no physical hardware validation is claimed.
