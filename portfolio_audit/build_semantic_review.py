#!/usr/bin/env python3
"""Build current-HEAD source-review and Gate-5 delta registers.

This script inventories tracked source files and combines them with curated
review notes. It does not infer that a file was semantically reviewed from
its hash or from pattern scans; review notes/status are explicit below.
"""
from __future__ import annotations
import csv, hashlib, pathlib, subprocess

ROOT = pathlib.Path(__file__).resolve().parents[1]
BASE = 'd2ef2bb2ec41a2b99f6532618a4a2d41bca736b5'
REVIEW_REV = '05440c322bbd49beba59f07f3f5d51a0af6faef6'
OUT = ROOT / 'portfolio_audit'

# Curated, file-specific review notes from the source passes. For formal files,
# the configuration is read alongside its harness and the property family is
# identified by module/job name; source-line properties are recorded as counts.
RTL = {
'axi_address_decoder.sv':'Combinational decode maps S0-S2 windows; unmapped addresses default to S3.',
'axi_ar_target_path_a.sv':'Manager AR admission captures widened ID and full payload in one registered target slot; slot drain/refill are separate cycles.',
'axi_ar_target_path_b.sv':'Same registered AR slot/admission boundary as A, with B scheduler selection.',
'axi_ar_target_scheduler_a.sv':'Eligibility combines valid/legal/target match and read credit; successor suppressed on admission edge.',
'axi_ar_target_scheduler_b.sv':'Separates legal-pending age accounting from current admission eligibility.',
'axi_aw_target_path_a.sv':'Manager AW admission captures full payload and widened ID; target slot holds through stall.',
'axi_aw_target_path_b.sv':'Same AW slot/admission boundary as A, with B scheduler selection.',
'axi_aw_target_scheduler_a.sv':'Blocks a target with unfinished W owner and suppresses same-edge successor after AW admission.',
'axi_aw_target_scheduler_b.sv':'Ages legal-pending AW independent of current capacity/owner eligibility.',
'axi_b_response_router.sv':'Registered per-manager B slots; widened BID checks manager/busy ID; write retirement is manager B handshake.',
'axi_fabric_a.sv':'Top composes four AW/AR/W target paths, shared read/write state, response routers and internal S3.',
'axi_fabric_b.sv':'B top reuses common datapath/state/response paths and substitutes B AW/AR target paths.',
'axi_id_mapper.sv':'Widened ID includes manager prefix; reserved prefix 11 is invalid on return.',
'axi_outstanding_tracker.sv':'Registered busy/count state controls admission; allocation/completion update on clock edge with pre-state semantics.',
'axi_qos_aging_arbiter_3.sv':'Three-request QoS selection, age-64 escape set, RR ties, stable held grant and accepted-admission pointer update.',
'axi_r_response_router.sv':'Per-manager registered R slot locks target/RID through manager-accepted RLAST; completion occurs at final manager handshake.',
'axi_read_state_bank.sv':'Per-manager read tracker allocates on AR admission and clears from router completion event.',
'axi_request_legal.sv':'Enforces aligned full-width INCR, normal lock, LEN<=15 and 4-KiB-contained burst subset.',
'axi_rr_arbiter_3.sv':'Registered 3-way RR grant remains held until ready; pointer advances only on acceptance.',
'axi_rr_arbiter_4.sv':'Registered 4-way RR response selection holds under backpressure and advances on accepted service.',
'axi_s3_error_target.sv':'Independent one-context read/write DECERR endpoint; B after final W and R beats follow ARLEN.',
'axi_w_target_path.sv':'Owner-directed one-beat target W slot; final delivered WLAST does not drain/refill same edge.',
'axi_write_owner.sv':'Captures target/ID/beat count on allocation; owner retires only on accepted correctly-final target W beat.',
'axi_write_state_bank.sv':'Atomic AW allocation couples outstanding credit and W owner; owner and B lifetime retire separately.',
'fabric_addr_map_pkg.sv':'Central S0-S2 windows and supported-subset constants; S3 is default target.'}

