# Gate-2 independent Python oracle evidence

Status: **PARTIAL — Gate 2 remains open**

The project-owned reference model and DUT-facing cocotb run pass for the
currently implemented scope. The run is intentionally not treated as Gate-2
closure evidence because the complete requested oracle matrix is not yet
implemented.

## Passing evidence

- Pure Python detector/self tests: 15 tests pass in
  `tb/model/test_axi_reference_model.py`.
- DUT-facing Verilator/cocotb test: 1 test passes against `axi_fabric_a`.
- S3 legal write/read transport: DECERR, widened-ID restoration, zero read
  data and one-beat completion.
- S0/S1 mapped memory phase: all LEN values 0 through 15, independent
  byte-addressed endpoint memory, full and partial WSTRB patterns, target AW/
  AR/W ID and payload checks, B/R response checks and readback against a
  separately maintained reference memory.
- S2 verification-only endpoint phase: one legal multi-beat write and read
  route through S2 with OKAY responses, exact beat/LAST behavior and widened
  ID restoration. Reads use deterministic zero data; this is testbench
  endpoint behavior, not architectural S2 storage semantics.
- Three-manager same-visible-ID write overlap: widened AWID disambiguation,
  target W routing and manager BID restoration for M0/M1/M2.
- Manager-W expectations are recorded at manager handshakes and compared at
  target delivery; target-address observations validate admitted transaction,
  address, complete AW/AR carried payload and widened ID.
- The independent endpoint memory implementation is used by the DUT-facing
  test and its initialization agrees with the reference memory at sampled
  addresses.
- The normal run has monotonic multi-cycle JSONL trace data. A deliberate
  `ORACLE_FAULT_MODE=bad_rdata` run fails with `bad RDATA`, and the closure
  driver records that expected failure as sensitivity PASS.
- The model rejects premature B before any or all expected W beats and owns
  R beat indexing internally rather than trusting the caller.
- Reference-model trace: `results/raw/gate2_oracle/event_trace.jsonl`.

## Detector non-vacuity

The pure model self-tests deliberately reject loss, duplication, misrouting,
bad IDs, bad data, bad WSTRB, bad RESP, bad LAST, R-source interleaving and a
stale reset epoch. The corruption-sensitivity test injects incorrect read
data and requires an `OracleViolation`.

## Remaining closure gaps

The current DUT-facing oracle still needs explicit independent end-to-end
scenarios for whole-top reset with outstanding work, target and
manager backpressure in the oracle run, four outstanding IDs, read-side
same-visible-ID overlap and distinct-ID out-of-order completion. The existing
348-check hand-written directed regression covers several of these, but it
does not substitute for the independent oracle.

Existing full-Fabric synthesis remains historical evidence; this task made no
RTL changes and makes no new PPA, timing or performance claim. The known
recorded-target versus returned-target validation limitation remains.
