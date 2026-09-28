# Gate-2 independent Python oracle

Status: **PASS**

The project-owned reference model and public-port Verilator/cocotb run pass the complete deterministic matrix. Production RTL was unchanged.

## Evidence

- 15 pure-Python self-tests pass, covering loss, duplication, address/W misrouting, target/returned IDs, carried payload, premature B, bad data, WSTRB, RESP, LAST, R-source interleaving, stale epoch, unsupported LOCK and byte preservation.
- The normal DUT-facing run passes the original S0/S1 memory and WSTRB readback, S2 verification endpoint, S3 DECERR, all LEN 0..15, full AW/AR payloads, manager-W versus target-W comparison and widened-ID restoration.
- The closure matrix passes four live writes and four live reads with fifth request blocking and following-cycle recovery, same visible read ID 5 on M0/M1/M2, distinct-ID out-of-order B and R, target AW/AR/W backpressure, manager B/R backpressure, and live-work reset with fresh same-ID reuse.
- JSONL traces are cycle/epoch traced and monotonic. The normal event trace is `results/raw/gate2_oracle/event_trace.jsonl`; closure scenarios are in `results/raw/gate2_oracle/closure_event_trace.jsonl`.
- `ORACLE_FAULT_MODE=bad_rdata` fails for the specific `bad RDATA` mismatch; the closure driver records this as expected-fail sensitivity PASS.

S2 data behavior is verification-only endpoint semantics: legal writes are consumed and return OKAY, and reads return deterministic OKAY data with exact beat/LAST behavior. It is not an architectural S2 register-map claim.

The known limitation remains that production B/R routers do not compare the returned source target with target metadata recorded at admission. Coordinated reset is assumed; an independently reset subordinate emitting an indistinguishable stale response remains outside the MVP contract.

Existing full-Fabric ECP5 synthesis remains historical SYNTH evidence: 5,046 LUT4, 1,219 TRELLIS_FF, 288 CCU2C, 807 PFUMX and 270 L6MUX21. No new timing, PPA, performance or deep-verification claim is made.
