# Third-Party Manifest

Snapshot date: **2026-09-20**. SHAs below are observed public default-branch snapshots used for reference qualification, not vendored dependencies.

| Project | Repository | Observed SHA | Licence observation | Role | Copied? |
|---|---|---|---|---|---|
| PULP AXI | https://github.com/pulp-platform/axi | `70b8e54fd460e3308e58be596ceb3566a6e3576e` | repository LICENSE is Solderpad Hardware License v0.51 / SHL-0.51 | reference-only for core fabric | no |
| common_cells | https://github.com/pulp-platform/common_cells | `e73baaec2ca665cd80c3c384e9258e35242b829c` | repository LICENSE SHL-0.51; individual files must still be checked | reference-only; possible later generic CDC primitive by explicit decision | no |
| iDMA | https://github.com/pulp-platform/iDMA | `2e0b0fe53b6f8823319e2428e2e9abc2db149b7d` | repository LICENSE SHL-0.51 | workload/DMA prior art | no |
| FlooNoC | https://github.com/pulp-platform/FlooNoC | `c58f1bf13baeda147b4e87e961683d389db090a1` | observed HW files identify SHL-0.51; Python/floogen files observed Apache-2.0 | architecture-C prior art only | no |
| wb2axip | https://github.com/ZipCPU/wb2axip | `2e8d3bc2d26ddc33d1881022a2a2b9d3f0c16b9b` | source headers observed Apache License 2.0 | formal-method prior art | no |
| cocotbext-axi | https://github.com/alexforencich/cocotbext-axi | `264319c17f0869e4d0efb15ad0e6d74e3bef453c` | MIT LICENSE observed | candidate verification-only dependency, intended package pin 0.1.28 | no; package install pending |

## Policy
Core routing, arbitration, QoS/aging, outstanding tracking, reference model and architecture comparison remain original. A future imported file must add exact file path, exact source ref, SPDX/licence, modification status and required notice here before merge.
