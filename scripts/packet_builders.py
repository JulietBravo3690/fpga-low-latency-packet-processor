"""Standard-library reference frame builders for RTL verification."""

import ipaddress
import struct

from generate_market_packet import ipv4_checksum, mac_to_bytes

DEFAULT_DST_MAC = "AA:BB:CC:DD:EE:FF"
DEFAULT_SRC_MAC = "11:22:33:44:55:66"
DEFAULT_SRC_IP = "10.0.0.1"
DEFAULT_DST_IP = "10.0.0.2"


def build_ethernet_header(ethertype: int = 0x0800, *,
                          dst_mac: str = DEFAULT_DST_MAC,
                          src_mac: str = DEFAULT_SRC_MAC) -> bytes:
    return (mac_to_bytes(dst_mac) + mac_to_bytes(src_mac) +
            ethertype.to_bytes(2, byteorder="big"))


def build_ipv4_header(protocol: int, payload_length: int, *,
                      src_ip: str = DEFAULT_SRC_IP,
                      dst_ip: str = DEFAULT_DST_IP) -> bytes:
    source = ipaddress.IPv4Address(src_ip).packed
    destination = ipaddress.IPv4Address(dst_ip).packed
    header = struct.pack(">BBHHHBBH4s4s", 0x45, 0, 20 + payload_length,
                         1, 0x4000, 64, protocol, 0, source, destination)
    checksum = ipv4_checksum(header)
    return header[:10] + struct.pack(">H", checksum) + header[12:]


def build_udp_frame(payload: bytes = b"", *, src_port: int = 3000,
                    dst_port: int = 3001, src_ip: str = DEFAULT_SRC_IP,
                    dst_ip: str = DEFAULT_DST_IP) -> bytes:
    udp_length = 8 + len(payload)
    udp = struct.pack(">HHHH", src_port, dst_port, udp_length, 0)
    return (build_ethernet_header() +
            build_ipv4_header(17, udp_length, src_ip=src_ip, dst_ip=dst_ip) +
            udp + payload)


def build_tcp_frame(payload: bytes = b"", *, src_port: int = 5000,
                    dst_port: int = 80, flags: int = 0x02,
                    src_ip: str = DEFAULT_SRC_IP,
                    dst_ip: str = DEFAULT_DST_IP) -> bytes:
    # TCP checksum is zero because the RTL fast path does not validate it.
    tcp = struct.pack(">HHIIHHHH", src_port, dst_port, 0, 0,
                      (5 << 12) | flags, 0, 0, 0)
    segment = tcp + payload
    return (build_ethernet_header() +
            build_ipv4_header(6, len(segment), src_ip=src_ip, dst_ip=dst_ip) +
            segment)


def build_non_ipv4_frame(payload: bytes = b"", ethertype: int = 0x0806) -> bytes:
    return build_ethernet_header(ethertype) + payload


def build_malformed_frame() -> bytes:
    """Return a deliberately truncated Ethernet header."""
    return bytes.fromhex("AA BB CC")
