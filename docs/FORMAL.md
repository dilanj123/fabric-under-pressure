# Formal Strategy

**Status:** Gate-1 formal contract frozen; Phase-0 generic formal harness passed, but no project AXI property has run.

## Scope order
Prove tractable primitives first. Do not begin with whole-fabric exhaustive proof.

## Candidate properties
- arbiter: one-hot grant, grant implies request, held grant stability, no illegal simultaneous ownership;
- RR fairness under explicit recurring-service assumptions;
- QoS/age: age saturation correctness, starvation-escape membership, no bypass by non-starved traffic once eligible, RR service within starved set under assumptions;
- decoder: at most one legal target; unmapped -> S3;
- channel buffers: stalled payload stable, token conservation, no overwrite;
- write route tracker: every accepted W burst follows registered accepted-AW context;
- read response: response maps to a manager with matching valid outstanding context;
- counters: no underflow; never exceed configured capacity.

## Liveness discipline
All bounded-service claims must list environmental readiness assumptions. Add covers/non-vacuity checks so a proof cannot pass merely because requests or service opportunities never occur.

For scheduler fairness, assumptions are limited to a continuously legal pending request and recurring downstream service opportunities for the selected target and direction. A request being blocked by target backpressure does not count as a lost scheduler opportunity. The age threshold is therefore measured in eligible arbitration opportunities, and the proof must cover an escape decision with at least two competing requesters. No property assumes that a subordinate is always ready unless that assumption is stated in the property harness.

## Evidence language
A formal PASS applies only to the named property, assumptions, engine, depth/mode and exact commit. It is not a whole-fabric correctness or compliance claim.