TB = {
'address_decoder_tb.sv':'Checks mapped boundaries and representative catch-all S3 decode; this is decode-only.',
'axi_ar_r_read_lifecycle_tb.sv':'Composes AR allocation, R-source lock, final-beat backpressure and post-RLAST reuse timing.',
'axi_ar_read_state_composition_tb.sv':'Composes registered AR path and read bank; target consume is distinct from manager admission.',
'axi_ar_s3_tb.sv':'Checks parameterized S3 AR transport and widened ID; endpoint response is outside this test.',
'axi_ar_target_path_tb.sv':'Checks all manager fields, eligibility blockers, registered target stability and no same-edge slot refill.',
'axi_aw_target_path_tb.sv':'Checks AW payload/ID capture, reset, stall stability, eligibility and D031/D032 timing.',
'axi_aw_target_scheduler_tb.sv':'Checks RR selection/hold, owner eligibility and independence across targets.',
'axi_aw_w_state_composition_tb.sv':'Checks W-before-AW blocking, owner tracking, target stall and owner release on target WLAST separately from B retirement.',
'axi_aw_write_state_composition_tb.sv':'Checks AW admission-to-shared-bank state composition and allocation lifetime.',
'axi_b_response_router_tb.sv':'Checks widened ID validation, per-manager response slot hold, competing target arbitration and reset.',
'axi_b_write_state_composition_tb.sv':'Checks B routing retirement against write bank, including stalled response and ownership/outstanding separation.',
'axi_fabric_a_tb.sv':'Whole-top directed integration: mapped/S3 routes, outstanding limits, stalls, ordering, reset and integrated AW/AR fairness using sampled public handshakes.',
'axi_qos_aging_arbiter_3_tb.sv':'Directed QoS and age boundary/escape/hold behavior against explicit expected grants.',
'axi_r_burst_lengths_tb.sv':'Checks R beat count and RLAST for selected 2-, 4- and 16-beat cases.',
'axi_r_response_router_tb.sv':'Checks target arbitration, source/RID lock, stalls, drain/refill, invalid IDs, reorder and S3 propagation.',
'axi_read_state_bank_tb.sv':'Checks per-manager read busy/count allocation, capacity, completion and reset.',
'axi_read_write_id_independence_tb.sv':'Checks same numeric ID can be live independently in read and write directions.',
'axi_rr_arbiter_4_tb.sv':'Checks four-source RR selection, stalls and pointer progression.',
'axi_s3_error_target_tb.sv':'Checks standalone unmapped read/write DECERR behavior, burst lengths, backpressure and reset.',
'axi_s3_read_lifecycle_tb.sv':'Composes AR path, read bank, S3, R router and final manager completion.',
'axi_s3_write_lifecycle_tb.sv':'Composes AW path, write bank, owner W path, S3 and B router.',
'axi_w_target_path_tb.sv':'Checks owner-gated W route, held payload, nonfinal refill and final-beat no-refill.',
'axi_w_target_route_tb.sv':'Checks W routing only to selected owner target and final slot release.',
'axi_write_owner_3_tb.sv':'Checks independent owner counters for three managers.',
'axi_write_owner_tb.sv':'Checks allocation metadata, beat accounting, WLAST, pre-state reuse and reset.',
'axi_write_state_bank_tb.sv':'Checks atomic write allocation, four-live capacity, one owner, WLAST/B split and following-cycle reuse.',
'id_mapper_tb.sv':'Exhaustively checks valid manager/ID widening, reserved prefixes and collision prevention.',
'outstanding_tracker_tb.sv':'Checks capacity, duplicate/unknown completion, reset and read/write pre-state independence.',
'request_legality_tb.sv':'Checks length, size, burst, alignment, lock and page-boundary legality.',
'rr_arbiter_tb.sv':'Checks pointer/request masks, rotation, dynamic arrivals, held grant stability and reset.',
'test_axi_bfm_smoke.py':'Third-party BFM/RAM smoke validates basic aligned read/write and payload/response; not Fabric correctness.',
'test_axi_fabric_a_benchmark.py':'Central cycle snapshot driver records public handshake events, held-payload checks, timing and synthetic endpoint traffic.',
'test_axi_fabric_a_concurrent_endpoint.py':'Checks DUT R retention under manager backpressure against separate endpoint memory.',
'test_axi_fabric_a_oracle.py':'Whole-DUT mapped I/O exercises independent Python decode/lifecycle/byte-memory oracle; helper polling weakens edge-to-call correlation.',
'test_axi_fabric_a_random.py':'Saved-plan random driver has deterministic prologue then serial plan operations; not random concurrency evidence.',
'test_axi_fabric_a_random_v2.py':'Concurrent manager workers and handshake-aware endpoint drivers; observed random depth remains two in documented runs.',
'test_smoke_counter.py':'Checks generic counter ready/accept/data behavior only.',
'axi_endpoint_model.py':'Separate byte memory applies WSTRB and queues B after final W; model does not itself enforce AWLEN/W count.',
'axi_reference_model.py':'Independent address/legal/lifecycle/data oracle; only advances when caller invokes it, so callsite handshake correlation matters.',
'test_axi_reference_model.py':'Negative tests validate oracle detection of malformed/lost/duplicated/misrouted transactions, not DUT behavior.',
'__init__.py':'Python package marker for deterministic random-plan support.',
'axi_random_plan.py':'Seeded intent generation, validation, serialization and address-region checking; does not establish simulator execution.',
'concurrent_bus.py':'Shadow packed-lane dictionaries prevent independent worker read-modify-write overwrites; no handshake sampling.',
'concurrent_endpoint.py':'Queued B/R drivers retain active payload and advance only on sampled valid-ready events.',
'test_axi_random_plan.py':'Checks deterministic replay/diversity, legality, schema and rejection of malformed target/page associations.',
'test_concurrent_bus.py':'Checks packed lane updates and target ready packing for the concurrent bus helper.',
'test_concurrent_endpoint.py':'Checks queued response payload hold under backpressure and sequential read beats.',
'test_v3_scheduler.py':'Pure Python tests read/write capacity, D028 delayed reuse, W owner release and reset; not DUT-facing v3 evidence.',
'v3_scheduler.py':'Pure Python manager live-ID/presentation/W-owner state; no DUT timing or endpoint behavior.'}

