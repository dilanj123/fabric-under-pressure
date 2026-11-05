# Gate-5 clean-clone reproduction

**Decision: PASS (same qualified host; not independent-hardware validation).** The public repository reproduced the published A/B simulation, D045 and PPA results from a fresh clone at the reviewed comparison commit. No RTL, workload, endpoint, metric or sampling-policy changes were made.

## Clone and environment

- Public source: `https://github.com/dilanj123/fabric-under-pressure.git`
- Fresh checkout: `/tmp/fabric-under-pressure-g5-reproduction`
- Source commit: `3f70eb616fddcd2fcb48a96b340f61f4baba2c85`; detached HEAD; initial `git status --short` was empty. `kg-g4-ab-measured^{commit}` resolved to the same SHA.
- Host: Apple Silicon arm64, macOS 26.4.1, Darwin 25.4.0.
- Shared qualified tools: `/Users/Dilan/eda/fabric-under-pressure/oss-cad-suite`, Verilator 5.053-devel, Yosys 0.69+75, nextpnr-ecp5 0.11.1-30-g3e53a0bf, Trellis/ecppack 1.4-82-g3afe7b5, SBY 0.69. The suite archive SHA-256 is `3af61f750c8040bcdfe317ba6134f93e391d65dc27e6bf39ef56455e48c723ae`.
- Python 3.11.6; dependencies recreated in the clone using `scripts/bootstrap_python.sh` and committed `requirements/phase0.txt` (including NumPy 2.3.5).
- `bench/workloads.yaml` SHA-256: `31c599caa7344c938b588a0f22404cfcfe5fe53b3ef5fae40a568130cfadfca4`. D045 and D047 text and all protected tags were unchanged.
- Final committed source hashes used by the fresh runs: benchmark engine `tb/cocotb/test_axi_fabric_a_benchmark.py` `6d243fe801557d0d97ee273a9dd5f52d42acfd24c7ecc794d34e4e1d080d0e7f`; generator `bench/benchmark_plan.py` `d017c80afe6fcaff0b5032e2e5a4da02a12b6ef6990f357ec26e7c32cb653453`; simulation runner `scripts/run_arch_a_benchmark.sh` `634573f401b4dba12765f87e6a442738611553d60f8d821e12997d8db0d0ada5`; PPA runner `scripts/run_arch_a_ppa.sh` `e1589c5f168d2cc0c113fd321e4d1bb38e3f201d99c6e5d9374ed722bfe7c981`; common wrapper `bench/arch_fabric_wrapper.sv` `8c4a44d4db1947399b8722a5cb6b1cefc643ce17470955ff46b4fc6900fd9cd5`. Fresh full-run source-manifest hashes: A `a89c557e569c7bc0df849f9d155c35b1aa55fb178e08d0c797281b056a02cbda`, B `7d9ea658ef71150d7063f910cd6f0fca0968f8974fafc15fc2d51092c2e0ffe3`; the selected DUT tops were checked as A and B respectively.
- The configured OSS CAD Suite absolute path exists on this qualified host, so no runner or source change was needed. This reproduction does not establish portability to a host without that installation.

## Commands and functional smoke

From the clone, after sourcing the OSS CAD Suite environment and bootstrapping Python:

```bash
scripts/run_fabric_a_gate2_directed.sh
scripts/run_fabric_b_directed.sh
scripts/run_qos_aging_directed.sh
scripts/run_qos_aging_formal.sh
PYTHONPATH=tb/model:tb/random .venv/bin/python -m unittest discover -s tb/model -p 'test_*.py' -v
PYTHONPATH=tb/model:tb/random .venv/bin/python -m unittest discover -s tb/random -p 'test_*.py' -v
ARCH_BENCH_OUT_ROOT=results/raw/gate5/arch_a_qualification ARCH_BENCH_QUALIFICATION=1 ARCH_BENCH_WORKLOADS=W01,W02,W07,W08,W12,W13 ARCH_BENCH_SEEDS=0xFABC0001 scripts/run_arch_a_benchmark.sh
ARCH_BENCH_OUT_ROOT=results/raw/gate5/arch_b_qualification ARCH_BENCH_QUALIFICATION=1 ARCH_BENCH_WORKLOADS=W01,W02,W07,W08,W12,W13 ARCH_BENCH_SEEDS=0xFABC0001 scripts/run_arch_b_benchmark.sh
```

Results: A directed PASS; B directed PASS (444 checks); B scheduler directed PASS (28 checks); B bounded formal prove PASS and meaningful threshold/escape cover PASS; Python unittest discovery PASS (15 model + 15 plan/endpoint tests); A and B qualifications PASS (six scenarios each). An initial `pytest` collection attempt failed because the project package directory named `random` shadows Python's stdlib module under that invocation; the repository's unittest discovery passed and was used for the project tests. No RTL or test source edits were needed.

## Canonical simulation reproduction

Fresh outputs are under the clone's `results/raw/gate5/` directory. Commands:

