# Low-Latency FPGA Network Packet Processor

## Overview

This project implements a low-latency FPGA packet processing pipeline for Ethernet, IPv4, and UDP network traffic. The system is designed to parse packet headers, classify traffic, track real-time statistics, and decode simulated market-data packets for financial networking applications.

The goal of this project is to demonstrate FPGA-based networking, packet parsing, hardware pipelines, low-latency design, and verification using SystemVerilog and Python-based testing.

## Project Motivation

Modern trading firms, defense systems, and high-performance computing platforms often rely on low-latency networking hardware to process data quickly and deterministically. This project explores how an FPGA can be used to inspect and classify packets directly in hardware.

## Planned Features

- Ethernet frame parsing
- IPv4 header parsing
- UDP packet parsing
- Packet classification
- Real-time traffic statistics
- Cycle-level latency measurement
- Simulated market-data packet decoding
- Python-generated packet testing

## System Architecture

```text
Packet Byte Stream
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
Packet Classifier
      |
      v
Traffic Statistics Engine
      |
      v
Market Data Decoder