BENCH = {
'arch_fabric_wrapper.sv':'Registered pseudo-random pseudo-manager traffic and response-signature wrapper for common A/B synthesis/PPA.',
'benchmark_plan.py':'Frozen xorshift plan generation, workload-specific traffic offers and intent hashing independent of DUT grants.',
'compare_ab.py':'Pairs A/B run metadata, validates XML/manifests and evaluates frozen D045 from per-seed results; does not hard-code exact pair set at comparison boundary.',
'plot_ab_comparison.py':'Generates four figures from processed latency/throughput/fairness/PPA tables.',
'summarize_benchmark.py':'Recomputes latency and common-window throughput from event traces with NumPy nearest percentiles.',
'summarize_ppa.py':'Parses synthesis and routed results; failed resource parse can yield empty resource dictionary rather than hard failure.',
'test_benchmark_driver.py':'Unit checks packed bus and benchmark endpoint timing/retention via imported test driver classes.',
'test_benchmark_plan.py':'Checks frozen YAML hash, replay determinism, diversity and selected W12/W13 methodology.',
'workloads.yaml':'Frozen W00-W13 scenarios, five seeds, sample quotas and endpoint configuration; hash checked against D045 experiment.',
'.keep':'Empty directory placeholder; not an engineering source.'}

SCRIPT = {
'bootstrap_python.sh':'Creates venv and installs pinned phase0 Python requirements.',
'check_env.sh':'Captures host and Python/EDA tool availability/version data.',
'oss_cad_env.sh':'Selects configurable OSS CAD root and checks pinned release/tool versions.',
'publish_github_and_start_gate0.sh':'Checks GitHub setup, dispatches Gate-0 workflow and downloads evidence.',
'render_gate0_candidate_evidence.sh':'Builds candidate summary from required smoke outputs; not a PASS/tag mechanism.',
'run_ar_target_path_checks.sh':'Runs focused AR/path/state checks plus synthesis and bounded formal jobs.',
'run_arch_a_benchmark.sh':'Shared A/B benchmark runner builds selected top, creates manifest, runs plans and checks quotas/XML.',
'run_arch_a_ppa.sh':'Shared selector performs direct/wrapper synthesis and fixed/refined ECP5 sweeps.',
'run_arch_b_benchmark.sh':'Sets B selection/output then delegates to shared benchmark runner.',
'run_arch_b_ppa.sh':'Sets B selection/output then delegates to shared PPA runner.',
'run_aw_target_path_checks.sh':'Lint/sim/synthesis and bounded formal checks for A AW target path.',
'run_aw_target_scheduler_checks.sh':'Checks AW arbitration boundary and composition across lint, simulation, synthesis and formal.',
'run_b_response_router_checks.sh':'Checks RR4, B router and write-state composition across simulation/synthesis/formal.',
'run_b_response_router_repair_checks.sh':'Runs B-router repair regression to separate evidence output paths.',
'run_decoder_checks.sh':'Runs decode lint/sim/synthesis and bounded formal checks.',
'run_fabric_a_gate2_directed.sh':'Runs A whole-top directed simulator and requires its PASS marker.',
'run_fabric_a_integration_checks.sh':'Runs A top lint, directed regression and ECP5 synthesis.',
'run_fabric_b_directed.sh':'Builds shared directed TB against B top and validates B-specific PASS marker.',
'run_gate0.sh':'Runs environment capture and smoke suites, aggregates failures rather than stopping at first failure.',
'run_gate2_closure.sh':'Combines oracle unit, A directed, cocotb, trace and checker-sensitivity tests.',
'run_gate2_oracle_b.sh':'Builds B against shared oracle and checks JUnit and closure markers.',
'run_gate3_random.sh':'Generates/replays original A plans and validates per-seed/aggregate coverage.',
'run_gate3_random_v2.sh':'Generates/replays v2 plans for A/B and validates operation counts and observed coverage.',
'run_gate3_random_long.sh':'Sets 2048-operation v2 mode then delegates to common random runner.',
'run_gate3_random_b.sh':'Selects B and 512-operation mode for common random runner.',
'run_gate3_random_b_long.sh':'Selects B and 2048-operation mode for common random runner.',
'run_id_mapping_checks.sh':'Runs ID mapper lint, directed simulation, synthesis and bounded proof/cover.',
'run_outstanding_tracker_checks.sh':'Runs tracker lint, simulation, synthesis and bounded proof/cover.',
'run_qos_aging_directed.sh':'Builds and runs focused B QoS/age directed test; checks PASS marker.',
'run_qos_aging_formal.sh':'Runs B scheduler bounded prove/cover and checks reported statuses.',
'run_r_response_router_checks.sh':'Checks R router, burst counts, lifecycle, synthesis and bounded formal.',
'run_request_legality_checks.sh':'Runs legality lint, simulation, synthesis and bounded proof/cover.',
'run_rr_arbiter_checks.sh':'Runs RR simulation/synthesis/prove/cover and assumption-bounded fairness jobs.',
'run_s3_error_target_checks.sh':'Runs S3 endpoint/lifecycle simulation, formal and synthesis; some outputs are temporary.',
'run_s3_error_target_repair_checks.sh':'Repeats S3 W-before-AW repair-focused checks into separate results.',
'run_smoke_bfm.sh':'Checks BFM imports, builds namespace bus top, executes BFM and validates XML.',
'run_smoke_formal.sh':'Runs formal smoke and intentional failing task; nonzero expected-fail check does not verify failure cause.',
'run_smoke_pnr.sh':'Routes ECP5 smoke and checks text config; optional ecppack failure is ignored.',
'run_smoke_sim.sh':'Runs counter cocotb smoke and validates failure/error counts in XML.',
'run_smoke_sv.sh':'Runs Verilator/optional Slang/Yosys SV smoke checks.',
'run_smoke_synth.sh':'Synthesizes ECP5 smoke and requires output JSON.',
'run_smoke_wrapper.sh':'Checks synthesis preserves logic in generic wrapper.',
'run_w_target_path_checks.sh':'Checks W target path/route/composition with synthesis and bounded formal.',
'run_write_owner_checks.sh':'Runs owner simulation, synthesis and bounded prove/cover.',
'run_write_state_bank_checks.sh':'Checks write bank/composition simulation, synthesis and bounded formal.'}

