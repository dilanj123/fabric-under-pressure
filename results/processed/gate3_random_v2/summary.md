# Gate-3 Task 1B — randomized qualification repair

Status: **OPEN**.

The initial Task-1 matrix is retained as historical evidence: its 96-operation forced prefix exhausted the plan, so manager/direction/target/LEN were not seeded by the random branch; operations were completed serially; and the 10,000-cycle interval was post-drain idle time. Task 1B now generates 24 explicit deterministic anchors plus 512 genuinely seeded random operations per frozen seed, with seed-diversity and legal-plan checks before simulation.

The repaired prototype has independent manager workers and separates anchor counters from random-body counters. The forensic result led to D041 and handshake-driven endpoint/shadow-bus support in `tb/random/concurrent_endpoint.py`, `tb/random/concurrent_bus.py` and the DUT-facing v2 driver; their nine pure-Python unit checks pass. The exact minimized DUT plan now passes through the handshake-safe endpoint path, and the focused DUT RVALID-retention regression passes. The former full-run AR timeout was traced to an illegal generated S1 burst start (`0x10000fc0`, LEN 13), which crossed the 4 KiB boundary; the plan allocator now uses a 30-slot layout and prechecks every generated request with the independent legality model. A concurrent packed-lane shadow fix also removed cross-manager AWVALID overwrites. The request/response scheduler repair now snapshots target-AR data, accounts for target-W handshakes with registered READY ownership, and retires live responses from public RID/BID handshakes. The concurrent endpoint path applies finite target AW/AR/W pauses and all five 512-operation seeds complete and pass their per-seed DUT/oracle runs. Final random live depth is 12 reads and 12 writes globally, i.e. 4/4 per manager. No RTL change has been made.

## Implemented checks

- same-seed plan identity and different-seed plan diversity;
- 24-anchor / 512-random-operation separation;
- random IDs, targets, lengths, QoS, WSTRB vectors and launch cycles;
- plan replay input and legal-field validation;
- independent manager-worker execution prototype;
- cycle advancement once per simulation timestamp in the shared oracle helper.
- handshake-driven R/B endpoint primitives with stable payload retention;
- central shadow-bus packing primitives with unit coverage;
- minimized DUT replay PASS and focused DUT RVALID-retention PASS.
- independent generated-plan legality checking, including 4 KiB burst containment;
- five frozen-seed per-seed runs PASS after the AR and packed-lane repairs;
- finite target AW/AR/W pauses are observed on public target handshakes: aggregate AW 251 episodes, AR 249 episodes, W 44 episodes;
- Gate-2 closure regression PASS after the harness/model changes.

## Still unearned

The request and response phases are now separate for the selected four-read/four-write live set per manager. A planned AW pause remains deferred for `w_before_aw` operations in the compatibility path because applying it before the W-before-AW context is established can deadlock manager W admission; other write styles exercise target AW pauses. Reset-with-live-work, contention and reorder counters remain unimplemented in this v2 execution path.

Raw reproducer: `results/raw/gate3_random_v2/repaired/ar_deadlock_investigation.jsonl`. The repaired minimized replay is under `results/raw/gate3_random_v2/minimized_repaired_final/`; per-seed runs are under `results/raw/gate3_random_v2/seed_A3F30001` through `seed_A3F30005`, with aggregate observed coverage in `results/raw/gate3_random_v2/aggregate_coverage.json`. The old Task-1 artifacts under `results/raw/gate3_random/` and the original forensic artifacts under `results/raw/gate3_rdata_investigation/` remain unchanged.
