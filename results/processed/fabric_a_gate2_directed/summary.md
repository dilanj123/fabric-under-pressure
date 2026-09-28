# Architecture-A Gate-2 directed integration regression

Status: PASS

Command: `scripts/run_fabric_a_gate2_directed.sh`

Checks: 348 self-checking simulation checks, including the retained 260-check route/payload smoke.

Coverage added beyond the route smoke:

- AW-before-W, W-before-AW and same-cycle AW/W timing;
- four shared outstanding write entries, fifth-write blocking and following-cycle capacity return;
- four shared outstanding read entries, fifth-read blocking and following-cycle capacity return;
- unsupported burst/alignment/size request rejection;
- registered AW and AR target-slot backpressure stability;
- manager B and R backpressure stability;
- same-target AW contention and parallel AW progress to S0/S1/S2;
- same visible ID `5` across M0/M1/M2 in both write and read directions, including widened internal IDs and manager-side restoration;
- distinct-ID out-of-order B and R completion;
- locked S0 R-source gap with S1 response pending and blocked until the S0 burst reaches accepted RLAST;
- first, middle and final target-W stalls with payload/owner stability;
- reset abandonment of stalled AW/AR slots followed by fresh post-reset write/read recovery;
- one-hot target contribution assertions and exact manager-facing admission aggregation;
- retained all-manager/all-target mapped and S3 route coverage, including 16-beat examples.

The test uses verification-only procedural responders for S0-S2 and the real internal S3 endpoint. It is directed integration evidence, not an independent oracle, random stress test, deep formal proof or performance result. Recorded-target versus returned-target response-source matching remains unproven.
