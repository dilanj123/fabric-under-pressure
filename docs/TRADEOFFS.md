# Trade-offs Register

| Topic | Frozen baseline | Benefit | Cost/risk | Revisit trigger |
|---|---|---|---|---|
| one outstanding per ID | yes | avoids baseline reorder buffer while retaining multi-ID outstanding traffic | less concurrency for repeated same ID | measured bottleneck or explicit experiment |
| manager-index ID widening | 4 -> 6 bits | simple return routing/global uniqueness downstream | wider internal ID buses | only if PPA evidence shows meaningful cost |
| burst max | 16 beats | enough DMA pressure with bounded state/test complexity | not maximum AXI4 burst capability | post-public extension |
| scheduler B | Frozen QoS + age-64 RR escape; D047 rejects this measured variant under D045 | W08 M2 read-admission P99 improves; W12 Jain remains near 1 | W08 M1 throughput and M0 write-tail criteria fail; resource use rises and all-seed timing-clean target falls 5 MHz | A different scheduler is a new controlled experiment with fresh functional verification |
| single-clock MVP | yes | isolates interconnect correctness/performance | CDC not initially demonstrated | after core fabric trusted |
| open ECP5 target | yes | reproducible public PPA path | not ASIC-correlated | optional later vendor/ASIC flow |
