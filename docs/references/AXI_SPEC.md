# AXI protocol source register

## Normative AXI4 source

- **Title:** AMBA AXI and ACE Protocol Specification
- **Document:** ARM IHI 0022H.c
- **ID:** ID012621
- **Date:** 26 January 2021
- **Canonical selector:** https://developer.arm.com/documentation/ihi0022/hc
- **Project status:** normative authority for AXI4 semantics.

Later Issue J removed AXI3/AXI4/AXI4-Lite content from the consolidated specification. Issue L is useful current-family/version-history context, but is not the normative AXI4 semantic source for this project.

Do not commit or redistribute the Arm PDF unless redistribution rights are explicitly checked. Store only metadata, links and project-authored notes.

## Required H.c locations to cite during Gate 1

| Topic | H.c location | Project use |
|---|---|---|
| clock/reset | A3.1, especially A3.1.1–A3.1.2 | ACLK/ARESETn behaviour |
| common VALID/READY handshake and channel independence | A3.2, especially A3.2.1–A3.2.2 | hold VALID/payload stable until handshake; each channel has its own handshake |
| write-address/write-data dependencies | A3.3 / transaction dependency rules plus A5.2.2 write-data ordering | do not assume AW and W arrive together; AXI4 has no WID |
| burst address/length/size and 4-KiB boundary | A3.4, especially address structure/burst rules | INCR-only, 1–16 beat, aligned 64-bit subset; no burst crosses 4 KiB |
| responses | A3.4.5 | OKAY/SLVERR/DECERR; whole write burst has one BRESP |
| IDs | A5.1–A5.2 | multiple outstanding transactions and response IDs |
| write-data ordering and interconnect ID widening | A5.2.2–A5.2.3 | no AXI4 WID; append manager index downstream |
| ordering | Chapter A6, especially A6.1 and A6.6 | same-ID ordering requirements and interconnect obligations |
| QoS | A8.1.1–A8.1.3 | AWQOS/ARQOS are 4-bit; higher recommended priority; protocol does not mandate scheduler |

## Frozen interpretation discipline

Where the project intentionally supports less than full AXI4, it documents the restriction at the manager-facing contract and rejects/does not generate unsupported requests. It must not claim unrestricted AXI4 compliance.
