# Known Limitations

1. Gate 0 qualifies the Apple-Silicon toolchain and generic methodology; it does not qualify the project fabric.
2. Architectures A and B each completed the matched W00–W13 × five-seed canonical simulation matrix. B fails two frozen D045 criteria; details are in `results/processed/ab_comparison/summary.md`. These measurements do not establish whole-Fabric exhaustive formal proof, unrestricted AXI4 compliance or general device timing signoff.
3. The project intentionally supports only the documented AXI4 subset in `docs/REQUIREMENTS.md`.
4. The compact wrapper adds overhead. Direct Fabric synthesis and wrapped implementation counts are reported separately; A/B comparison must use the identical wrapper structure and may not estimate wrapper resources by subtraction.
5. Canonical benchmark endpoint behavior is a deterministic model, not a claim about a particular production memory or peripheral. Canonical manager BREADY/RREADY stalls were zero; target AR stalls arose from the depth-8 read queue.
6. Architecture-B's QoS/aging policy was not tuned after measurement. It improves W08 M2 read admission but materially reduces M1 throughput and increases M0 write admission tails. D047 rejects this frozen B implementation under D045; any future variant needs a fresh controlled study.
7. CDC, ACE/CHI, coherency, protocol conversion, unsupported bursts and USER semantics remain outside the single-clock MVP.
8. The ECP5 results use one fixed internal-stimulus wrapper, five route seeds and a bounded frequency sweep. They are comparative implementation evidence, not board timing signoff or a general Fmax claim.
9. Third-party source is not vendored. Any later imported file requires file-level SPDX/licence review and notice handling.
