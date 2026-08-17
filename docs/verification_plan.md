# Verification Plan

## Automated Coverage

`make test-all` runs self-checking SystemVerilog tests for stream framing, every parser, classification, statistics, latency tracking, market decoding, and the integrated top level. It also runs standard-library Python tests that validate generated packet vectors at each protocol boundary. GitHub Actions runs `make clean` followed by this suite on every push and pull request.

The top-level test loads the hex file emitted by
`generate_market_packet.py`. It proves that the same 59-byte reference frame is
parsed with IPv4/UDP lengths 45/25, classified and allowed as market data,
decoded to the expected fields, counted as 45 IPv4 bytes, and observed at every
latency milestone in monotonic order.

Covered negative cases include missing packet boundaries, short headers,
unsupported EtherType or IP layouts, non-UDP input, counter clearing, early
market payload EOP, and short or overlong market UDP declarations. The decoder
also runs with continuous bytes and idle cycles between bytes and checks that
`message_valid` is a one-cycle pulse.

## Remaining Verification Work

The suite is directed rather than constrained-random. Future work includes assertions, functional coverage, randomized gaps and malformed frames, synthesis lint, formal parser properties, and post-place-and-route timing validation.
