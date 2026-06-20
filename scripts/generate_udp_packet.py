def mac_to_bytes(mac_address):
    """
    Converts MAC address string into bytes.
    Example: 'AA:BB:CC:DD:EE:FF'
    """
    return bytes(int(part, 16) for part in mac_address.split(":"))


def ip_to_bytes(ip_address):
    """
    Converts IPv4 address string into bytes.
    Example: '192.168.1.10'
    """
    return bytes(int(part) for part in ip_address.split("."))


def ipv4_checksum(header):
    """
    Computes IPv4 header checksum.
    UDP checksum is left as zero for now, which is allowed for IPv4 UDP.
    """
    if len(header) % 2 != 0:
        header += b"\x00"

    total = 0

    for i in range(0, len(header), 2):
        word = (header[i] << 8) + header[i + 1]
        total += word

        # Fold carry bits back into 16 bits
        total = (total & 0xFFFF) + (total >> 16)

    checksum = ~total & 0xFFFF
    return checksum.to_bytes(2, byteorder="big")


def build_udp_packet():
    # Ethernet fields
    dest_mac = mac_to_bytes("AA:BB:CC:DD:EE:FF")
    src_mac = mac_to_bytes("11:22:33:44:55:66")
    ethertype = bytes.fromhex("0800")  # IPv4

    ethernet_header = dest_mac + src_mac + ethertype

    # Payload
    payload = b"HELLO_FPGA"

    # IPv4 fields
    version_ihl = bytes([0x45])  # Version = 4, IHL = 5
    dscp_ecn = bytes([0x00])
    total_length = (20 + 8 + len(payload)).to_bytes(2, byteorder="big")
    identification = bytes.fromhex("0001")
    flags_fragment = bytes.fromhex("4000")  # Don't Fragment flag
    ttl = bytes([64])
    protocol = bytes([17])  # UDP
    header_checksum = bytes.fromhex("0000")  # Temporary before checksum
    src_ip = ip_to_bytes("192.168.1.10")
    dst_ip = ip_to_bytes("192.168.1.20")

    ipv4_header_without_checksum = (
        version_ihl
        + dscp_ecn
        + total_length
        + identification
        + flags_fragment
        + ttl
        + protocol
        + header_checksum
        + src_ip
        + dst_ip
    )

    checksum = ipv4_checksum(ipv4_header_without_checksum)

    ipv4_header = (
        version_ihl
        + dscp_ecn
        + total_length
        + identification
        + flags_fragment
        + ttl
        + protocol
        + checksum
        + src_ip
        + dst_ip
    )

    # UDP fields
    src_port = (5000).to_bytes(2, byteorder="big")
    dst_port = (6000).to_bytes(2, byteorder="big")
    udp_length = (8 + len(payload)).to_bytes(2, byteorder="big")
    udp_checksum = bytes.fromhex("0000")

    udp_header = src_port + dst_port + udp_length + udp_checksum

    packet = ethernet_header + ipv4_header + udp_header + payload
    return packet


def print_packet_info(packet):
    print("Generated Ethernet/IPv4/UDP Packet")
    print("-----------------------------------")
    print(f"Packet length: {len(packet)} bytes")
    print()
    print("Packet bytes in hex:")
    print(packet.hex(" "))
    print()

    print("Important byte ranges:")
    print("Ethernet Header: bytes 0-13")
    print("IPv4 Header:     bytes 14-33")
    print("UDP Header:      bytes 34-41")
    print("Payload:         bytes 42+")


if __name__ == "__main__":
    packet = build_udp_packet()
    print_packet_info(packet)