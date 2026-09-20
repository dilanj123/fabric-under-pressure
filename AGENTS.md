# AGENTS.md — stable repository behaviour

1. Read authority in this order: `00_MASTER_PROJECT_PLAN.md`, `01_CHATGPT_PROJECT_OPERATING_INSTRUCTIONS.md`, `docs/REQUIREMENTS.md`, `docs/MICROARCHITECTURE.md`, `docs/VERIFICATION_PLAN.md`, `docs/FORMAL.md`, `docs/DECISIONS.md`, `docs/PROJECT_STATE.md`, `docs/EVIDENCE_INDEX.md`, then implementation/test/build files.
2. Do not claim functional correctness, formal proof, timing closure, Fmax, resources, throughput, P99 latency or fairness improvement without matching tool evidence.
3. Core fabric routing/arbitration/QoS/outstanding tracking/reference model remain original unless an explicit decision record changes that boundary.
4. Phase 0 must not implement the project fabric.
5. Every discovered functional bug later gains a regression test.
6. Architecture A/B comparison must freeze topology, widths, buffering, outstanding depth, address map, workloads, target, constraints, tools, settings and seed policy.
7. Put raw logs in `results/raw/`; put concise extracted evidence in `results/processed/`.
8. Codex/local tasks are narrow, name exact files, and define acceptance criteria.
9. Stop rather than silently weakening protocol semantics, formal assumptions, benchmark fairness or licence controls.
