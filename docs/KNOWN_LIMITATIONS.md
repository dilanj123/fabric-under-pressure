# Known Limitations

1. Gate 0 is open; intended Apple-Silicon EDA flow is not yet locally qualified.
2. Current ChatGPT execution environment is Linux/x86_64 and cannot substitute for the intended Mac qualification.
3. External package/network access is unavailable in this container, preventing installation of cocotb/EDA binaries here.
4. No project AXI RTL exists yet.
5. No simulation, formal, synthesis, P&R or benchmark result exists for the project fabric.
6. The project intentionally supports only the documented AXI4 subset in `docs/REQUIREMENTS.md`.
7. Compact P&R wrapper methodology is provisional until preservation is demonstrated with Yosys/nextpnr evidence.
8. Third-party source is not vendored. Any later imported file requires file-level SPDX/licence review and notice handling.
