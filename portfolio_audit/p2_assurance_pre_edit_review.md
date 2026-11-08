# P2 assurance hardening — pre-edit review

**Review baseline:** `40317a634a1ef9b40be50db831bcd073fad9e9bb`

**Branch:** `assurance/p2-tooling-guards`

## Independent assessment before implementation

The three findings require different treatment. SR-P2-04 and SR-P2-05 are narrowly scoped guard-strength issues: the comparison and PPA summarizer should reject malformed input, while preserving their existing numerical calculations. These changes can be tested with synthetic negative fixtures and then checked against copies of the frozen data. Their risk is accidental rejection of legitimate historical manifests or Yosys report variants, so positive tests against the committed A/B outputs are necessary.

SR-P2-03 is different. Its original review wording identified a possible oracle event-correlation weakness but had no failing trace. Modifying that cocotb test alongside parser changes would mix a testbench behavior correction with tooling guards and could require Gate-2 and A/B functional requalification. The appropriate first step is a qualified simulator diagnostic that samples actual public handshakes at active edges. If it finds no mismatch, retain a precise limitation. If it finds a mismatch, preserve evidence and define a separate repair rather than silently expanding this PR.

The requested work must not alter scheduler behavior, production RTL, formal assumptions, frozen workload/endpoint/metrics, D045/D047, or historical processed results. The comparator may validate identities and completeness but must leave aggregation and acceptance criteria intact. The PPA parser may reject absent/malformed required report data and treat optional resource classes as zero only after recognizing the expected report format.

## Plan corrections and execution order

1. Verify the current branch, clean baseline, protected tags and frozen workload hash.
2. Add comparator validation and focused negative fixtures; validate the unchanged frozen A/B dataset into a separate output directory.
3. Add fail-closed PPA parsing and format/error fixtures; reprocess copied A/B reports and compare parsed resources and route summaries.
4. Independently instrument the existing oracle test in an isolated copy; compare active-edge public handshakes with oracle updates. Do not edit the checked-in oracle test in this task.
5. Update only the P2 finding records and record any oracle correction as a separate follow-up if a mismatch is reproduced.
6. Obtain a separate patch review, validate changed-file scope and hashes, then submit one focused PR for the two guard fixes, their tests and concise diagnostic/finding documentation.

## Stop conditions

- Stop source edits and preserve a reproducer if a public DUT handshake is shown to be functionally wrong; production RTL changes are outside scope.
- Keep SR-P2-03 separate if an oracle mismatch is found; do not imply Gate-2 confidence is complete until the oracle correction and required regressions occur.
- Do not replace or overwrite authoritative historical result files.
- Do not claim measurement requalification: these changes only strengthen comparator/parser input validation, and the frozen data must numerically reproduce unchanged.

## Recommendation

**PROCEED WITH CHANGES.** The comparator and parser hardening are justified and bounded. Treat the oracle timing question as a diagnostic-only branch point; escalate a reproduced mismatch into a separate corrective task.
