# Task-1B request/response scheduler repair

The repair is verification-harness-only; production RTL and existing raw evidence are unchanged.

## Root cause

The request/response split still used serial Gate-2 response helpers. Those helpers regenerated mapped read data instead of retaining data sampled at target AR admission, and each response coroutine assumed its own completion order. Concurrent W issue also left target WREADY high while the registered W slot was being observed, allowing the target handshake to be consumed before the helper accounted for it.

The repaired path snapshots mapped read data at the actual target AR handshake, updates endpoint memory only at actual target W handshakes, holds target WREADY low until the registered slot is sampled, and separates target response drivers from one manager-direction monitor. The monitor retires only the public RID/BID associated with the live `(epoch, manager, ID)` record.

## Verification

Focused command:

```text
bash scripts/run_manager_scheduler_checks.sh
exit 0
```

Frozen matrix command:

```text
bash scripts/run_gate3_random_v2.sh
exit 0
```

All five seeds passed: `0xA3F30001`, `0xA3F30002`, `0xA3F30003`, `0xA3F30004`, and `0xA3F30005`. The two independent reproducers now pass: the former A3F30002 bad-RDATA failure and the former A3F30003 target-W-valid failure.

Depth evidence from the final matrix: global maximum live reads `12`, global maximum live writes `12`; equivalently `4/4` reads and `4/4` writes per manager. Aggregate coverage also records target AW/AR/W stalls, manager B/R stalls, and response delays.