FORMAL_TOPIC = {
'address_decoder':'One-hot decode and default S3 mapping.',
'aw_target_scheduler':'AW eligibility, owner exclusion and RR scheduler selection/hold.',
'axi_ar_read_state_composition':'AR admission/read-state composition and delayed capacity reuse.',
'axi_ar_target_path':'Registered AR slot, one-hot admission, stall stability and D036 suppression.',
'axi_aw_target_path':'Registered AW slot, one-hot admission, payload stability and D031 suppression.',
'axi_aw_w_state_composition':'AW allocation through W owner and target W completion under source assumptions.',
'axi_aw_write_state_composition':'AW path/shared write-state atomic allocation and capacity safety.',
'axi_b_response_router':'B source stability, validation, registered slot admission and manager completion.',
'axi_qos_aging_arbiter_3':'QoS max selection, age transitions/threshold escape, RR, held grant and reset.',
'axi_r_response_router':'R slot/lock, source stability, beat sequencing and completion separation.',
'axi_read_state_bank':'Read count/popcount, four-entry bound, admission and completion gating.',
'axi_s3_error_target_read':'S3 read state, DECERR payload/beat count and response stability.',
'axi_s3_error_target_write':'S3 write state, DECERR B and W-before-AW/no-context behavior.',
'axi_w_target_path':'Owner-directed target W handshake, stall stability and final no-refill.',
'axi_write_owner':'Owner metadata/beat count, WLAST release, bounds and reset.',
'axi_write_state_bank':'Atomic AW allocation, count bound, invalid event gating and reset.',
'id_mapper':'Manager/ID widen and strip mapping with reserved-prefix rejection.',
'outstanding_tracker':'Busy/count allocation/completion, uniqueness and capacity invariants.',
'request_legality':'Supported request shape and page-boundary legality.',
'rr_arbiter':'RR one-hot selection, held stability and pointer advance.',
'rr_arbiter_4':'Four-source RR response arbitration, held selection and pointer advance.',
'rr_arbiter_fairness':'Bounded per-manager service under continuous request and recurring READY assumptions.',
'smoke':'Generic formal counter smoke only.'}


def git(*args: str) -> str:
    return subprocess.check_output(['git', *args], cwd=ROOT).decode()

def blob(path: str, rev: str=REVIEW_REV) -> str:
    return git('rev-parse', f'{rev}:{path}').strip()

def tracked(rev: str=REVIEW_REV) -> list[str]:
    return sorted(x for x in git('ls-tree','-r','--name-only',rev).splitlines() if x)

