# Architecture

The FPGA packet processor is organized as a streaming hardware pipeline.

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