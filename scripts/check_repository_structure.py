#!/usr/bin/env python3
"""Reject common conflict-resolution artifacts before RTL compilation."""

from collections import Counter
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
TEXT_SUFFIXES = {".md", ".py", ".sv", ".yml", ".yaml"}
MERGE_MARKERS = ("<<<<<<<", "=======", ">>>>>>>")
TARGET_PATTERN = re.compile(r"^([A-Za-z0-9_.%/-]+)\s*:(?!=)")
MODULE_PATTERN = re.compile(r"^\s*module\s+([A-Za-z_][A-Za-z0-9_$]*)\b", re.MULTILINE)


def fail(message: str) -> None:
    print(f"STRUCTURE CHECK FAILED: {message}", file=sys.stderr)
    raise SystemExit(1)


def checked_text_files():
    for path in ROOT.rglob("*"):
        if not path.is_file() or ".git" in path.parts:
            continue
        if "sim" in path.parts or "build" in path.parts:
            continue
        if path.suffix in TEXT_SUFFIXES or path.name in {"Makefile", ".gitignore"}:
            yield path


def check_merge_markers() -> None:
    for path in checked_text_files():
        for line_number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if line.startswith(MERGE_MARKERS):
                fail(f"merge marker in {path.relative_to(ROOT)}:{line_number}")


def check_make_targets() -> None:
    targets = []
    for line in (ROOT / "Makefile").read_text(encoding="utf-8").splitlines():
        match = TARGET_PATTERN.match(line)
        if match and not line.startswith(("\t", " ")):
            targets.append(match.group(1))
    duplicates = sorted(name for name, count in Counter(targets).items() if count > 1)
    if duplicates:
        fail("duplicate Make targets: " + ", ".join(duplicates))


def check_systemverilog_modules() -> None:
    definitions = []
    for directory in ("rtl", "tb"):
        for path in sorted((ROOT / directory).glob("*.sv")):
            text = path.read_text(encoding="utf-8")
            modules = MODULE_PATTERN.findall(text)
            endmodule_count = len(re.findall(r"^\s*endmodule\b", text,
                                             re.MULTILINE))
            if len(modules) != endmodule_count:
                fail(f"module/endmodule count mismatch in {path.relative_to(ROOT)}")
            definitions.extend((module, path) for module in modules)
    duplicate_modules = sorted(name for name, count in Counter(name for name, _ in definitions).items()
                               if count > 1)
    if duplicate_modules:
        fail("duplicate SystemVerilog modules: " + ", ".join(duplicate_modules))


def check_market_decoder_shape() -> None:
    text = (ROOT / "rtl" / "market_data_decoder.sv").read_text(encoding="utf-8")
    if len(re.findall(r"\balways_ff\b", text)) != 1:
        fail("market_data_decoder must contain exactly one always_ff block")
    if text.count("udp_length != REQUIRED_UDP_LENGTH") != 1:
        fail("market_data_decoder must contain one exact UDP-length check")
    if "udp_length < REQUIRED_UDP_LENGTH" in text:
        fail("stale minimum-length decoder condition found")


def main() -> None:
    check_merge_markers()
    check_make_targets()
    check_systemverilog_modules()
    check_market_decoder_shape()
    print("Repository structure check PASSED")


if __name__ == "__main__":
    main()
