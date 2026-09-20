# Microarchitecture

**Status:** Gate-1 skeleton. Frozen architectural contract is copied here; implementation decomposition remains to be completed before RTL.

## 1. Topology
3 manager ports fan into target-specific request arbitration for S0/S1/S2 plus internal S3 error handling. Read and write request scheduling are independent.

## 2. Address path
Decode AW and AR independently. Legal supported requests select one logical target. Unmapped addresses select S3. Decode must be one-hot-or-error.

## 3. IDs/outstanding
Manager IDs are 4 bits. Append 2-bit manager index downstream for 6-bit internal IDs. Limit to 4 outstanding read and 4 outstanding write transactions per manager, with one outstanding per ID per direction.

## 4. Write path
Accepted AW allocates/records write route ownership. Because AXI4 has no WID, write data are forwarded in accepted address order. Target W ownership remains through WLAST handshake. B uses returned internal BID to recover manager and original ID.

## 5. Read path
AR routing uses target decode/arbitration. R returns based on widened RID. Per-manager return arbitration must not interleave beats from a burst in a way that violates the accepted subordinate stream; lock chosen return source through RLAST when needed.

## 6. Arbitration
### A — RR
Per-target AW and AR RR, handshake-driven pointer update, held grant under backpressure.

### B — QoS + aging
Normal: maximum AxQOS, RR tie-break. Starvation escape: age >=64, serve starved set RR. 8-bit saturating counters; reset age to zero when no legal pending request or request handshakes.

## 7. Buffers
Gate 1 must freeze exact skid/register buffering and show that A/B buffering is identical. Any B-only pipeline creates a separately named variant and invalidates the pure scheduler-policy comparison.

## 8. Reset/error
Coordinated reset flushes all route/outstanding state. S3 consumes legal supported request shape and returns DECERR while preserving required beat count/LAST semantics.

## 9. Open Gate-1 implementation details
- exact register-slice/skid placement;
- exact outstanding-table structure under frozen one-per-ID policy;
- endpoint memory model details;
- performance-counter register map/observation method.
