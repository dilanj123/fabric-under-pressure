# P2 assurance validation

## Comparator and PPA parser

Under the qualified OSS CAD Suite 20260920 environment:

```sh
PYTHONPATH=bench:tb/cocotb:. python3 -m unittest \
  bench.test_benchmark_driver bench.test_benchmark_plan \
  bench.test_compare_ab bench.test_summarize_ppa -v
python3 -m unittest discover -s tb/model -p 'test*.py' -v
```

Result: 28 Python tests passed (3 benchmark-driver, 4 plan, 13 comparator, 8 PPA parser); 15 independent reference-model tests passed. The fixtures include complete accepted frozen inputs and negative cases for incomplete/duplicate matrices, mismatched path/metadata/config/summary, wrong DUT selection, wrong frozen workload hash, duplicate or boolean manager IDs, missing direction samples, unequal A/B intent hashes, mismatched shared generator identity, missing/malformed Yosys resources, wrong hierarchy/top and synthesis failure.

The frozen A/B datasets were reprocessed to `results/raw/portfolio_audit_p2/compare_final/`; PPA copies were parsed under `results/raw/portfolio_audit_p2/ppa_A/` and `ppa_B/`. No authoritative processed result was overwritten.

| Reprocessed output | Rows / result | Comparison with committed processed output |
|---|---:|---|
| Matched per-seed metrics | 5,890 | Equal within 1e-12 |
| Median-of-five metrics | 1,178 | Equal within 1e-12 |
| Aggregate throughput per seed | 155 | Equal within 1e-12 |
| Median aggregate throughput | 31 | Equal within 1e-12 |
| D045 evaluation | 5 criteria | JSON identical; same PASS/FAIL outcomes |
| A/B source-manifest comparison | 70 pairs | JSON identical |
| PPA route attempts | 55 per architecture | Seed, frequency, timing status and achieved MHz identical |

Direct and wrapped resource totals match the committed PPA comparison for both architectures. All-seed timing-clean target remains 60 MHz for A and 55 MHz for B. The parser reports omitted optional cell classes as zero only after recognizing the expected report structure. The frozen workload hash remains `31c599caa7344c938b588a0f22404cfcfe5fe53b3ef5fae40a568130cfadfca4`.

## Oracle handshake-correlation diagnostic

A temporary edge snapshot under the qualified Verilator 5.053/Cocotb 2.1.0 simulator captured the Gate-2 M0/S1/ID 11 LEN=3 case. The testcase XML reports 2 PASS, 0 FAIL, 0 SKIP, but the sampled public signals recorded six target and six manager R handshakes; the oracle trace recorded four R updates. Beats 1 and 2 were each accepted twice with identical payload on successive active edges. This demonstrates that the existing helper/oracle progression does not account for every sampled handshake in this scenario. It does not demonstrate a DUT defect.

Compact evidence: `results/raw/portfolio_audit_p2/oracle_edge_correlation_summary.json` and `oracle_edge_correlation_window.jsonl`. The full temporary simulator trace/build and instrumented test copy remain local under `results/raw/portfolio_audit_p2/oracle_diag/`; the checked-in oracle source is unchanged. The focused repair and required Gate-2/A/B functional requalification are a separate follow-up, documented in `oracle_edge_correlation_followup.md`.
