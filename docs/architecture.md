# Architecture

The FPGA packet processor is organized as a streaming hardware pipeline.

## Data Plane vs Metadata Plane

The design is organized into two conceptual paths.

### Data Plane

The data plane carries the raw packet byte stream through the parser pipeline.

## Top-Level Packet Processor

The top-level module integrates the Ethernet parser, IPv4 parser, UDP parser, metadata completion logic, and packet classifier.

```text
Raw Packet Stream
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
Metadata Completion Unit
        |
        v
Packet Classifier
        |
        v
Class + Allow/Drop Decision

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

## Traffic Statistics Engine

After classification, the traffic statistics engine counts packet events.

```text
Packet Classifier
        |
        v
Traffic Statistics Engine
        |
        v
Counters / Register Read Interface