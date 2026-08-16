# Metadata Pipeline

The data stream and metadata are separate. Parser instances observe raw bytes in parallel, while `top_packet_processor` retains completed fields for the classifier.

Classification is triggered for:

1. a parser-error event,
2. a non-IPv4 event, or
3. a completed UDP header.

A classification event contains class, allow, and drop outputs. The traffic statistics engine samples that event on the next active edge according to normal registered SystemVerilog behavior. TCP and ICMP are recognized by the IPv4 parser, but the integrated completion logic currently produces normal classifications only for completed UDP packets; expanding integrated non-UDP handling is roadmap work.
