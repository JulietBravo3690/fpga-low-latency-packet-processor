"""End-to-end reference-vector checks for the integrated RTL test stimulus."""
import struct
import unittest
from pathlib import Path
import sys
sys.path.insert(0, str(Path(__file__).parents[1] / "scripts"))
from generate_market_packet import (MARKET_PAYLOAD_FORMAT, build_market_packet,
                                    build_market_payload)

class TopLevelStimulusTest(unittest.TestCase):
    def test_market_payload_round_trip(self):
        frame = build_market_packet(message_type=2, symbol="MSFT", price=41750,
                                    quantity=250, sequence_number=99)
        self.assertEqual(struct.unpack(MARKET_PAYLOAD_FORMAT, frame[42:]),
                         (2, b"MSFT", 41750, 250, 99))

    def test_invalid_symbol_is_rejected(self):
        with self.assertRaises(ValueError):
            build_market_payload(symbol="TOO_LONG")

if __name__ == "__main__": unittest.main()
