# Follow-up: Gate-2 oracle edge correlation

## Finding

A qualified Verilator/Cocotb run exposed a real testbench correlation gap in the M0/S1 four-beat R response used by `fabric_a_oracle_closure_matrix`. The test completed two Cocotb testcases successfully, but a temporary active-edge snapshot counted six target-side and six manager-side `RVALID && RREADY` handshakes for M0/ID 0xB, where the helper intended four beats. The independent oracle recorded four R beat updates. Target R beats 1 and 2 were each accepted on two successive sampled edges with identical payload, and the manager accepted each twice; the current coroutine loop advanced its expected beat once.

The captured events are in [`oracle_edge_correlation_summary.json`](../results/raw/portfolio_audit_p2/oracle_edge_correlation_summary.json) and [`oracle_edge_correlation_window.jsonl`](../results/raw/portfolio_audit_p2/oracle_edge_correlation_window.jsonl). The complete temporary trace and simulator build are retained locally under `results/raw/portfolio_audit_p2/oracle_diag/`; the diagnostic used an instrumented copy of the test and restored the repository source unchanged.

## Classification and scope

This is a verification-driver/edge-correlation defect candidate, not evidence of a production RTL defect. The target response helper in `tb/cocotb/test_axi_fabric_a_oracle.py` changes target RVALID immediately after `await cycles()` at the rising edge. The edge capture shows the same driven beat accepted again on the next edge. The current oracle loop updates once per intended beat rather than from a sampled handshake event set, so it can miss these extra accepted beats.

No RTL, formal assumptions, workload, benchmark, endpoint model or frozen A/B result was changed in the assurance-guard work. Gate-2 R-path confidence for this helper scenario remains OPEN until the separate correction and reruns are complete.

## Smallest corrective task

1. Drive each target R beat in a phase that is safely before its accepting rising edge, and hold it until a monitor observes exactly one sampled target `RVALID && RREADY`.
2. Record manager R payload and `RVALID && RREADY` on every active edge; update the oracle exactly once for each sampled manager beat.
3. Add a focused LEN=3 regression that asserts exactly four target and four manager handshakes, including a check that each beat payload advances once and RLAST appears only on beat 3.
4. Run the Gate-2 oracle closure, its deliberate bad-RDATA sensitivity test, focused R-retention, and Architecture-A/B functional suites affected by the helper. Preserve old results as historical and qualify any claim that changes.

Do not alter Architecture A/B RTL, D045/D047 or canonical benchmark results as part of that follow-up.

## Repair and requalification (2026-11-08)

The focused repair is complete. The R driver now holds each beat through its sampled target handshake, separately counts target and manager transfers, and updates the oracle from accepted manager R beats. The LEN=3 M0/S1/ID11 regression passes both without stalls and with manager backpressure at exactly 4 target / 4 manager / 4 oracle events. A short post-completion window detects any extra transfer. Six controlled faults are rejected by their intended checks, and the existing bad-RDATA fault mode remains sensitive.

The edge diagnostic found the pre-edge sample and immediate `RisingEdge` callback identical for the qualified Verilator/Cocotb configuration; `ReadOnly` may show post-edge registered values. A related AR-capacity assertion was corrected to count the fifth request on its real handshake instead of inspecting READY after state update. The full affected Gate-2, directed and A/B functional requalification is recorded in [`results/processed/oracle_edge_repair/summary.md`](../results/processed/oracle_edge_repair/summary.md). No production RTL or frozen benchmark source/result changed. This resolves the original correlation finding for the repaired R driver and exercised cases; it does not claim that every older coroutine helper has been converted to a central monitor.
