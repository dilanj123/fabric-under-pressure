# Requirements

**Status:** Gate-1 specification frozen. No implementation evidence yet.

## R-001 Scope and protocol claim
The project implements a **documented AXI4 subset** and remains an interconnect/microarchitecture project, not a CPU, DMA-engine, coherent-protocol or mesh-NoC project.

## R-002 Topology
- Managers: M0 control-like, M1 DMA/bulk, M2 latency-critical accelerator.
- Logical targets: S0 SRAM A, S1 SRAM B, S2 peripheral/config, S3 default/error.

## R-003 Widths
- DATA_WIDTH=64; ADDR_WIDTH=32; manager ID width=4.
- Internal downstream ID width=6: `{manager_index[1:0], manager_id[3:0]}`; manager index `2'b11` is illegal on returned responses.

## R-004 Address map
- S0 `0x0000_0000`–`0x0000_FFFF`.
- S1 `0x1000_0000`–`0x1000_FFFF`.
- S2 `0x2000_0000`–`0x2000_0FFF`.
- S3 all other addresses, returning DECERR while completing the required burst protocol.

## R-005 Supported transaction subset
- AW/W/B and AR/R.
- INCR bursts only; 1–16 beats (`AxLEN=0..15`).
- 64-bit full-width transfer size (`AxSIZE=3`), 8-byte aligned start addresses.
- Legal WSTRB byte enables.
- IDs, RESP, LAST, AWQOS/ARQOS and backpressure on every channel.
- Supported bursts must not cross a 4-KiB boundary.

## R-005a Frozen manager-facing channel signals

The manager and logical-target ports use the following AXI4 signal bundle. Signals are repeated per port and direction; `x` denotes the manager index where applicable.

| Channel | Signals and widths | Attribute policy |
|---|---|---|
| AW | `AWID[3:0]`, `AWADDR[31:0]`, `AWLEN[7:0]`, `AWSIZE[2:0]`, `AWBURST[1:0]`, `AWLOCK`, `AWCACHE[3:0]`, `AWPROT[2:0]`, `AWQOS[3:0]`, `AWREGION[3:0]`, `AWVALID`, `AWREADY` | `AWLEN=0..15`, `AWSIZE=3`, `AWBURST=INCR`, `AWLOCK=normal`; CACHE/PROT/REGION are carried but not interpreted; QoS is used by the scheduler. |
| W | `WDATA[63:0]`, `WSTRB[7:0]`, `WLAST`, `WVALID`, `WREADY` | Full-width data with legal byte strobes; ownership comes from accepted AW and ends at accepted WLAST. |
| B | `BID[3:0]`, `BRESP[1:0]`, `BVALID`, `BREADY` | BID is the original manager ID; OKAY/SLVERR/DECERR are propagated or produced as specified. |
| AR | `ARID[3:0]`, `ARADDR[31:0]`, `ARLEN[7:0]`, `ARSIZE[2:0]`, `ARBURST[1:0]`, `ARLOCK`, `ARCACHE[3:0]`, `ARPROT[2:0]`, `ARQOS[3:0]`, `ARREGION[3:0]`, `ARVALID`, `ARREADY` | Same legality and attribute policy as AW. |
| R | `RID[3:0]`, `RDATA[63:0]`, `RRESP[1:0]`, `RLAST`, `RVALID`, `RREADY` | RID is the original manager ID; RLAST terminates the accepted burst. |

`AxUSER`, `WUSER`, `BUSER` and `RUSER` are omitted. The MVP has one `ACLK` and coordinated active-low `ARESETn`; no separate clock or reset ports are present.

## R-006 Explicit exclusions
FIXED, WRAP, narrow/unaligned transfers, exclusives, locked accesses, ATOPs, ACE/CHI/coherency and W interleaving are outside MVP.

## R-007 Outstanding transactions and ordering
- At most 4 outstanding reads and 4 outstanding writes per manager.
- At most one outstanding transaction per manager ID per direction.
- Different IDs may complete out of issue order when protocol/legal routing allows.
- Same-ID ordering must be preserved.

## R-008 Write routing
AW and W are independent. Accepted AW creates registered route/ownership context for that write. W routing follows that context through accepted WLAST. The fabric never infers W destination from current AW combinationally.

## R-009 Reset
MVP uses one clock. Reset follows AXI interface rules and is a coordinated system reset: pre-reset outstanding work is abandoned, endpoints/scoreboards flush state, and stale pre-reset responses must not be accepted as post-reset traffic.

## R-010 Architecture A
Per-target, per-request-direction round-robin address arbitration. A selected downstream request is held stable until handshake. Pointer advances only on handshake.

## R-011 Architecture B
Same topology/datapath/buffering/protocol behaviour as A; only scheduling policy/state changes. Normal mode selects maximum 4-bit AxQOS with RR tie break. An 8-bit saturating age counter increments while a legal request remains pending without handshake. `age >= 64` enters starvation escape; the starved set is served round-robin. Held requests are never pre-empted.

## R-012 Performance experiment integrity
Canonical workloads W00–W13, generator algorithm, target percentages, gap distributions, endpoint queue/latency model, seeds `0xFABC0001`…`0xFABC0005`, 500 warm-up completions and 5,000 retained samples are frozen in `bench/workloads.yaml` before Architecture B performance data is inspected. A/B use identical target, wrapper, buffering, endpoint models, constraints and measurement scripts.

## R-013 Interface and implementation freeze

The exact signal list above, one-clock reset style, buffering contract, endpoint model, workload file, metric vocabulary and ECP5 implementation settings are the Gate-1 contract. Any change after Architecture A starts requires a new decision and invalidates affected A/B comparisons.

## R-014 Implementation target
Open-source first: LFE5U-45F, CABGA381, speed grade 6, common wrapper/constraints. Vendor flow is optional and not an MVP blocker.

## R-015 CDC extension
Single-clock MVP first. CDC is a later controlled extension using per-channel architecture; never place one FIFO around the whole AXI bus.

## Traceability rule
The Gate-1 verification matrix in `docs/VERIFICATION_PLAN.md` assigns every requirement to directed, random or formal checks and to the planned implementation block before RTL begins.
