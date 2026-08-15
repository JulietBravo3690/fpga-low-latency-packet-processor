# Latency Instrumentation

`latency_tracker` starts at zero when `valid_in && sop_in` is sampled. On each later active clock it increments a saturating 16-bit counter and captures the count when Ethernet, IPv4, UDP, classification, and statistics event pulses occur. Each capture has a corresponding one-cycle valid pulse.

The statistics capture uses the classifier event that the statistics engine samples; it identifies the statistics update edge. The tracker completes on that event. A new start-of-packet restarts the measurement, so the current architecture assumes packets are not interleaved.

These counters enable cycle-accurate observation in a chosen simulation or synthesized build. The repository does not state nanosecond latency, maximum frequency, throughput, or timing closure because no device-specific implementation report is included.
