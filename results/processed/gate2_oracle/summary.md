# Gate-2 independent Python oracle evidence

Status: **PARTIAL — Gate 2 remains open**

The project-owned reference model and DUT-facing cocotb run pass for the
currently implemented scope. The run is intentionally not treated as Gate-2
closure evidence because the complete requested oracle matrix is not yet
implemented.

## Passing evidence

- Pure Python detector/self tests: 8 tests pass in
  `tb/model/test_axi_reference_model.py`.
- DUT-facing Verilator/cocotb test: 1 test passes against `axi_fabric_a`.
- S3 legal write/read transport: DECERR, widened-ID restoration, zero read
  data and one-beat completion.
- S0/S1 mapped memory phase: all LEN values 0 through 15, independent
  byte-addressed endpoint memory, full and partial WSTRB patterns, target AW/
  AR/W ID and payload checks, B/R response checks and readback against a
  separately maintained reference memory.
- Three-manager same-visible-ID write overlap: widened AWID disambiguation,
  target W routing and manager BID restoration for M0/M1/M2.
- Reference-model trace: `results/raw/gate2_oracle/event_trace.jsonl`.

## Detector non-vacuity

The pure model self-tests deliberately reject loss, duplication, misrouting,
bad IDs, bad data, bad WSTRB, bad RESP, bad LAST, R-source interleaving and a
stale reset epoch. The corruption-sensitivity test injects incorrect read
data and requires an `OracleViolation`.

## Remaining closure gaps

The current DUT-facing oracle still needs explicit independent end-to-end
scenarios for S2 behavior, whole-top reset with outstanding work, target and
manager backpressure in the oracle run, four outstanding IDs, read-side
same-visible-ID overlap, distinct-ID out-of-order completion, and a separate
expected-fail DUT-facing corruption experiment. The existing 348-check
hand-written directed regression covers several of these, but it does not
substitute for the independent oracle.

Existing full-Fabric synthesis remains historical evidence; this task made no
RTL changes and makes no new PPA, timing or performance claim. The known
recorded-target versus returned-target validation limitation remains.
