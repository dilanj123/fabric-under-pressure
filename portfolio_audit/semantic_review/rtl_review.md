> Separate Codex CLI read-only review context. These are source-review observations, not test execution or human approval.

### RTL observations

- `rtl/axi_address_decoder.sv` — Decodes the three mapped address windows and defaults every other address to S3 (lines 7–19).
- `rtl/axi_ar_target_path_a.sv` — Captures the selected manager’s AR payload and widened ID into a one-entry target slot on manager admission; slot drain and refill cannot share an edge (lines 131–162, 175–189).
- `rtl/axi_ar_target_path_b.sv` — Uses the same one-entry AR admission slot as A, with the B scheduler supplying selection (lines 131–163, 176–190).
- `rtl/axi_ar_target_scheduler_a.sv` — Forms eligibility from valid, legal, matching requests with outstanding capacity, and suppresses same-edge successor selection after AR admission (lines 23–39).
- `rtl/axi_ar_target_scheduler_b.sv` — Ages legal mapped requests separately from capacity eligibility and passes both sets to the QoS arbiter (lines 23–37).
- `rtl/axi_aw_target_path_a.sv` — Captures the selected AW and widened ID at manager admission; the registered AW slot holds them until target handshake (lines 171–225, 246–284).
- `rtl/axi_aw_target_path_b.sv` — Has the same AW slot and admission boundary as A, with QoS selection (lines 171–226, 247–285).
- `rtl/axi_aw_target_scheduler_a.sv` — Blocks AW eligibility while the target has an unfinished write owner and suppresses same-edge successor selection on acceptance (lines 35–64).
- `rtl/axi_aw_target_scheduler_b.sv` — Ages legal pending AW requests even when capacity or target ownership currently prevents admission (lines 26–43).
- `rtl/axi_b_response_router.sv` — Validates widened BID against manager busy state, buffers one B per manager, and completes write tracking only on manager B handshake (lines 85–143, 182–222).
- `rtl/axi_fabric_a.sv` — Composes four AW/AR/W target paths with shared per-manager write/read state, common B/R routers, and internal S3 (lines 218–264, 315–321).
- `rtl/axi_fabric_b.sv` — Composes the same shared state and response paths as A, substituting B AW/AR target paths (lines 218–264, 315–321).
- `rtl/axi_id_mapper.sv` — Widening prepends the manager index; return decoding marks prefix `2'b11` invalid (lines 14–19).
- `rtl/axi_outstanding_tracker.sv` — Uses registered busy/count state for admission eligibility and updates allocation/completion state only at the clock edge (lines 34–58, 60–86).
- `rtl/axi_qos_aging_arbiter_3.sv` — Selects highest QoS until an eligible request reaches age 64, then round-robins among starved requests; accepted selections advance the pointer and clear the grant (lines 33–72, 82–109).
- `rtl/axi_r_response_router.sv` — Buffers target R beats per manager, locks source and widened RID through manager-accepted RLAST, and only then emits read completion (lines 138–179, 181–266, 283–339).
- `rtl/axi_read_state_bank.sv` — Allocates shared per-manager read state on admitted AR and clears it from the response router’s completion event (lines 30–60).
- `rtl/axi_request_legal.sv` — Accepts only aligned, full-width, normal-lock INCR bursts of at most 16 beats that stay within a 4-KiB page (lines 19–30).
- `rtl/axi_rr_arbiter_3.sv` — Registers a three-manager grant and holds it while downstream is not ready; pointer advances on ready (lines 108–127, 130–148).
- `rtl/axi_rr_arbiter_4.sv` — Registers a four-source grant and holds it until downstream-ready, advancing its pointer on that event (lines 65–84, 86–105).
- `rtl/axi_s3_error_target.sv` — Accepts one write and one read context independently; returns DECERR after the full W burst and one DECERR R beat per accepted read beat (lines 76–100, 115–148).
- `rtl/axi_w_target_path.sv` — Routes W from registered owner context through a one-beat slot and prevents replacing a delivered final beat on that cycle (lines 44–93, 95–144).
- `rtl/axi_write_owner.sv` — Captures target, IDs, and expected beat count at AW allocation and retains ownership until an accepted correctly marked final W beat (lines 34–47, 49–75).
- `rtl/axi_write_state_bank.sv` — Commits AW allocation atomically to the outstanding tracker and W owner only when both are available and admission metadata matches (lines 61–107, 110–133).
- `rtl/fabric_addr_map_pkg.sv` — Defines the S0–S2 address windows and shared supported-subset constants; S3 is the default target (lines 5–21).

### Confirmed defects or material disclosed gaps

- **No confirmed functional defect found in the inspected RTL.**
- **Recorded-target response matching is absent:** the trackers store target metadata, but the B/R routers validate returned ID against busy state without checking that the response came from the target recorded for that ID. This is disclosed in D037 and the verification plan. Relevant ranges: [axi_outstanding_tracker.sv](rtl/axi_outstanding_tracker.sv:28), [axi_b_response_router.sv](rtl/axi_b_response_router.sv:85), [axi_r_response_router.sv](rtl/axi_r_response_router.sv:138), [axi_read_state_bank.sv](rtl/axi_read_state_bank.sv:30).
- **Production-top diagnostics are not externally surfaced:** fabric tops leave violation outputs from shared state and response routers unconnected. This is a monitoring/integration limitation, not evidence of incorrect transaction routing. Ranges: [axi_fabric_a.sv](rtl/axi_fabric_a.sv:243), [axi_fabric_a.sv](rtl/axi_fabric_a.sv:315), with equivalent connections in B.
- **A/B read and write lifecycle:** AW admission allocates shared outstanding and owner state; W follows that owner through final WLAST; B completion occurs on manager B handshake. AR admission allocates shared read state; target R beats are buffered and source/RID-locked; read completion occurs on manager-accepted RLAST. D028 uses pre-state capacity, D030 prohibits same-cycle owner reuse, D031/D036 suppress same-edge address successor selection, and D032 specifies the shared one-entry target address slot. These behaviors are reflected in [axi_write_state_bank.sv](rtl/axi_write_state_bank.sv:110), [axi_r_response_router.sv](rtl/axi_r_response_router.sv:181), and [axi_ar_target_path_a.sv](rtl/axi_ar_target_path_a.sv:175).

### Test/formal limitation

Evidence is directed/random simulation plus property-scoped bounded formal checks under stated assumptions; it does not prove whole-fabric correctness or unrestricted AXI4 compliance. B’s scheduler formal is bounded; the B whole-DUT evidence is simulation. Random B runs reached outstanding depth two, with four-outstanding capacity covered by directed evidence. The disclosed recorded-target matching gap remains unproven/unimplemented.