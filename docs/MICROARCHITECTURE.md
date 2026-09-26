# Microarchitecture

**Status:** Gate-1 specification frozen. Implementation is intentionally not started.

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
Normal: maximum AxQOS, RR tie-break. Starvation escape: age >=64, serve starved set RR. The 8-bit age counter increments by one on every clock cycle that a legal request remains pending without handshake and saturates at 255; reset age to zero when no legal pending request or when the request handshakes. Service-opportunity assumptions apply to the later liveness guarantee, not to age measurement.

## 7. Buffers
Each manager-facing and target-facing channel has one registered ready/valid boundary. Payload and VALID remain stable while VALID is asserted and READY is low. The AW, W, B, AR and R boundaries are independent. A and B use the same boundary count, widths and placement; a B-only pipeline is a named variant and is not part of the frozen comparison.

## 7a. Exact state decomposition

- `decode_aw`/`decode_ar`: combinational target decode with one-hot legal target or S3 error selection.
- `aw_rr[target]` and `ar_rr[target]`: 2-bit per-target round-robin pointers for A; B retains the same pointers and changes only the request selection policy. At an AW target boundary, a successful AW handshake suppresses same-edge successor selection; scheduling resumes after registered write-owner state reports the target free.
- `write_owner[manager]`: one registered active accepted-AW context driving W until accepted WLAST; it records target, original ID, widened ID and remaining-beat state. A manager has only one unfinished W burst. Completed-W transactions waiting for B remain in `outstanding_w[manager][id]` and are not write-owner entries.
- `outstanding_r[manager][id]` and `outstanding_w[manager][id]`: valid bits plus target and burst metadata, with four-entry per-direction admission counters per manager.
- `read_return[target]` and `write_response[target]`: response queues with fixed depth 8 in the canonical endpoint model; the fabric preserves burst-level R ownership through RLAST.
- `age[target][direction][manager]`: 8-bit saturating B-only scheduler state, reset when no legal request is pending or when the request handshakes, and incremented every pending clock cycle without handshake. Recurring service opportunities are assumed only for the later bounded-service claim.

The one-outstanding-per-ID rule means no reorder buffer is required for a repeated ID. Different IDs may return out of issue order, subject to subordinate response behavior.

## 8. Reset/error
Coordinated reset flushes all route/outstanding state. Stateful MVP RTL uses active-low asynchronous assertion and synchronous deassertion to rising `ACLK`:

```systemverilog
always_ff @(posedge ACLK or negedge ARESETn) begin
  if (!ARESETn) begin
    // clear state
  end else begin
    // registered state update
  end
end
```

The coordinated environment is responsible for synchronous reset release; individual MVP blocks do not add reset synchronizers. S3 consumes legal supported request shape and returns DECERR while preserving required beat count/LAST semantics.

Outstanding capacity is derived from registered pre-state. A completion on cycle N cannot recycle its ID or count capacity into a new allocation on cycle N. Different-ID allocation is allowed in the same cycle only when the pre-state ID is free and the pre-state count is below four.

## 9. Canonical endpoint and measurement contract

The benchmark subordinate model has queue depth 8 per target, accepts AW/AR whenever capacity exists, asserts WREADY for an active legal owned burst, starts reads after two cycles, returns B two cycles after the final accepted W beat, and emits one read beat per cycle after the two-cycle read start. Response ordering is fixed per-target FIFO for each direction and identical for A and B. Random response delays are used only by functional verification.

Measurement observes handshake events at the manager-facing boundary and records the counters defined in `docs/TIMING_PERFORMANCE.md`; there is no performance register map in the MVP. A registered signature/status observation is used by the compact implementation wrapper.
