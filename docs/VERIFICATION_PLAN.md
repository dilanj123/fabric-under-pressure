# Verification Plan

**Status:** Gate-1 skeleton; no AXI verification has run.

## Independent checking
A project-owned Python transaction/reference model records manager, target, ID, address, length, size, data/strobes, acceptance cycle, expected route and expected response. It models the architectural contract, not RTL internals.

## Required detection
Loss, duplication, misrouting, bad ID, bad data, bad RESP, bad LAST, ordering violations and stale responses after reset.

## Directed suites
1. primitive/decoder tests;
2. AW/W decoupling including W presented before matching AW is accepted;
3. B path and backpressure;
4. AR/R path and backpressure;
5. 1–16 beat INCR bursts and 4-KiB boundary rejection/generation discipline;
6. multiple distinct IDs and legal out-of-order completion;
7. simultaneous managers/targets;
8. random subordinate response latency;
9. every channel backpressured;
10. default/error target;
11. idle reset and reset with partially accepted traffic;
12. long randomized contention;
13. adversarial fairness/starvation;
14. architecture A/B against identical frozen workload vectors.

## Regression rule
Every discovered functional bug gains a regression test before the fix is considered complete.

## Phase-0 note
`cocotbext-axi` may be used as verification-only stimulus after the compatibility smoke passes; it is never the sole oracle.
