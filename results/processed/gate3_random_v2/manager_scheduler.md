# Task-1B random-body manager scheduler evidence

The random-body driver now issues the selected four-read/four-write set with
one issue worker per manager, then retires reads and writes through independent
per-manager R/B monitor tasks. The Python oracle is updated from the public
handshakes, and write WLAST retirement remains separate from B completion.

Frozen functional run:

```text
bash scripts/run_gate3_random_v2.sh --seed 0xA3F30001
```

Result: PASS (`fabric_a_random_v2`, 512 random operations; seed decimal
2750611457). The saved run reported:

```text
request_response_split_max_live_reads=12
request_response_split_max_live_writes=12
random_max_live_reads=12
random_max_live_writes=12
accepted_reads=[82, 93, 85]
accepted_writes=[85, 86, 81]
```

The split-phase values are aggregate across three managers: 12 means four live
reads and four live writes per manager at the same request/response boundary.
The focused scheduler regression also passes:

```text
bash scripts/run_manager_scheduler_checks.sh
PASS manager scheduler checks
```

Evidence source: `results/raw/gate3_random_v2/seed_A3F30001/coverage.json` and
`results/raw/gate3_random_v2/seed_A3F30001/results.xml`.
