"""Reference checks for UDP fields in generated stimulus."""
import unittest
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).parents[1] / "scripts"))
from generate_market_packet import build_market_packet

class UDPStimulusTest(unittest.TestCase):
    def test_udp_header(self):
        header = build_market_packet()[34:42]
        self.assertEqual(int.from_bytes(header[0:2]), 5000)
        self.assertEqual(int.from_bytes(header[2:4]), 6000)
        self.assertEqual(int.from_bytes(header[4:6]), 25)
        self.assertEqual(header[6:8], b"\x00\x00")

if __name__ == "__main__": unittest.main()
