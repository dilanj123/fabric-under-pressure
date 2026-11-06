> Separate Codex CLI read-only review context. These are source-review observations, not test execution or human approval.

## Scope and method

Reviewed the tracked files under `bench/`, `scripts/`, and `smoke/`, plus the Gate-0 GitHub workflow and `requirements/phase0.txt`. The tracked `bench/analysis/.keep` file is empty. **No files were edited, and I did not run benchmarks or other project commands.** The observations below describe what the code does; they are not claims that the runners pass.

## Bench files

| File | Behavior-specific observation |
|---|---|
| [arch_fabric_wrapper.sv](bench/arch_fabric_wrapper.sv) | Wraps Fabric A or B with registered pseudo-random legal one-beat traffic, simple target responses, and a response signature intended to keep logic in the synthesis design. |
| [benchmark_plan.py](bench/benchmark_plan.py) | Generates deterministic workload intents from one xorshift32 stream, using frozen seeds and workload profiles. Validates aligned, page-contained S0/S1 transactions and records intent digests. |
| [workloads.yaml](bench/workloads.yaml) | Defines the frozen seeds, sample quotas, endpoint timing, traffic classes, and W00–W13 scenarios. Its declared workload hash is embedded in the generator and plan test. |
| [summarize_benchmark.py](bench/summarize_benchmark.py) | Recomputes latency, payload rate, stall, service-loss, and W12 Jain-index summaries from transaction traces; requires NumPy 2.3.5 and uses nearest-method percentiles. |
| [compare_ab.py](bench/compare_ab.py) | Validates run metadata and JUnit records, pairs A/B summaries, computes per-seed and median metrics, and evaluates frozen D045 criteria. |
| [plot_ab_comparison.py](bench/plot_ab_comparison.py) | Produces four figures from processed A/B and PPA summaries, including admission P99, throughput, service-loss/Jain index, and resource/timing views. |
| [summarize_ppa.py](bench/summarize_ppa.py) | Extracts synthesis cell counts and routed report fields, then reports per-frequency all-seed timing-clean status. |
| [test_benchmark_plan.py](bench/test_benchmark_plan.py) | Checks same-seed replay, seed diversity, W13 target split, W12 shared direction/release behavior, and the frozen workload-file hash. |
| [test_benchmark_driver.py](bench/test_benchmark_driver.py) | Checks packed-lane helpers and endpoint read/B response timing and retention behavior using classes imported from the cocotb benchmark module. |

## Script files

