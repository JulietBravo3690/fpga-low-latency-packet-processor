#!/usr/bin/env python3
"""Build the fixed-format market-data UDP frame consumed by the RTL decoder."""

import argparse
import ipaddress
import struct
from pathlib import Path

MARKET_PAYLOAD_FORMAT = ">B4sIII"
MARKET_PAYLOAD_LENGTH = struct.calcsize(MARKET_PAYLOAD_FORMAT)


def mac_to_bytes(address: str) -> bytes:
    parts = address.split(":")
    if len(parts) != 6:
        raise ValueError("a MAC address must contain six octets")
    value = bytes(int(part, 16) for part in parts)
    if any(len(part) != 2 for part in parts):
        raise ValueError("each MAC octet must contain two hexadecimal digits")
    return value


def ipv4_checksum(header: bytes) -> int:
    if len(header) % 2:
        header += b"\x00"
    total = sum((header[index] << 8) | header[index + 1]
                for index in range(0, len(header), 2))
    while total >> 16:
        total = (total & 0xFFFF) + (total >> 16)
    return (~total) & 0xFFFF


def build_market_payload(message_type: int = 1, symbol: str = "AAPL",
                         price: int = 18_525, quantity: int = 100,
                         sequence_number: int = 1) -> bytes:
    symbol_bytes = symbol.encode("ascii")
    if len(symbol_bytes) != 4:
        raise ValueError("symbol must contain exactly four ASCII characters")
    return struct.pack(MARKET_PAYLOAD_FORMAT, message_type, symbol_bytes, price,
                       quantity, sequence_number)


def build_market_packet(*, message_type: int = 1, symbol: str = "AAPL",
                        price: int = 18_525, quantity: int = 100,
                        sequence_number: int = 1,
                        src_port: int = 5000, dst_port: int = 6000,
                        src_mac: str = "11:22:33:44:55:66",
                        dst_mac: str = "AA:BB:CC:DD:EE:FF",
                        src_ip: str = "192.168.1.10",
                        dst_ip: str = "192.168.1.20") -> bytes:
    payload = build_market_payload(message_type, symbol, price, quantity,
                                   sequence_number)
    ethernet = mac_to_bytes(dst_mac) + mac_to_bytes(src_mac) + b"\x08\x00"

    source_ip = ipaddress.IPv4Address(src_ip).packed
    destination_ip = ipaddress.IPv4Address(dst_ip).packed
    udp_length = 8 + len(payload)
    total_length = 20 + udp_length
    ipv4_without_checksum = struct.pack(
        ">BBHHHBBH4s4s", 0x45, 0, total_length, 1, 0x4000, 64, 17, 0,
        source_ip, destination_ip
    )
    checksum = ipv4_checksum(ipv4_without_checksum)
    ipv4 = ipv4_without_checksum[:10] + struct.pack(">H", checksum) + ipv4_without_checksum[12:]
    udp = struct.pack(">HHHH", src_port, dst_port, udp_length, 0)
    return ethernet + ipv4 + udp + payload


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--symbol", default="AAPL")
    parser.add_argument("--price", type=int, default=18_525,
                        help="unsigned integer price in application-defined units")
    parser.add_argument("--quantity", type=int, default=100)
    parser.add_argument("--sequence", type=int, default=1)
    output_group = parser.add_mutually_exclusive_group()
    output_group.add_argument("--output", type=Path,
                              help="write the raw frame to a binary file")
    output_group.add_argument("--hex-output", type=Path,
                              help="write one hexadecimal byte per line for $readmemh")
    output_group.add_argument("--sv-array", action="store_true",
                              help="print a SystemVerilog byte-array initializer")
    args = parser.parse_args()
    packet = build_market_packet(symbol=args.symbol, price=args.price,
                                 quantity=args.quantity,
                                 sequence_number=args.sequence)
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_bytes(packet)
    elif args.hex_output:
        args.hex_output.parent.mkdir(parents=True, exist_ok=True)
        args.hex_output.write_text("".join(f"{byte:02x}\n" for byte in packet),
                                   encoding="ascii")

    if args.sv_array:
        values = ", ".join(f"8'h{byte:02X}" for byte in packet)
        print("'{" + values + "}")
    else:
        print(f"Generated {len(packet)}-byte Ethernet/IPv4/UDP market-data frame")
        print(packet.hex(" "))


if __name__ == "__main__":
    main()
