# Architecture

The FPGA packet processor is organized as a streaming hardware pipeline.

## Data Plane vs Metadata Plane

The design is organized into two conceptual paths.

### Data Plane

The data plane carries the raw packet byte stream through the parser pipeline.

```text
data_in
valid_in
sop_in
eop_in
## High-Level Pipeline

```text
Input Byte Stream
      |
      v
Ethernet Parser
      |
      v
IPv4 Parser
      |
      v
UDP Parser
      |
      v
Classifier
      |
      v
Statistics / Market Data Decoder