| File | Behavior-specific observation |
|---|---|
| [bootstrap_python.sh](scripts/bootstrap_python.sh) | Creates `.venv`, installs `requirements/phase0.txt`, and writes a pip freeze under Gate-0 raw results. |
| [check_env.sh](scripts/check_env.sh) | Records host identity and versions or absence of the listed Python and EDA tools. |
| [oss_cad_env.sh](scripts/oss_cad_env.sh) | Loads the configured OSS CAD Suite, requires release `20260920`, checks tool paths and version strings, and exports its library paths. |
| [publish_github_and_start_gate0.sh](scripts/publish_github_and_start_gate0.sh) | Checks GitHub auth and repository state, creates or validates the remote, pushes `main`, dispatches Gate-0, watches it, then downloads artifacts. |
| [render_gate0_candidate_evidence.sh](scripts/render_gate0_candidate_evidence.sh) | Requires Darwin/arm64 and selected smoke artifacts, then writes a candidate evidence summary; it does not tag or publish a PASS. |
| [run_arch_a_benchmark.sh](scripts/run_arch_a_benchmark.sh) | Selects A or B RTL, creates a source manifest, builds with Verilator/cocotb, runs workload/seed pairs, checks XML and sample quotas, and removes build products. Supports environment overrides and qualification mode. |
| [run_arch_b_benchmark.sh](scripts/run_arch_b_benchmark.sh) | Sets Architecture B and its default output directory, then delegates to the shared benchmark runner. |
| [run_arch_a_ppa.sh](scripts/run_arch_a_ppa.sh) | Selects A or B, synthesizes direct Fabric and common wrapper, then runs fixed and refined ECP5 frequency/seed sweeps and summarizes results. |
| [run_arch_b_ppa.sh](scripts/run_arch_b_ppa.sh) | Sets Architecture B and its output location, then delegates to the shared PPA runner. |
| [run_ar_target_path_checks.sh](scripts/run_ar_target_path_checks.sh) | Runs AR path, S3, read-bank, composition, and read/write-ID-independence simulations; synthesizes two components and runs prove/cover jobs. |
| [run_aw_target_path_checks.sh](scripts/run_aw_target_path_checks.sh) | Lints, simulates, synthesizes, and proves/covers the Architecture-A AW target path. |
| [run_aw_target_scheduler_checks.sh](scripts/run_aw_target_scheduler_checks.sh) | Checks the AW scheduler alone and in composition, including lint, simulation, synthesis, prove, and cover. |
| [run_b_response_router_checks.sh](scripts/run_b_response_router_checks.sh) | Checks the 4-way RR arbiter, B response router, and write-state composition; runs lint, simulation, synthesis, prove, and cover. |
| [run_b_response_router_repair_checks.sh](scripts/run_b_response_router_repair_checks.sh) | Repeats the same B-router/arbiter/composition check sequence into a repair-specific results directory. |
| [run_decoder_checks.sh](scripts/run_decoder_checks.sh) | Lints, simulates, synthesizes, and proves/covers the address decoder. |
| [run_fabric_a_gate2_directed.sh](scripts/run_fabric_a_gate2_directed.sh) | Lints and runs the Architecture-A whole-fabric directed testbench; requires its PASS marker. |
| [run_fabric_a_integration_checks.sh](scripts/run_fabric_a_integration_checks.sh) | Runs whole-top lint, directed simulation, and ECP5 synthesis for Architecture A. |
| [run_fabric_b_directed.sh](scripts/run_fabric_b_directed.sh) | Lints and runs the Architecture-A directed testbench compiled against Fabric B with the B define; requires a B-named PASS marker. |
| [run_gate0.sh](scripts/run_gate0.sh) | Invokes environment capture and seven smoke scripts, continuing after failures and returning aggregate failure status. |
| [run_gate2_closure.sh](scripts/run_gate2_closure.sh) | Runs oracle unit tests, A directed regression, cocotb oracle checks, trace checks, and deliberate bad-RDATA sensitivity checking. |
| [run_gate2_oracle_b.sh](scripts/run_gate2_oracle_b.sh) | Builds Fabric B against the A-named oracle module, then checks JUnit counts and selected closure markers. |
| [run_gate3_random.sh](scripts/run_gate3_random.sh) | Generates or replays Architecture-A random plans, runs cocotb, and checks each seed’s coverage plus aggregated coverage thresholds. |
| [run_gate3_random_v2.sh](scripts/run_gate3_random_v2.sh) | Generates or replays v2 plans, selects A/B, runs cocotb per plan, checks operation counts and coverage, and aggregates five-seed coverage. |
| [run_gate3_random_long.sh](scripts/run_gate3_random_long.sh) | Sets the v2 operation count to 2,048 and delegates to the v2 runner. |
| [run_gate3_random_b.sh](scripts/run_gate3_random_b.sh) | Selects B and 512 operations, then delegates to v2. |
| [run_gate3_random_b_long.sh](scripts/run_gate3_random_b_long.sh) | Selects B and 2,048 operations, then delegates to v2. |
| [run_id_mapping_checks.sh](scripts/run_id_mapping_checks.sh) | Lints, simulates, synthesizes, and proves/covers the ID mapper. |
| [run_outstanding_tracker_checks.sh](scripts/run_outstanding_tracker_checks.sh) | Lints, simulates, synthesizes, and proves/covers the outstanding tracker. |
| [run_qos_aging_directed.sh](scripts/run_qos_aging_directed.sh) | Builds and runs the QoS aging arbiter directed testbench and checks its PASS marker. |
| [run_qos_aging_formal.sh](scripts/run_qos_aging_formal.sh) | Runs QoS aging prove/cover and checks expected status text. |
| [run_r_response_router_checks.sh](scripts/run_r_response_router_checks.sh) | Checks R router, burst lengths, and read lifecycle; also synthesizes and proves/covers the R router. |
| [run_request_legality_checks.sh](scripts/run_request_legality_checks.sh) | Lints, simulates, synthesizes, and proves/covers request legality logic. |
| [run_rr_arbiter_checks.sh](scripts/run_rr_arbiter_checks.sh) | Lints, simulates, synthesizes, proves/covers the RR arbiter, and runs per-manager fairness jobs. |
| [run_s3_error_target_checks.sh](scripts/run_s3_error_target_checks.sh) | Runs S3 standalone and read/write lifecycle simulations, formal jobs, and synthesis. Some build artifacts/logs go to `/tmp`. |
| [run_s3_error_target_repair_checks.sh](scripts/run_s3_error_target_repair_checks.sh) | Repeats S3 standalone/lifecycle, formal, and synthesis checks into a repair output directory; build products/logs go to `/tmp`. |
| [run_w_target_path_checks.sh](scripts/run_w_target_path_checks.sh) | Checks W path standalone, route, and composition, with synthesis and formal prove/cover for W path and AW/W composition. |
| [run_write_owner_checks.sh](scripts/run_write_owner_checks.sh) | Lints, simulates two write-owner benches, synthesizes, and proves/covers the write owner. |
| [run_write_state_bank_checks.sh](scripts/run_write_state_bank_checks.sh) | Lints state bank and AW path, simulates bank/composition, synthesizes bank, and runs bank/composition prove/cover. |
| [run_smoke_bfm.sh](scripts/run_smoke_bfm.sh) | Checks cocotb/BFM imports, builds the namespace-only AXI bus smoke top, and runs the cocotb BFM test with XML checks. |
| [run_smoke_formal.sh](scripts/run_smoke_formal.sh) | Runs formal prove and cover, then an intentional fail task; accepts any nonzero result from that final task as expected failure. |
| [run_smoke_pnr.sh](scripts/run_smoke_pnr.sh) | Synthesizes and routes the ECP5 smoke design; checks text config exists. If `ecppack` is available, its failure is ignored. |
| [run_smoke_sim.sh](scripts/run_smoke_sim.sh) | Checks cocotb import, builds handshake counter, runs test, and checks XML error/failure counts. |
| [run_smoke_sv.sh](scripts/run_smoke_sv.sh) | Runs Verilator lint, optional Slang lint, and Yosys parse/proc/check on SV feature smoke code. |
| [run_smoke_synth.sh](scripts/run_smoke_synth.sh) | Synthesizes the ECP5 smoke design and requires a nonempty JSON output. |
| [run_smoke_wrapper.sh](scripts/run_smoke_wrapper.sh) | Synthesizes the preserve harness and checks that the top has cells remaining. |

