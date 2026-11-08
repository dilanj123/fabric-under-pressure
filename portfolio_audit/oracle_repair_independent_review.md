# Independent review — Gate-2 oracle R repair

**Review date:** 2026-11-08
**Scope:** patch-focused review of the current R driver, model negative tests, Gate-2 runners and focused evidence.
**Method:** separate Codex review context inspected the changed source and saved trace; reviewer did not edit files or independently rerun simulations.

## Findings and disposition

1. **Fault-result wording needed narrowing.** The focused driver validates accepted manager payload/sequence before calling `model.observe_r`, so bus-level injected duplicate/data/LAST errors are detected by driver assertions. The wrong-RID case is blocked before manager acceptance and reports `wrong RID blocked`. The reference model independently rejects direct malformed events in its Python negative tests. The processed summary now separates boundary-driver fault checks from model unit sensitivity and does not claim the wrong-RID bus case reached the oracle.
2. **Focused payload vector is not an independent-memory check.** The focused LEN=3 data vector is read from the oracle’s initialized memory, making this test specifically a handshake-correlation/order/RLAST regression. Broader mapped reads still compare against the separate endpoint memory. This scope distinction is documented.
3. **No transfer-counting defect found in the new driver.** The reviewer checked falling-edge drive, settled pre-edge sample, immediate active-edge sample, post-edge `ReadOnly` diagnostic, payload holds and post-completion checks. The saved focused trace has 25 matching pre-edge/active-edge snapshots; 18 ReadOnly snapshots differ due to sequential state updates.
4. **Adjacent AR recovery correction is supported.** The new monitor counts the fifth request on actual manager `ARVALID && ARREADY` and observes the later target AR handshake, rather than interpreting post-edge READY as the prior edge’s handshake.
5. **No specific AW/W/B replay issue was identified** in the inspected scope. These legacy helpers were not refactored into the new R monitor.

## Review limits

The reviewer examined the requested patch and trace but did not run the simulation or verify every dependent helper. The author’s recorded qualified-simulator runs and XML checks remain the execution evidence. No RTL, formal, benchmark, workload, processed A/B result or D045/D047 change was present in the patch.
