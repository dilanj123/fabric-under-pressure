# Gate-0 tool/version record

## Intended host candidate
- Host: macOS on Apple Silicon (`arm64`) — **not yet executed**.
- Preferred EDA bundle: OSS CAD Suite `2026-09-20` darwin-arm64.
- Asset: `oss-cad-suite-darwin-arm64-20260920.tgz`.
- SHA-256: `3af61f750c8040bcdfe317ba6134f93e391d65dc27e6bf39ef56455e48c723ae`.
- Release page: https://github.com/YosysHQ/oss-cad-suite-build/releases/tag/2026-09-20

## Python candidate pins
See `requirements/phase0.txt`. These are candidate reproducibility pins until installed and smoked on the intended host.

## Current ChatGPT execution host
`Linux x86_64`; Python 3.13.5; pip 25.1.1; git 2.47.3. Verilator, Yosys, SBY, nextpnr-ecp5, ecppack and Slang are absent. This is environment evidence only and does not qualify the intended Apple-Silicon flow.
