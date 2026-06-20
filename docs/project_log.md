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