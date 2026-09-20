# Trade-offs Register

| Topic | Frozen baseline | Benefit | Cost/risk | Revisit trigger |
|---|---|---|---|---|
| one outstanding per ID | yes | avoids baseline reorder buffer while retaining multi-ID outstanding traffic | less concurrency for repeated same ID | measured bottleneck or explicit experiment |
| manager-index ID widening | 4 -> 6 bits | simple return routing/global uniqueness downstream | wider internal ID buses | only if PPA evidence shows meaningful cost |
| burst max | 16 beats | enough DMA pressure with bounded state/test complexity | not maximum AXI4 burst capability | post-public extension |
| scheduler B | QoS + starvation escape | tests tail-latency/fairness policy | counters/comparison timing/area | measured A/B results |
| single-clock MVP | yes | isolates interconnect correctness/performance | CDC not initially demonstrated | after core fabric trusted |
| open ECP5 target | yes | reproducible public PPA path | not ASIC-correlated | optional later vendor/ASIC flow |
