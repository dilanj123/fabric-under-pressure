# Gate-3 Task 1B RDATA investigation

Status: **classified as HARNESS_ENDPOINT**. Production RTL was not changed.

## Reproduction

The exact saved plan was replayed with `scripts/run_gate3_random_v2.sh --plan <absolute path to results/raw/gate3_random_v2/plans/seed_A3F30001.json>`. It reproduced deterministically at random sequence 28:

- M1, read ID 6, target S0;
- ARADDR `0x00000740`, LEN 8, byte range `0x740..0x787`;
- reported beat 5;
- expected `0x744f2a05e0bb9671`;
- observed `0x4c2702ddb8936e49`.

The minimized active prefix is 24 anchors plus random sequences 0 through 28. It is preserved in `results/raw/gate3_rdata_investigation/minimized_plan.json`; the direct replay wrapper and result are in `run_minimized.sh` and `minimized_replay.log`.

## Boundary evidence

The endpoint presentation and actual public target inputs agree on beat 5. The manager receives the previous beat:

| logical beat | address | endpoint / target RDATA | manager RDATA |
|---:|---:|---:|---:|
| 3 | `0x758` | `0x24ffdab5906b4621` | `0x24ffdab5906b4621` |
| 4 | `0x760` | `0x4c2702ddb8936e49` | `0x4c2702ddb8936e49` |
| 5 | `0x768` | `0x744f2a05e0bb9671` | `0x4c2702ddb8936e49` |
| 6 | `0x770` | not reached after checker failure | not reached |

The decisive detail is manager R backpressure. The plan sets `manager_r_stall=3` for this read. The helper presents the next target beat and samples `target_rready` before combinational settling. It then waits one clock and clears `target_rvalid` without proving `target_rvalid && target_rready` occurred on that edge. The trace shows beat 5 presented with a stale sampled ready value of 1, followed by ready=0 after the edge, while the manager slot still holds beat 4. The endpoint worker therefore drops beat 5 at the target boundary; the manager later observes the held previous beat. This is a target-endpoint driver/handshake-accounting defect.

## Ownership audit

`test_axi_fabric_a_random_v2.py` has one worker per manager, but each worker calls the serial Gate-2 `mapped_read()`/`mapped_write()` helpers. Those helpers simultaneously drive manager request/READY lanes and target response VALID/payload lanes. There are no independent endpoint workers consuming actual target AW/AR/W handshakes. `target_locks` serialize helpers targeting S0-S2, but they do not replace channel ownership or handshake-aware endpoint queues.

The helper-owned channels are:

- manager AW/W/AR VALID and payload: the manager worker for that manager;
- manager BREADY/RREADY: the same transaction helper;
- target AWREADY/WREADY/ARREADY: setup/global values, with no v2 per-channel scheduler;
- target BVALID/BID/BRESP and RVALID/RID/RDATA/RRESP/RLAST: the active Gate-2 transaction helper;
- public target handshakes and manager responses: observed by that same helper.

`set_lane()` performs packed read/modify/write operations. Different manager workers can write different lanes in one simulation timestamp, so this is also a race risk. More fundamentally, Gate-2 helpers are not safe endpoint models when concurrent manager workers are active.

## Address and reference-memory audit

The failing read has no overlapping write in the saved plan; `results/raw/gate3_rdata_investigation/address_overlap.txt` reports `overlap_count=0`. The oracle and endpoint memory values therefore are not ambiguous due to read-during-write ordering. The failure occurs before the oracle consumes beat 5, at the endpoint/target handshake boundary.

## Classification

**HARNESS_ENDPOINT**. The endpoint helper clears a target response without an actual target handshake under manager backpressure. The manager-side repeated word is a consequence of the endpoint worker violating target VALID/READY ownership/accounting. This evidence does not establish a production RTL defect.

## Recommended repair

Replace helper-driven concurrent response presentation with a verification-only endpoint architecture:

1. one manager coroutine owns each manager AW/W/AR request lane and BREADY/RREADY lane;
2. one endpoint worker owns each target's AWREADY/WREADY/ARREADY and B/R response lanes;
3. endpoint workers enqueue actual target AW/AR/W handshakes and generate responses only from queued handshakes;
4. a response remains VALID and payload-stable until the actual target or manager handshake is observed;
5. monitors feed the independent oracle from public handshakes only;
6. `set_lane()` writes are centralized or protected so no two coroutines perform packed RMW on the same signal in one timestamp;
7. S0/S1 read data should use disjoint random live address windows for stress, or snapshot reference data at actual target AR acceptance and retain it through the burst. This is a verification policy, not a Fabric memory-consistency requirement.

No production RTL repair is recommended from this investigation.