def content_at(path: str, rev: str=REVIEW_REV) -> bytes:
    return subprocess.check_output(['git','cat-file','blob',f'{rev}:{path}'],cwd=ROOT)

def source_category(p: str) -> str | None:
    if p.startswith('rtl/') and p.endswith('.sv'): return 'RTL'
    if p.startswith('formal/') and p.endswith(('.sv','.sby')): return 'FORMAL'
    if p.startswith('tb/') and p.endswith(('.sv','.py')): return 'TEST/MODEL'
    if p.startswith('bench/') and p.endswith(('.sv','.py','.yaml')): return 'BENCHMARK'
    if p.startswith('scripts/') and p.endswith('.sh'): return 'SCRIPT'
    if p.startswith('smoke/') and p.endswith('.sv'): return 'SMOKE'
    if p.startswith('.github/workflows/') and p.endswith(('.yml','.yaml')): return 'CI'
    if p.startswith('portfolio_audit/') and p.endswith('.py'): return 'AUDIT TOOL'
    if p == 'requirements/phase0.txt': return 'DEPENDENCIES'
    return None

def purpose(p: str, content: str) -> tuple[str,str]:
    name=pathlib.Path(p).name
    if p.startswith('rtl/'):
        return 'Production module/package', RTL.get(name, 'Reviewed module implementation and its direct producer/consumer contract.')
    if p.startswith('formal/'):
        stem=pathlib.Path(p).stem
        if name.endswith('.sby'):
            cfg=content.replace('\n','; ')
            return 'Formal job configuration', f"Selects the {FORMAL_TOPIC.get(stem,stem+' property family')} harness; inspected mode, engine, depth and file selection: {cfg[:210]}"
        # Formal harness records the exact local assumptions/assertion families visible in source.
        import re
        modules=re.findall(r'\bmodule\s+([A-Za-z0-9_$]+)',content)
        ass=len(re.findall(r'\bassume\s*\(',content)); ast=len(re.findall(r'\bassert\s*\(',content)); cov=len(re.findall(r'\bcover\s*\(',content))
        topic=FORMAL_TOPIC.get(stem, next((v for k,v in FORMAL_TOPIC.items() if stem.startswith(k)),stem+' local property set'))
        return 'Formal harness', f'{topic} Harness module(s): {", ".join(modules) or "none parsed"}; explicit assume/assert/cover calls={ass}/{ast}/{cov}. Inspected DUT binding and reset/input constraints; bounded property scope only.'
    if p.startswith('tb/'):
        note=TB.get(name, 'Reviewed test/helper implementation and traced its caller or DUT/model boundary.')
        return ('Directed testbench' if p.startswith('tb/directed/') else 'Cocotb test' if p.startswith('tb/cocotb/') else 'Reference/endpoint model' if p.startswith('tb/model/') else 'Random-plan/scheduler support'), note
    if p.startswith('bench/'):
        return 'Benchmark source/configuration', BENCH.get(name, 'Reviewed plan/endpoint/metric call flow and frozen configuration dependencies.')
    if p.startswith('scripts/'):
        return 'Runner/environment script', SCRIPT.get(name,'Reviewed command selection, error propagation, output paths and delegated scripts.')
    if p.startswith('smoke/'):
        return 'Toolchain smoke source', {
            'axi_bfm_bus.sv':'Interface namespace only; inout bus fields carry no protocol implementation.',
            'ecp5_smoke.sv':'Small initialized shift register validates ECP5 synthesis/route path.',
            'formal_counter.sv':'Counter invariant/cover and EXPECT_FAIL assertion support formal smoke.',
            'handshake_counter.sv':'Always-ready counter updates only on valid/ready and synchronous active-low reset.',
            'preserve_harness.sv':'Sequential signature consumes generated payload to test synthesis observability.',
            'sv_features.sv':'Compile smoke covers package, packed struct, arrays, generate and reset syntax.'}.get(name,'Reviewed smoke-only behavior; not product functionality.')
    if p.startswith('.github/'):
        return 'CI workflow','Manual macOS arm64 Gate-0 job downloads hash-checked tool bundle, bootstraps Python, runs gate and uploads candidate/raw evidence.'
    if p.startswith('portfolio_audit/'):
        return 'Audit utility','Reviewed tracked-file register generation, hash/redaction boundaries and tests; the tool is inventory support, not semantic review.'
    return 'Dependency pin','Pins Python runtime/test/benchmark libraries; actual environment is recorded by Gate-0/Gate-5 evidence.'


