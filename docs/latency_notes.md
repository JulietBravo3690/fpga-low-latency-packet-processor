# Latency Notes

Latency will be measured in clock cycles.

Planned measurements:

| Stage | Measurement |
|---|---|
| Ethernet Parser | Start of packet to EtherType extracted |
| IPv4 Parser | Start of packet to source/destination IP extracted |
| UDP Parser | Start of packet to ports extracted |
| Classifier | Start of packet to classification result |
| Full Pipeline | Start of packet to final output |