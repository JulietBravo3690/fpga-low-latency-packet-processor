# Metadata and Decision Pipeline

At every accepted SOP, integrated Ethernet, IP, UDP, TCP, and selected layer-4
port registers are cleared. This prevents one packet's ports or addresses from
contaminating the next decision.

Classification is triggered by the first applicable completion event:

1. any parser error → malformed,
2. unsupported Ethernet type → non-IPv4,
3. complete UDP header → classify with UDP ports,
4. complete TCP header → classify with TCP ports,
5. complete supported IPv4 header with another protocol → classify with zero ports.

DNS matching is restricted to UDP. Web matching is restricted to TCP. Control
port matching is restricted to UDP or TCP. Trusted endpoint matching remains
available for supported IPv4 traffic. The one-cycle classifier result updates
statistics and authorizes the buffered packet gate.

The gate can receive a decision before or after EOP. It retains the decision
until capture completes, then forwards the exact stored frame for allow or
returns directly to capture for drop. No speculative bytes reach egress.