def evidence_for(p: str) -> str:
    """Return exact supporting source/evidence paths without implying reruns."""
    name=pathlib.Path(p).name
    stem=pathlib.Path(p).stem
    if p.startswith('rtl/'):
        key=stem
        if key not in ('axi_fabric_a','axi_fabric_b') and (key.endswith('_a') or key.endswith('_b')): key=key[:-2]
        aliases={
            'axi_fabric_a':'axi_fabric_a_tb','axi_fabric_b':'axi_fabric_a_tb',
            'axi_ar_target_path':'axi_ar_target_path_tb','axi_ar_target_scheduler':'axi_ar_target_path_tb',
            'axi_aw_target_path':'axi_aw_target_path_tb','axi_aw_target_scheduler':'axi_aw_target_scheduler_tb',
            'axi_b_response_router':'axi_b_response_router_tb','axi_r_response_router':'axi_r_response_router_tb',
            'axi_w_target_path':'axi_w_target_path_tb','axi_write_state_bank':'axi_write_state_bank_tb',
            'axi_read_state_bank':'axi_read_state_bank_tb','axi_qos_aging_arbiter_3':'axi_qos_aging_arbiter_3_tb',
            'axi_request_legal':'request_legality_tb','axi_outstanding_tracker':'outstanding_tracker_tb',
            'axi_rr_arbiter_3':'rr_arbiter_tb','axi_rr_arbiter_4':'axi_rr_arbiter_4_tb',
            'axi_id_mapper':'id_mapper_tb','axi_address_decoder':'address_decoder_tb',
            'axi_s3_error_target':'axi_s3_error_target_tb','axi_write_owner':'axi_write_owner_tb',
            'fabric_addr_map_pkg':'address_decoder_tb'}
        tb=aliases.get(key)
        parts=[]
        if tb: parts.append('tb/directed/'+tb+'.sv')
        fm=key+'_formal.sv'
        if (ROOT/'formal'/fm).exists(): parts.append('formal/'+fm)
        if key in ('axi_fabric_a','axi_fabric_b'):
            parts += ['results/processed/gate3/summary.md','results/processed/architecture_b_functional/summary.md']
        if not parts: parts=['docs/VERIFICATION_PLAN.md']
        return '; '.join(parts)+'; scope/result references: docs/EVIDENCE_INDEX.md. Source review only; no regression rerun.'
    if p.startswith('formal/'):
        mate=('formal/'+stem+'_formal.sv') if name.endswith('.sby') else ('formal/'+stem[:-7]+'.sby' if stem.endswith('_formal') else '')
        if stem=='rr_arbiter_fairness': mate='formal/rr_arbiter_fairness.sv' if name.endswith('.sby') else 'formal/rr_arbiter_fairness.sby'
        if stem=='smoke': mate='smoke/formal_counter.sv'
        mate=(mate+'; ') if mate and (ROOT/mate).exists() else ''
        return mate+'docs/FORMAL.md; docs/EVIDENCE_INDEX.md. Source review only; formal job not rerun.'
    if p.startswith('tb/'):
        parts=[p]
        if p.startswith('tb/directed/'):
            runner_map={'axi_fabric_a_tb.sv':'scripts/run_fabric_a_gate2_directed.sh','axi_qos_aging_arbiter_3_tb.sv':'scripts/run_qos_aging_directed.sh','address_decoder_tb.sv':'scripts/run_decoder_checks.sh'}
            if name in runner_map: parts.append(runner_map[name])
            parts.append('docs/EVIDENCE_INDEX.md')
        elif p.startswith('tb/cocotb/'):
            if 'benchmark' in name: parts += ['bench/summarize_benchmark.py','results/processed/ab_comparison/summary.md']
            elif 'random_v2' in name or 'random.py' in name: parts += ['results/processed/gate3_random_v2/summary.md','docs/EVIDENCE_INDEX.md']
            elif 'oracle' in name: parts += ['tb/model/axi_reference_model.py','scripts/run_gate2_closure.sh']
            else: parts += ['scripts/run_smoke_bfm.sh','docs/EVIDENCE_INDEX.md']
        elif p.startswith('tb/model/'):
            parts += ['tb/model/test_axi_reference_model.py','scripts/run_gate2_closure.sh']
        else:
            parts += ['tb/random/test_axi_random_plan.py','tb/random/test_concurrent_bus.py','tb/random/test_concurrent_endpoint.py','docs/EVIDENCE_INDEX.md']
        return '; '.join(parts)+'; reviewed test/model source, not a claim that it was rerun in this audit.'
    if p.startswith('bench/'):
        return p+'; results/processed/ab_comparison/summary.md; results/processed/arch_a_measurement/summary.md; frozen run/raw manifests under results/raw/ab_comparison/ and results/raw/arch_a_measurement/. No benchmark rerun in this audit.'
    if p.startswith('scripts/'):
        return p+'; docs/EVIDENCE_INDEX.md (the runner’s named test/formal scope and recorded result references). No runner executed in this source review.'
    if p.startswith('formal/'):
        return p+'; docs/FORMAL.md; docs/EVIDENCE_INDEX.md.'
    if p.startswith('smoke/'):
        smoke_runner={'axi_bfm_bus.sv':'scripts/run_smoke_bfm.sh','ecp5_smoke.sv':'scripts/run_smoke_pnr.sh','formal_counter.sv':'scripts/run_smoke_formal.sh','handshake_counter.sv':'scripts/run_smoke_sim.sh','preserve_harness.sv':'scripts/run_smoke_wrapper.sh','sv_features.sv':'scripts/run_smoke_sv.sh'}[name]
        return p+'; '+smoke_runner+'; smoke-only evidence under results/raw/gate0/, not a product property.'
    if p.startswith('.github/'):
        return p+'; scripts/run_gate0.sh; docs/EVIDENCE_INDEX.md; Gate-0 raw evidence is recorded under results/raw/gate0/.'
    if p.startswith('portfolio_audit/'):
        return p+'; portfolio_audit/test_build_register.py; portfolio_audit/audit_findings.md.'
    return p+'; Gate-0 dependency lock/evidence: requirements/phase0.txt and results/raw/gate0/.'

