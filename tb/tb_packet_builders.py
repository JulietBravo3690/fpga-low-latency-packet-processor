"""Reference checks for generic UDP, TCP, and negative frame builders."""
import sys
import unittest
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parents[1] / "scripts"))
from packet_builders import (build_malformed_frame, build_non_ipv4_frame,
                             build_tcp_frame, build_udp_frame)

class PacketBuilderTest(unittest.TestCase):
    def test_generic_udp(self):
        frame = build_udp_frame(b"abc", src_port=1234, dst_port=4321)
        self.assertEqual(frame[23], 17)
        self.assertEqual(int.from_bytes(frame[34:36], "big"), 1234)
        self.assertEqual(int.from_bytes(frame[36:38], "big"), 4321)
        self.assertEqual(int.from_bytes(frame[38:40], "big"), 11)
        self.assertEqual(frame[42:], b"abc")

    def test_tcp(self):
        frame = build_tcp_frame(dst_port=443, flags=0x12)
        self.assertEqual(len(frame), 54)
        self.assertEqual(frame[23], 6)
        self.assertEqual(int.from_bytes(frame[36:38], "big"), 443)
        self.assertEqual(frame[46] >> 4, 5)
        self.assertEqual(frame[47], 0x12)

    def test_negative_frames(self):
        self.assertEqual(build_non_ipv4_frame()[12:14], b"\x08\x06")
        self.assertLess(len(build_malformed_frame()), 14)

if __name__ == "__main__":
    unittest.main()
