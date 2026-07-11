# Project Log

## Day 1

- Created GitHub repository
- Set up project folder structure
- Added initial README
- Added documentation files
- Added planned RTL module placeholders
- Added planned testbench placeholders

## Next Step

Start learning Ethernet frame structure and build the first Python packet generator. 

## Day 2

- Reviewed Ethernet II, IPv4, and UDP packet structure
- Documented packet byte offsets
- Created a Python script to generate a valid Ethernet/IPv4/UDP packet
- Verified packet length and important header fields
- Prepared packet generator for future parser testbenches

## Next Step

Build the first SystemVerilog input module that receives packet data one byte per clock cycle.

## Day 3

- Built the first RTL module: `packet_stream_input.sv`
- Created a one-byte-per-clock packet stream interface
- Added packet start and packet end signaling
- Added byte counting for incoming packets
- Added simple malformed packet detection
- Wrote a SystemVerilog testbench for valid and invalid packet cases
- Ran simulation and verified packet length detection

## Next Step

Build the Ethernet parser to extract destination MAC, source MAC, and EtherType from the incoming packet stream. 

## Day 4

- Built `ethernet_parser.sv`
- Added byte-position-based Ethernet header parsing
- Extracted destination MAC, source MAC, and EtherType
- Added IPv4 frame detection using EtherType `0x0800`
- Added unsupported EtherType detection
- Added short-frame parser error detection
- Created and ran `tb_ethernet_parser.sv`
- Verified parser behavior using three simulation tests

## Next Step

Build the IPv4 parser to extract version, IHL, total length, protocol, source IP, and destination IP.

## Day 5

- Built `ipv4_parser.sv`
- Parsed IPv4 header fields from Ethernet frame byte offsets
- Extracted IP version, IHL, total length, protocol, source IP, and destination IP
- Added UDP/TCP/ICMP protocol detection
- Added non-IPv4 frame detection
- Added short IPv4 packet error detection
- Created and ran `tb_ipv4_parser.sv`
- Verified IPv4 parsing through simulation

## Next Step

Build the UDP parser to extract source port, destination port, UDP length, and UDP checksum.

## Day 6

- Built `udp_parser.sv`
- Parsed UDP source port, destination port, length, and checksum
- Added UDP protocol validation from the IPv4 protocol field
- Added market-data-style packet detection for destination ports 5000-6000
- Added short UDP header error detection
- Created and ran `tb_udp_parser.sv`
- Added a Makefile to simplify simulation commands

## Next Step

Build the packet classifier to assign packets into categories such as market data, DNS, web traffic, and unknown traffic.

## Day 7

- Designed the packet classification stage as the first major metadata-processing module
- Separated the project conceptually into a data plane and metadata plane
- Built `packet_classifier.sv`
- Added classification rules for malformed packets, non-IPv4 traffic, market data, DNS, web traffic, control traffic, trusted endpoints, and unknown traffic
- Added configurable unknown-traffic drop behavior
- Created `tb_packet_classifier.sv`
- Verified seven packet-classification scenarios in simulation
- Added `docs/classification_rules.md`
- Updated the Makefile with `make test-classifier`
- Updated project architecture documentation

## Next Step

Build the top-level packet processor module that connects the parser outputs into the classifier and creates the first end-to-end metadata pipeline.


---

## Day 8

- Built `top_packet_processor.sv`
- Integrated Ethernet parser, IPv4 parser, UDP parser, metadata completion logic, and packet classifier
- Created the first end-to-end packet-processing pipeline
- Added metadata registers for Ethernet, IPv4, and UDP fields
- Added classifier trigger logic based on parser error, non-IPv4 detection, and UDP header completion
- Created `tb_top_packet_processor.sv`
- Verified end-to-end classification for market data, DNS, trusted traffic, unknown traffic, non-IPv4 traffic, and malformed packets
- Added `docs/metadata_pipeline.md`
- Updated Makefile with `make test-top`
- Updated architecture documentation

## Next Step

Build the traffic statistics engine to count total packets, allowed packets, dropped packets, market-data packets, DNS packets, malformed packets, and total classified packets.

## Day 9

- Built `traffic_stats.sv`
- Added counters for total packets, allowed packets, dropped packets, malformed packets, non-IPv4 packets, market-data packets, DNS packets, web packets, control packets, trusted packets, and unknown packets
- Added total IPv4 byte counting
- Added last-packet-length tracking
- Added `clear_counters` control signal
- Added a register-style statistics read interface
- Created `tb_traffic_stats.sv`
- Verified counter updates, register reads, and counter clearing in simulation
- Added `docs/statistics_engine.md`
- Updated Makefile with `make test-stats`

## Next Step

Integrate the traffic statistics engine into the top-level packet processor so end-to-end classified packets automatically update hardware counters.

## Day 10

- Integrated `traffic_stats.sv` into `top_packet_processor.sv`
- Connected classifier events directly into hardware traffic counters
- Added top-level statistics read interface signals
- Added top-level counter outputs for total packets, allowed packets, dropped packets, packet classes, and total IPv4 bytes
- Updated `tb_top_packet_processor.sv` to verify end-to-end classification and statistics updates
- Verified that market-data, DNS, trusted, unknown, non-IPv4, and malformed packets update the correct counters
- Verified register-style statistics reads from the integrated top-level design
- Verified counter clearing through the top-level module

## Next Step

Build a latency tracker to measure cycle-level delay from start-of-packet to Ethernet parsing, IPv4 parsing, UDP parsing, classification, and statistics update.