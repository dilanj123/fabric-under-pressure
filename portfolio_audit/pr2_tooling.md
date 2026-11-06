# PR2 — CAD-suite path portability and runner qualification

Base: `8e1a79406163174192b95e384463ab876cb986c9` (PR1 merged to `main`).

## Change

Added `scripts/oss_cad_env.sh` and updated the 19 existing shell runners that embedded `/Users/Dilan/eda/fabric-under-pressure/oss-cad-suite`. Set `OSS_CAD_SUITE_ROOT` to use an installation elsewhere; otherwise the helper uses `~/eda/fabric-under-pressure/oss-cad-suite`. It requires the recorded suite release marker `20260920`, verifies that Verilator, Yosys, SBY, nextpnr-ecp5, ecppack, Yices and Python resolve inside that installation, and checks their recorded versions. Missing or mismatched installations fail with a diagnostic. Python libraries for cocotb are resolved from the selected suite. No RTL, formal source, benchmark engine, generator, workload, endpoint, sample policy, metric or processed comparison changed.

The new benchmark qualification manifests contain the new launcher SHA-256. The earlier full canonical A/B results remain intact and linked to their original source manifests. The launcher change only selects and verifies the already-frozen tool installation; these six-workload runs were qualification checks, not replacement canonical measurements. No full canonical sweep or PPA sweep was repeated.

Exact base/current hashes for the 19 launchers and the new helper are in [`tooling_script_hashes.csv`](tooling_script_hashes.csv). The two benchmark launchers naturally have new runner hashes in the qualification manifests; `tb/cocotb/test_axi_fabric_a_benchmark.py`, `bench/benchmark_plan.py`, `bench/workloads.yaml`, wrapper and selected RTL hashes are unchanged.

## Validation

- `bash -n scripts/*.sh` — PASS.
- Sourced the helper with the default and explicit qualified root — PASS; tools resolved under the selected suite.
- Missing installation and release marker `wrong-release` — both rejected before a runner starts.
- Python plan/reference-model/endpoint/scheduler/oracle suite — 30 tests PASS using `.venv` and the documented `PYTHONPATH`.
- `./scripts/run_fabric_a_gate2_directed.sh` — PASS, 384 checks (`results/raw/fabric_a_gate2_directed/simulation.log`).
- `./scripts/run_fabric_b_directed.sh` — PASS, 444 checks (`results/raw/fabric_b_directed/simulation.log`).
- `./scripts/run_qos_aging_directed.sh` — PASS.
- `./scripts/run_qos_aging_formal.sh` — PASS: SBY prove `PASS 0 1`; cover `PASS 0 5`, including the threshold/escape cover at step 65.
- `./scripts/run_gate2_closure.sh` — PASS (`results/raw/gate2_oracle/`).
- `./scripts/run_fabric_a_integration_checks.sh` — PASS, 384 checks.
- A and B benchmark qualification: W01, W02, W07, W08, W12 and W13, seed `0xFABC0001`, one testcase per run, zero XML failures/errors/skips. Each active manager retained 75 completions after at least 25 warm-up completions. All six A/B pairs used identical intent counts and SHA-256 values; manifests selected `axi_fabric_a` and `axi_fabric_b` respectively. W13 recorded 59 parallel-target address cycles for A and 58 for B; W12 grants were equal/near-equal; W08 exercised the competing QoS load. Qualification raw files are in `results/raw/portfolio_audit_pr2_A/` and `results/raw/portfolio_audit_pr2_B/` on the validation host.

The qualification runner emits the existing Verilator `UNOPTFLAT` warnings in the top-level combinational dependency analysis; both A/B simulations completed with passing XML and transaction counts. No RTL was changed in response.
