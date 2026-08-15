"""Reference checks for IPv4 fields and checksum in generated stimulus."""
import unittest
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).parents[1] / "scripts"))
from generate_market_packet import build_market_packet, ipv4_checksum

class IPv4StimulusTest(unittest.TestCase):
    def test_ipv4_header(self):
        header = build_market_packet()[14:34]
        self.assertEqual(header[0], 0x45)
        self.assertEqual(int.from_bytes(header[2:4]), 45)
        self.assertEqual(header[9], 17)
        self.assertEqual(ipv4_checksum(header), 0)
        self.assertEqual(header[12:16], bytes([192, 168, 1, 10]))

if __name__ == "__main__": unittest.main()