## Smoke, workflow, and package files

| File | Behavior-specific observation |
|---|---|
| [axi_bfm_bus.sv](smoke/axi_bfm_bus.sv) | Declares an AXI signal namespace with `inout` ready/response signals; contains no bus behavior. |
| [ecp5_smoke.sv](smoke/ecp5_smoke.sv) | Small initialized shift-register design for synthesis and ECP5 route smoke. |
| [formal_counter.sv](smoke/formal_counter.sv) | Counter with an invariant assertion, cover point, and optional failing assertion under `EXPECT_FAIL`. |
| [handshake_counter.sv](smoke/handshake_counter.sv) | Always-ready counter records accepted input handshakes and last payload, with synchronous active-low reset. |
| [preserve_harness.sv](smoke/preserve_harness.sv) | Generates and folds a 256-bit payload through sequential logic to check that synthesis retains nonempty logic. |
| [sv_features.sv](smoke/sv_features.sv) | Exercises packed structs, package function, parameterized modules, arrays, generate loops, and sequential reset. |
| [.github/workflows/gate0-macos-arm64.yml](.github/workflows/gate0-macos-arm64.yml) | Manually dispatched macOS 14 arm64 workflow; downloads and hash-checks OSS CAD Suite, bootstraps Python, runs Gate-0, and uploads raw/candidate evidence. |
| [requirements/phase0.txt](requirements/phase0.txt) | Pins cocotb, cocotbext-axi, pytest, NumPy, pandas, and matplotlib for the Phase-0 environment. |

## Demonstrated integrity, metric, and runner concerns

These are code-path observations, not claims about outputs from an execution in this review.

- **Benchmark summarizer counts completions beyond the measurement window in latency and payload totals.** `summarize_benchmark.py` selects all completed transactions with `sampled_latency`, but does not additionally filter those records by completion cycle. Its payload-byte calculation likewise includes every transaction beat in the trace. By contrast, several other metrics explicitly filter cycles to the measurement interval. This makes the computed metric windows asymmetric.
- **Architecture-B PPA uses the same synthesis runner filename/hash as A.** `run_arch_b_ppa.sh` delegates to `run_arch_a_ppa.sh`, and that runner records its own hash in `source_hashes.txt`. The architecture-specific wrapper is therefore represented by the shared runner’s hash, rather than a hash of the B entry-point script.
- **PPA summaries can report empty synthesis counts without failing.** `summarize_ppa.py` returns `{}` when it cannot find the expected Yosys report block; the caller writes that result into the summary without asserting counts were parsed. Missing or changed report formatting could therefore yield an incomplete summary.
- **Some smoke checks are permissive about failure specificity.** The formal smoke accepts any nonzero exit code for the expected-fail task; it does not itself check that the failure came from the intentional assertion. The PNR smoke ignores `ecppack` failure when the tool exists. These behaviors limit what a passing runner result establishes.
- **A/B comparison validates pair presence and selected shared components, but not every frozen field at the comparison boundary.** `compare_ab.py` checks 70 metadata files, quotas, source-manifest linkage, and equality for selected component entries. It does not itself assert that the 70 workload/seed pairs equal the exact frozen W00–W13 × five-seed set, nor does it compare every manifest field (such as the wrapper hash). Other project evidence may cover those checks; this observation is limited to this script’s own validation.

I did not find a basis in this read-only pass to claim a benchmark result is invalid or to assert any RTL defect.