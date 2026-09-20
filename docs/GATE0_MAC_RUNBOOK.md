# Gate-0 Apple-Silicon Runbook

This runbook closes the remaining environment evidence on the intended macOS/Apple-Silicon host. Do not start project AXI RTL until every Gate-0 row is PASS.

## 1. Obtain the pinned candidate OSS CAD Suite

Candidate upstream release: `2026-09-20`.

```bash
mkdir -p ~/eda/fabric-under-pressure
cd ~/eda/fabric-under-pressure
curl -L -o oss-cad-suite-darwin-arm64-20260920.tgz \
  https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2026-09-20/oss-cad-suite-darwin-arm64-20260920.tgz
printf '%s  %s\n' \
  3af61f750c8040bcdfe317ba6134f93e391d65dc27e6bf39ef56455e48c723ae \
  oss-cad-suite-darwin-arm64-20260920.tgz | shasum -a 256 -c -
tar -xzf oss-cad-suite-darwin-arm64-20260920.tgz
source oss-cad-suite/environment
```

If the checksum does not match, stop. Do not substitute a newer nightly silently; create a decision entry and re-pin it.

## 2. Enter the repository and capture the host/tool versions

```bash
cd /path/to/Fabric-Under-Pressure
./scripts/check_env.sh
```

Acceptance: the raw log shows `Darwin`, machine `arm64`, and real version output for Verilator, Yosys, SBY, nextpnr-ecp5 and Trellis/ecppack where exposed.

## 3. Create the repository Python environment

```bash
./scripts/bootstrap_python.sh
source .venv/bin/activate
python --version
pip freeze
```

If the candidate Python pins fail, record the exact resolver/import error and make the smallest compatibility change. Do not change the AXI architecture to solve a Python-package issue.

## 4. Run Gate-0 smokes

```bash
./scripts/run_smoke_sv.sh
./scripts/run_smoke_sim.sh
./scripts/run_smoke_bfm.sh
./scripts/run_smoke_formal.sh
./scripts/run_smoke_synth.sh
./scripts/run_smoke_pnr.sh
./scripts/run_smoke_wrapper.sh
```

Or run the combined driver:

```bash
./scripts/run_gate0.sh 2>&1 | tee results/raw/gate0/mac_gate0_driver.log
```

## 5. Review before declaring PASS

Confirm all of the following:

- SV feature smoke parses/elaborates in the intended frontends.
- cocotb counter test has a machine-readable PASS result.
- cocotbext-axi performs aligned 64-bit write/read, a 4-beat INCR transfer, explicit IDs, and deterministic backpressure.
- formal `prove` and `cover` pass, while the intentionally failing task is detected as a failure.
- Yosys emits an ECP5 JSON/netlist and non-empty resource statistics.
- nextpnr targets `LFE5U-45F`, `CABGA381`, speed grade `6`, seed `1`, and emits a routed config.
- the compact wrapper remains non-empty after synthesis; inspect the Yosys `stat` output rather than relying only on the JSON-file existence check.

## 6. Evidence update

After successful runs, update:

- `results/processed/gate0/tool_versions.md` with actual Mac versions;
- `results/processed/gate0/summary.md` from OPEN to PASS for each evidenced row;
- `docs/EVIDENCE_INDEX.md`;
- `docs/DECISIONS.md` if the coding subset or package pin changed;
- `docs/PROJECT_STATE.md` to Gate 0 PASS only when every acceptance item is satisfied.

Then create the first `KNOWN_GOOD` Gate-0 commit/tag (`kg-g0-env`).
