# Verification Plan

## Automated Coverage

`make test-all` runs self-checking SystemVerilog tests for stream framing, every parser, classification, statistics, latency tracking, market decoding, and the integrated top level. It also runs standard-library Python tests that validate generated packet vectors at each protocol boundary.

Covered negative cases include missing packet boundaries, short headers, unsupported EtherType or IP layouts, non-UDP input, counter clearing, and a too-short market payload declaration. The market decoder test checks every decoded field. The latency test checks milestone capture and completion behavior.

## Remaining Verification Work

The suite is directed rather than constrained-random. Future work includes assertions, functional coverage, randomized gaps and malformed frames, synthesis lint, formal parser properties, and post-place-and-route timing validation.