```bash
ARCH_BENCH_OUT_ROOT=results/raw/gate5/arch_a_full scripts/run_arch_a_benchmark.sh
ARCH_BENCH_OUT_ROOT=results/raw/gate5/arch_b_full scripts/run_arch_b_benchmark.sh
.venv/bin/python bench/summarize_benchmark.py results/raw/gate5/arch_a_full
.venv/bin/python bench/summarize_benchmark.py results/raw/gate5/arch_b_full
.venv/bin/python bench/compare_ab.py results/raw/gate5/arch_a_full results/raw/gate5/arch_b_full results/processed/gate5_reproduction/ab_comparison
```

| Architecture | Runs | Valid JUnit | Active-manager quota | Selected DUT |
|---|---:|---:|---|---|
| A | 70/70 | 70 pass; zero failure/error/skip | 500 warm-up + 5,000 measured | `axi_fabric_a` |
| B | 70/70 | 70 pass; zero failure/error/skip | 500 warm-up + 5,000 measured | `axi_fabric_b` |

All 70 A/B pairs have identical intent counts and intent SHA-256. Workload hash, xorshift32 generator, benchmark engine, endpoint settings, and nearest-method percentile configuration match. The fresh per-seed comparison table (5,890 rows) and median-of-five table (1,178 rows) are byte-for-byte equivalent in parsed data to the published tables. Fresh D045 evaluation is exactly equal to the published JSON.

The old A canonical run manifest recorded wrapper hash `41391b0b…`, while the committed common wrapper and fresh A/B runs use `8c4a44d4…`. The benchmark simulations instantiate the selected Fabric top directly and do not compile the PPA wrapper; the driver, generator, runner, workload, and A RTL source hashes match. A was rerun across all 70 scenarios from the committed source. Its processed measurements match the published results exactly. The original A PPA source manifest already used the committed common-wrapper hash, and the fresh PPA results also match exactly. This metadata discrepancy and its resolution are retained here rather than hidden.

## ECP5 reproduction

Commands:

```bash
ARCH_A_PPA_OUT=results/raw/gate5/arch_a_ppa scripts/run_arch_a_ppa.sh
ARCH_PPA_ARCH=B ARCH_A_PPA_OUT=results/raw/gate5/arch_b_ppa scripts/run_arch_a_ppa.sh
```

Both sweeps produced 55 recorded route attempts (coarse 50/75/100/125/150/175/200 MHz and boundary refinement), with seeds 1–5, on LFE5U-45F/CABGA381/-6. Each output includes direct/wrapped Yosys reports, route matrix/logs/reports, source hashes, tool versions, and PPA summary.

| Metric | A fresh | B fresh | Published comparison | Match |
|---|---:|---:|---:|---|
| Direct Fabric LUT4 | 5,046 | 5,730 | same | Yes |
| Direct Fabric FF | 1,219 | 1,426 | same | Yes |
| Common-wrapper LUT4 | 5,226 | 5,826 | same | Yes |
| Common-wrapper FF | 1,649 | 1,856 | same | Yes |
| All-five-seed timing-clean target | 60 MHz | 55 MHz | same | Yes |

Fresh `ppa_resource_comparison.json` is exactly equal to the published processed JSON. The per-route comparison differs only in clone-local file paths. These results are fixed-wrapper implementation comparisons, not device timing signoff or a universal Fmax claim.

## D045 reproduction

| Frozen criterion | Fresh B result | Decision | Published match |
|---|---:|---|---|
| W08 M2 read admission P99 <= 16 cycles (A baseline 21) | 16 cycles | PASS | Exact |
| W08 M1 read+write throughput >= 10.07665 B/cycle | 6.340714 B/cycle; 59.78% of A's 10.606859 | FAIL | Exact |
| W08 M0 read admission P99 <= 23 cycles (A 21) | 17 cycles | PASS | Exact |
| W08 M0 write admission P99 <= 29 cycles (A 27) | 69 cycles | FAIL | Exact |
| W12 median Jain grant-rate index >= 0.98 | 0.9999999733 | PASS | Exact |

D047 remains **REJECT B under the frozen criteria**. The negative throughput and M0 write-tail findings remain visible and unchanged.

## Figures, limits and artifacts

The four figures were regenerated by the committed `bench/plot_ab_comparison.py` from fresh processed benchmark tables and fresh PPA summaries/routes. The script currently reads PPA summaries from its conventional `arch_a_ppa_matched_v1` and `arch_b_ppa_matched_v1` paths, so those two small summary/route-summary files were copied from the newly generated Gate-5 PPA outputs before plotting (no old raw data was used). The exact plot invocation was `.venv/bin/python bench/plot_ab_comparison.py results/processed/gate5_reproduction/ab_comparison results/raw/gate5/arch_a_full results/raw/gate5/arch_b_full`. Copies are in `results/processed/gate5_reproduction/figures/`; the original published figures remain unchanged. Machine-readable fresh comparison artifacts are in `results/processed/gate5_reproduction/ab_comparison/`.

The full raw fresh-clone logs, XMLs, transaction traces and route reports remain outside Git under `/tmp/fabric-under-pressure-g5-reproduction/results/raw/gate5/`. The reproduction ran on the same qualified physical host and shared OSS CAD Suite, so it is a clean source/dependency reproduction, not independent-host validation. Formal remains bounded and targeted; AXI support is the documented subset; the synthetic endpoint is not production memory; routed results are not board timing signoff.
