# Known Limitations

1. Gate 0 qualifies the Apple-Silicon toolchain and generic methodology; it does not qualify the project fabric.
2. Architecture-A has passed Gate 2 and Gate 3 functional verification, including five-seed long random stress and integrated service-opportunity AW/AR fairness. Its frozen W00–W13 benchmark and common-wrapper ECP5 measurement are recorded in `results/processed/arch_a_measurement/summary.md`; those results do not establish whole-Fabric exhaustive formal proof, unrestricted AXI4 compliance, general device timing signoff or Architecture-B performance.
3. The project intentionally supports only the documented AXI4 subset in `docs/REQUIREMENTS.md`.
4. The compact wrapper adds overhead. Direct Fabric synthesis and wrapped implementation counts are reported separately; A/B comparison must use the identical wrapper structure and may not estimate wrapper resources by subtraction.
5. Canonical benchmark endpoint behavior is a deterministic model, not a claim about a particular production memory or peripheral. Canonical manager BREADY/RREADY stalls were zero; target AR stalls arose from the depth-8 read queue.
6. CDC, ACE/CHI, coherency, protocol conversion, unsupported bursts and USER semantics remain outside the single-clock MVP.
7. Third-party source is not vendored. Any later imported file requires file-level SPDX/licence review and notice handling.
