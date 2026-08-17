"""End-to-end reference-vector checks for the integrated RTL test stimulus."""
import struct
import subprocess
import tempfile
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

    def test_cli_hex_matches_packet_builder(self):
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "market.hex"
            subprocess.run([
                sys.executable,
                str(Path(__file__).parents[1] / "scripts" / "generate_market_packet.py"),
                "--symbol", "AAPL", "--price", "18525", "--quantity", "100",
                "--sequence", "42", "--hex-output", str(output)
            ], check=True, capture_output=True, text=True)
            emitted = bytes(int(line, 16) for line in output.read_text().splitlines())
            self.assertEqual(emitted, build_market_packet(sequence_number=42))
            self.assertEqual(len(emitted), 59)

    def test_cli_binary_and_sv_outputs(self):
        expected = build_market_packet(sequence_number=42)
        script = str(Path(__file__).parents[1] / "scripts" /
                     "generate_market_packet.py")
        common = ["--symbol", "AAPL", "--price", "18525", "--quantity",
                  "100", "--sequence", "42"]
        with tempfile.TemporaryDirectory() as directory:
            output = Path(directory) / "market.bin"
            subprocess.run([sys.executable, script, *common, "--output",
                            str(output)], check=True, capture_output=True,
                           text=True)
            self.assertEqual(output.read_bytes(), expected)

        result = subprocess.run([sys.executable, script, *common, "--sv-array"],
                                check=True, capture_output=True, text=True)
        self.assertTrue(result.stdout.startswith("'{8'hAA, 8'hBB"))
        self.assertEqual(result.stdout.count("8'h"), 59)

    def test_invalid_symbol_is_rejected(self):
        with self.assertRaises(ValueError):
            build_market_payload(symbol="TOO_LONG")

if __name__ == "__main__": unittest.main()
