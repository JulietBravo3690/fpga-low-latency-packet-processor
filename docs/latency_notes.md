# Latency Instrumentation

## Cycle Convention

`latency_tracker` accepts SOP when the ingress handshake presents `sop_event`
on a rising clock edge. That edge is **cycle 0**. A milestone on the SOP edge records 0; a milestone on
the immediately following rising edge records 1. Thus a stored value `N` is the
number of rising-edge intervals from the accepted SOP edge to the milestone
edge, not nanoseconds and not combinational delay.

The counter increments every clock while a measurement is active, including
cycles where stream `valid` is low. It saturates at its all-ones value and sets
a sticky-per-measurement overflow flag rather than wrapping. A statistics event
captures the final value and ends the measurement. A new SOP restarts at zero,
clears overflow, and supersedes any incomplete prior measurement. Same-edge
milestones on that new SOP are associated with the new transaction.

The statistics milestone is the edge on which `traffic_stats` samples the
classifier event. Classification and statistics latency may therefore be equal
in the current registered integration.

## Verification and Limits

The standalone test covers cycle 0, the first post-SOP cycle, ordered events,
saturation, overflow, completion, and restart. Integrated tests check every
milestone and monotonic ordering for the reference packet.

The measurements stop at the classification/statistics milestone and exclude
store-and-forward egress drain time. These are cycle-level RTL observations.
No device clock, nanosecond latency, maximum frequency, throughput, timing
closure, or hardware measurement is claimed.
