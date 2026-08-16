"""Packet-stream stimulus checks used alongside the RTL testbench."""
import unittest
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).parents[1] / "scripts"))
from generate_market_packet import build_market_packet

class PacketStreamStimulusTest(unittest.TestCase):
    def test_frame_has_unambiguous_boundaries(self):
        frame = build_market_packet()
        stream = [(byte, index == 0, index == len(frame) - 1)
                  for index, byte in enumerate(frame)]
        self.assertEqual(sum(sop for _, sop, _ in stream), 1)
        self.assertEqual(sum(eop for _, _, eop in stream), 1)
        self.assertEqual(len(stream), 59)

if __name__ == "__main__": unittest.main()
