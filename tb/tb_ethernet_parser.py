"""Reference checks for Ethernet fields in generated RTL stimulus."""
import unittest
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).parents[1] / "scripts"))
from generate_market_packet import build_market_packet

class EthernetStimulusTest(unittest.TestCase):
    def test_ethernet_header(self):
        frame = build_market_packet()
        self.assertEqual(frame[0:6], bytes.fromhex("AA BB CC DD EE FF"))
        self.assertEqual(frame[6:12], bytes.fromhex("11 22 33 44 55 66"))
        self.assertEqual(frame[12:14], b"\x08\x00")

if __name__ == "__main__": unittest.main()
