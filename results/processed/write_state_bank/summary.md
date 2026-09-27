# Shared per-manager write-state integration

## Scope

This evidence covers `rtl/axi_write_state_bank.sv`: three shared per-manager
write outstanding trackers and three per-manager unfinished-W owners. The bank
is driven by manager-facing AW admission events. The focused composition adds
one `axi_aw_target_path_a` for target S0 and feeds its admission/status signals
through the shared bank. No W payload routing, B routing, AR/R path, S3
endpoint or four-target Fabric is included.

## Commands and environment

The complete check was run with:

```text
source /Users/Dilan/eda/fabric-under-pressure/oss-cad-suite/environment
scripts/run_write_state_bank_checks.sh
```

Material tool versions:

```text
Verilator 5.053 devel rev v5.052-119-g014c9820d (mod)
Yosys 0.69+75 (git sha1 f0b945f63-dirty, Release)
SBY v0.69
Solver: Yices via yosys-smtbmc
```

The raw driver log is `results/raw/write_state_bank/full_run.log`.

## Simulation

- `axi_write_state_bank_tb`: exit 0, 24 self-checking checks.
- `axi_aw_write_state_composition_tb`: exit 0, 8 self-checking checks.

The checks cover atomic allocation, target AW stall and non-allocation on
target consumption, WLAST/B separation, same-ID blocking before B, different
ID admission after WLAST, four outstanding writes, fifth-write blocking,
same-cycle completion credit policy, invalid direct admission, manager
independence and reset.

Classification: **RTL SIMULATION VERIFIED**, limited to these standalone and
one-target composition scopes.

## Formal

Bank prove:

```text
formal/axi_write_state_bank.sby prove
engine: smtbmc
solver: Yices
mode: bounded BMC
depth: 12
result: PASS
log: results/raw/write_state_bank/formal_bank_prove/logfile.txt
```

The bank harness assumes completion events refer to pre-existing state and
keeps reset asserted for the initial two cycles. It proves the count bound and
defensive invalid-admission gating, with covers for counts 0 through 4,
invalid admissions, populated owner state, all three managers and B/owner
lifetime cases.

Composition prove:

```text
formal/axi_aw_write_state_composition.sby prove
engine: smtbmc
solver: Yices
mode: bounded BMC
depth: 24
result: PASS
log: results/raw/write_state_bank/formal_comp_prove/logfile.txt
```

The composition harness assumes AXI source VALID/payload and relevant request
facts remain stable while an AW is stalled, and that W/B events refer to
pre-existing state. It proves one-hot AW fire, admission conservation,
admission safety, target-side consumption non-allocation and reset safety.

Composition cover uses depth 32 and reaches M0/M1/M2 admissions, stalled and
consumed target AW, following-cycle admission and owner/outstanding lifetime
states. Logs are in `results/raw/write_state_bank/formal_comp_cover/logfile.txt`.

These are bounded results, not unbounded whole-Fabric proofs. Exact metadata
capture and W beat accounting are directly checked by the directed suites and
the already-qualified standalone owner/tracker evidence.

## Synthesis

Exact production command:

```text
yosys -Q -p "read_verilog -sv rtl/axi_outstanding_tracker.sv rtl/axi_write_owner.sv rtl/axi_write_state_bank.sv; synth_ecp5 -top axi_write_state_bank -json results/raw/write_state_bank/axi_write_state_bank_ecp5.json; stat"
```

Exit 0; Yosys check reported 0 problems. Primitive/composition statistics:

```text
LUT4       706
TRELLIS_FF 117
CCU2C       39
PFUMX      225
L6MUX21    147
EBR/DSP      none reported
```

Warnings reviewed: one experimental `write_xaiger2` feature warning and ABC
box/fanout/network informational warnings; no synthesis error or Yosys check
problem. These figures are not Fabric PPA.

## Limitations

The shared bank is not connected to a four-target top-level Fabric. Production
W routing, manager WREADY, target WVALID/WREADY, B completion routing, AR/R,
S3 response behavior, Architecture B, end-to-end AXI behavior and performance
remain unproven.
