# Architecture-A Gate-2 closure

Status: **PASS**

Closing known-good commit: `cbb801aaf87870cb6f7aaa938f3d364e5b16d472`.
Annotated tag `kg-g2-a-functional`: object
`15190879d68fb7f94f425556d60a20609f818c79`, dereferenced commit
`cbb801aaf87870cb6f7aaa938f3d364e5b16d472`.

The complete documented AXI4-subset Architecture-A production top is covered by deterministic hand-written and independent project-owned oracle evidence.

- Whole-top directed regression: 348 checks PASS.
- Python oracle self-tests: 15 PASS.
- Public-port DUT oracle: PASS for S0/S1 independent memory/WSTRB, verification-only S2, S3 DECERR, LEN 0..15, 4-write/4-read capacity, fifth-request blocking and following-cycle recovery, same visible read IDs across M0/M1/M2, distinct-ID out-of-order B/R, deterministic target and manager backpressure, and live-work reset with fresh same-ID reuse.
- Expected-fail `bad_rdata` corruption run fails for the specific oracle mismatch and is accepted as sensitivity evidence.
- Existing full-Fabric synthesis reference: 5,046 LUT4, 1,219 TRELLIS_FF, 288 CCU2C, 807 PFUMX and 270 L6MUX21.

The production response-source limitation remains: B/R routers validate manager prefix and busy ID, and R validates its active lock/RID, but returned source target is not compared against admission metadata. Coordinated reset is part of the supported environment; rogue stale subordinate responses are outside MVP.

Gate 2 does not claim full AXI4 compliance, deep randomized verification, whole-Fabric formal proof, timing closure, Fmax, P99 latency, throughput or PPA characterization.
