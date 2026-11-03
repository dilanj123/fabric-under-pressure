# Formal Strategy

**Status:** Gate-1 formal contract frozen; targeted project primitive formal jobs have rerun successfully. Evidence remains bounded and property-scoped; no whole-fabric exhaustive proof is claimed.

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
- write owner: registered accepted-AW context remains stable through W completion; beat counts stay in range; correct WLAST releases ownership; malformed W events are diagnosed without counter underflow; same-cycle final-W/AW recycling is blocked.

## Liveness discipline
All bounded-service claims must list environmental readiness assumptions. Add covers/non-vacuity checks so a proof cannot pass merely because requests or service opportunities never occur.

For scheduler fairness, assumptions are limited to a continuously legal pending request and recurring downstream service opportunities for the selected target and direction. A request being blocked by target backpressure does not count as a lost scheduler opportunity. The age threshold is measured in pending clock cycles; recurring service opportunities condition the later bounded-service guarantee. The proof must cover an escape decision with at least two competing requesters. No property assumes that a subordinate is always ready unless that assumption is stated in the property harness.

## Evidence language
A formal PASS applies only to the named property, assumptions, engine, depth/mode and exact commit. It is not a whole-fabric correctness or compliance claim.

## Executed standalone evidence

The per-manager write-owner primitive is checked by `formal/axi_write_owner_formal.sv` using Yices through SBY: prove is bounded BMC to depth 12 and cover is bounded to depth 16. Legal allocation traces assume `allocate_len <= 15`; malformed W events remain unconstrained for diagnostic properties. This is primitive evidence only, not AXI channel or integrated-Fabric proof.


## Architecture-B QoS/aging arbiter

`formal/axi_qos_aging_arbiter_3_formal.sv` checks the three-requester scheduler's one-hot candidate/grant, maximum-QoS selection, RR tie choice, escape-set membership, transition equations for age reset/increment/saturation, pointer update only on accepted admission, held-grant stability and reset state. `formal/axi_qos_aging_arbiter_3.sby` runs Yices BMC prove to depth 20 and cover to depth 80. The cover traces reach age 63, age 64 with a competing fresh QoS request, and a multi-request starved-set selection (cover steps 64/65).

Assumptions: reset is asserted initially; `eligible` is a subset of `legal_pending`; `accept` is a real accepted selected eligible grant; and an AXI-compliant manager keeps a selected legal request asserted until admission. No downstream-ready assumption is needed for the age counter because age is pending-clock based. This proves only the arbiter's bounded transition/policy properties; the B whole-DUT evidence is directed/random simulation, not formal proof of the fabric. Raw logs and traces are under `results/raw/architecture_b_scheduler/formal_*`.
