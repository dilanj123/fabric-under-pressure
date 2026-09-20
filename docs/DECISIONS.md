# Decision Log

| ID | Decision | State | Rationale/evidence class |
|---|---|---|---|
| D001 | Use ARM IHI 0022H.c / ID012621 / 26 Jan 2021 as normative AXI4 source. | FROZEN | SPEC; later Issue J removed AXI4 content. |
| D002 | Claim a documented AXI4 subset, not unrestricted AXI4 compliance. | FROZEN | PLAN; matches explicit exclusions. |
| D003 | Freeze 3 managers, 4 logical targets, 64-bit data, 32-bit address, 4-bit manager IDs. | FROZEN | PLAN; portfolio scope and manageable complexity. |
| D004 | Support aligned 64-bit INCR bursts only, 1–16 beats, no 4-KiB crossing; WSTRB allowed. | FROZEN | SPEC+PLAN. |
| D005 | Allow 4 read + 4 write outstanding per manager, but one outstanding per ID/direction. | FROZEN | PLAN; genuine concurrency without reorder buffer. |
| D006 | Widen downstream ID to 6 bits by prefixing 2-bit manager index. | FROZEN | SPEC+PLAN; simple return routing. |
| D007 | Route W only from registered accepted-AW context through WLAST; never assume AW/W coupling. | FROZEN | SPEC+PLAN. |
| D008 | MVP reset is coordinated system reset; pre-reset transactions are abandoned/scoreboards flushed. | FROZEN | PLAN consistent with AXI interface reset requirements. |
| D009 | Architecture A is per-target AW/AR round-robin; held grant under backpressure. | FROZEN | PLAN; simplest complete baseline. |
| D010 | Architecture B uses 4-bit AxQOS, 8-bit saturating age, threshold 64 and starved-set RR escape. | FROZEN | PLAN; deterministic policy suitable for formal/measurement. |
| D011 | Freeze workloads W00–W13 and seeds FABC0001…FABC0005 before B results. | FROZEN | PLAN; benchmark integrity. |
| D012 | Use common compact wrapper and LFE5U-45F/CABGA381/-6 for open PPA comparison. | CONDITIONAL | PLAN; wrapper still requires Gate-0 validation. |
| D013 | Complete a single-clock MVP before any per-channel CDC bridge extension. | FROZEN | PLAN; scope/risk control. |
| D014 | Preferred EDA bundle candidate is OSS CAD Suite darwin-arm64 release 2026-09-20, asset `oss-cad-suite-darwin-arm64-20260920.tgz`, SHA-256 `3af61f750c8040bcdfe317ba6134f93e391d65dc27e6bf39ef56455e48c723ae`. | CANDIDATE | UPSTREAM; must be downloaded and version-smoked on intended Mac before becoming local evidence. |
| D015 | Phase-0 SV style will prefer packages/packed structs/arrays/generate/always_ff/always_comb/functions; SV interfaces/modports are optional and accepted only if all chosen frontends agree. | OPEN TEST | Requires local sim/synth/formal smoke. |
