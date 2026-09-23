# Known Limitations

1. Gate 0 qualifies the Apple-Silicon toolchain and generic methodology; it does not qualify the project fabric.
2. No project AXI RTL exists yet, so no project simulation, formal, synthesis, P&R, benchmark, PPA, timing, throughput or latency result exists.
3. The project intentionally supports only the documented AXI4 subset in `docs/REQUIREMENTS.md`.
4. The compact wrapper adds overhead; absolute resource results must separate wrapper contribution and compare A/B with identical wrapper structure.
5. Canonical benchmark endpoint behavior is a deterministic model, not a claim about a particular production memory or peripheral.
6. CDC, ACE/CHI, coherency, protocol conversion, unsupported bursts and USER semantics remain outside the single-clock MVP.
7. Third-party source is not vendored. Any later imported file requires file-level SPDX/licence review and notice handling.