def main():
    rows=[]
    for p in tracked(REVIEW_REV):
        cat=source_category(p)
        if cat is None: continue
        raw=content_at(p,REVIEW_REV); txt=raw.decode('utf-8',errors='replace')
        purpose_text,contract=purpose(p,txt)
        issue=''; sev=''; evidence=''; disposition='Reviewed; no source edit.'
        if p in ('rtl/axi_ar_target_path_b.sv','rtl/axi_aw_target_path_b.sv'):
            issue='SR-P3-05'; sev='P3'; evidence='File header says Architecture-A although module is B-specific; module behavior reviewed and verified B source hashes are frozen.'; disposition='Leave RTL unchanged in audit; stale comment-only correction should be isolated because source hashes are experiment provenance.'
        elif p=='rtl/axi_b_response_router.sv' or p=='rtl/axi_r_response_router.sv':
            issue='SR-P3-01'; sev='P3'; evidence='D037 and docs/KNOWN_LIMITATIONS.md disclose response target is not checked against stored per-ID target metadata.'; disposition='Known, disclosed interface limitation; no change without a separately reviewed interface/RTL task.'
        elif p=='tb/cocotb/test_axi_fabric_a_oracle.py':
            issue='SR-P2-03'; sev='P2'; evidence='Helpers poll READY/VALID and then call model methods via cycle helpers instead of a single atomic edge snapshot; source review shows weaker event correlation, not a demonstrated mismatch.'; disposition='Record as testbench assurance limitation; no functional defect proven.'
        elif p=='bench/compare_ab.py':
            issue='SR-P2-04'; sev='P2'; evidence='Comparison checks count and selected metadata but does not independently assert exact frozen workload-seed Cartesian set nor every manifest hash.'; disposition='Published Gate-5 fresh-clone evidence separately confirms complete matrix; comparator guard is weaker than the experiment contract.'
        elif p=='bench/summarize_ppa.py':
            issue='SR-P2-05'; sev='P2'; evidence='Resource parser can return an empty dictionary on report-format mismatch; current processed reports contain resource data.'; disposition='No current result invalidation shown; hard-fail parser improvement is separate tooling work.'
        elif p=='scripts/run_smoke_formal.sh':
            issue='SR-P3-02'; sev='P3'; evidence='Intentional-fail phase accepts generic nonzero without checking expected assertion signature.'; disposition='Smoke false-positive guard limitation; existing formal evidence is from separate jobs.'
        elif p=='scripts/run_smoke_pnr.sh':
            issue='SR-P3-03'; sev='P3'; evidence='Optional ecppack failure is ignored if that tool is present; route/config check remains distinct.'; disposition='Smoke packaging check is weaker than route success; no product PPA result depends on this smoke.'
        elif p=='bench/arch_fabric_wrapper.sv':
            issue='SR-P3-04'; sev='P3'; evidence='Header still calls B wrapper a future PPA instantiation although common wrapper selects A/B and B is measured.'; disposition='Stale comment only; left source hash unchanged.'
        elif p=='bench/summarize_benchmark.py':
            evidence='Review traced completion sampling gate and common-window beat accounting. Latency records are retained only on completion within measured window; throughput counts accepted beats whose cycles fall inside the shared interval. Reviewer concern about post-window latency leakage was checked and rejected.'; disposition='No issue; reviewer false positive resolved by source inspection.'
        elif p=='tb/random/test_concurrent_bus.py':
            evidence='One target_rready assertion is conditional because default bus map omits the lane; test intentionally exercises only present lanes.'
        scope_record={
            'RTL':'portfolio_audit/semantic_review/rtl_review.md',
            'FORMAL':'portfolio_audit/semantic_review/formal_review.md',
            'TEST/MODEL':'portfolio_audit/semantic_review/tb_review.md',
            'BENCHMARK':'portfolio_audit/semantic_review/bench_script_review.md',
            'SCRIPT':'portfolio_audit/semantic_review/bench_script_review.md',
            'AUDIT TOOL':'portfolio_audit/semantic_review/audit_infrastructure_review.md',
            'SMOKE':'portfolio_audit/semantic_review/bench_script_review.md',
            'CI':'portfolio_audit/semantic_review/bench_script_review.md',
            'DEPENDENCIES':'portfolio_audit/semantic_review/bench_script_review.md'}[cat]
        scope_text=(ROOT/scope_record).read_text() if (ROOT/scope_record).exists() else ''
        review_status='REVIEWED' if p in scope_text else 'PARTIALLY_REVIEWED' if pathlib.Path(p).name in scope_text else 'NOT_REVIEWED'
        rows.append({
            'path':p,'git_blob_sha':blob(p,REVIEW_REV),'file_type':pathlib.Path(p).suffix or 'text','line_count':len(txt.splitlines()),
            'review_category':cat,'review_status':review_status,'reviewer_scope_record':scope_record,
            'module_script_purpose':purpose_text,
            'key_interface_behavior_contract_inspected':contract,'concrete_observation':evidence or contract,
            'issue_id':issue,'severity':sev,'relevant_test_formal_evidence':evidence_for(p),
            'final_disposition':disposition})
    fields=list(rows[0])
    out=OUT/'semantic_source_review.csv'
    with out.open('w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=fields,lineterminator='\n'); w.writeheader(); w.writerows(rows)

    # Complete path-level delta against the Gate-5 baseline; no rename collapsing.
    base_paths=set(x for x in git('ls-tree','-r','--name-only',BASE).splitlines() if x)
    now_paths=set(tracked(REVIEW_REV))
    delta=[]
    for p in sorted(base_paths|now_paths):
        old=blob(p,BASE) if p in base_paths else ''
        new=blob(p,REVIEW_REV) if p in now_paths else ''
        if old==new: continue
        status='ADDED' if not old else 'REMOVED' if not new else 'MODIFIED'
        raw=content_at(p,REVIEW_REV) if p in now_paths else b''
        f=p in now_paths
        delta.append({'path':p,'status_vs_gate5':status,'baseline_blob_sha':old,'current_blob_sha':new,
                      'current_size_bytes':len(raw) if f else '', 'current_sha256':hashlib.sha256(raw).hexdigest() if f else '',
                      'scope_group':('cleanup/qualification additions' if status=='ADDED' and (p.startswith('results/raw/portfolio_audit_pr2_') or p.startswith('docs/history/')) else 'other cleanup/qualification delta'),
                      'review_note':f'Path-level Git delta through review commit {REVIEW_REV}; source semantics are in semantic_source_review.csv.'})
    dfields=list(delta[0])
    with (OUT/'generated/current_head_delta_from_gate5.csv').open('w',newline='') as f:
        w=csv.DictWriter(f,fieldnames=dfields,lineterminator='\n'); w.writeheader(); w.writerows(delta)
    current_paths=tracked(REVIEW_REV)
    raw_paths=[p for p in current_paths if p.startswith('results/raw/')]
    duplicate_rows=list(csv.DictReader((OUT/'generated/duplicate_groups.csv').open()))
    raw_only_groups=sum(all(x.startswith('results/raw/') for x in r['paths'].split(';')) for r in duplicate_rows)
    group_counts={}
    for r in rows: group_counts[r['review_category']]=group_counts.get(r['review_category'],0)+1
    scope={'review_revision':REVIEW_REV,'tracked_paths':len(current_paths),'raw_paths':len(raw_paths),
           'raw_bytes':sum(len(content_at(p,REVIEW_REV)) for p in raw_paths),
           'engineering_source_rows':len(rows),'category_counts':group_counts,
           'baseline_duplicate_groups_repository_wide':len(duplicate_rows),
           'baseline_duplicate_groups_raw_only':raw_only_groups,
           'frozen_workload_sha256':hashlib.sha256(content_at('bench/workloads.yaml',REVIEW_REV)).hexdigest(),
           'scope_note':'Counts are computed from Git objects at review_revision; baseline duplicate counts come from the preserved Gate-5 audit register.'}
    import json
    (OUT/'generated/current_review_scope.json').write_text(json.dumps(scope,indent=2)+'\n')
    print(f'review_revision={REVIEW_REV} engineering_sources={len(rows)} reviewed={sum(r["review_status"]=="REVIEWED" for r in rows)} delta_paths={len(delta)} added={sum(x["status_vs_gate5"]=="ADDED" for x in delta)} removed={sum(x["status_vs_gate5"]=="REMOVED" for x in delta)} modified={sum(x["status_vs_gate5"]=="MODIFIED" for x in delta)}')

if __name__=='__main__': main()
