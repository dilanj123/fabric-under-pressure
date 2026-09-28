# Architecture-A Gate-2 directed integration regression

Status: PASS for the implemented expanded smoke; full requested Gate-2 closure matrix remains open.

Command: `scripts/run_fabric_a_gate2_directed.sh`

Checks: 296 self-checking simulation checks, including the retained 260-check route/payload smoke.

Coverage added beyond the route smoke:

- AW-before-W, W-before-AW and same-cycle AW/W timing;
- four shared outstanding write entries, fifth-write blocking and following-cycle capacity return;
- four shared outstanding read entries, fifth-read blocking and following-cycle capacity return;
- unsupported burst/alignment/size request rejection;
- registered AW and AR target-slot backpressure stability;
- manager B and R backpressure stability;
- same-target AW contention and parallel AW progress to S0/S1/S2;
- one-hot target contribution assertions and exact manager-facing admission aggregation;
- retained all-manager/all-target mapped and S3 route coverage, including 16-beat examples.

The test uses verification-only procedural responders for S0-S2 and the real internal S3 endpoint. It is directed integration evidence, not an independent oracle, random stress test, deep formal proof or performance result. Recorded-target versus returned-target response-source matching remains unproven.

Not yet covered by this expanded testbench at whole-top scope: multi-manager same-visible-ID return checks, distinct-ID out-of-order completion, locked-R source-gap switching, target-W stall points, and reset with each partially accepted state. Existing focused primitive evidence covers several of those behaviors, but it does not substitute for whole-top closure evidence.
