# Final repository audit plan review

**Reviewed before repository edits:** 2026-11-06
**Starting commit:** `d2ef2bb2ec41a2b99f6532618a4a2d41bca736b5`
**Branch:** `portfolio/final-audit-cleanup` (created from clean `main`)
**Recommendation:** **PROCEED WITH CHANGES**

## Review basis

I read the authority chain through the evidence index, the relevant master-plan workload/metrics/PPA/integrity/gate sections, the current README and project status, Git history/tags, the reference project's public README, and the source/report paths named by the audit plan. The checkout was clean; `main` and `origin/main` both resolved to the stated Gate-5 commit. All protected tags resolved to their expected commits. The repository contains 1,110 tracked files (827 under `results/raw/`).

The supplied `portfolio_file_audit.py`, deep-audit package, original audit brief, `ENGINEERING_OWNERSHIP_GUIDE.md` and `CV_LINKEDIN_COPY.md` were not found in the repository or the checked Downloads/Documents/Desktop/temp locations. I therefore treat the mission text as the audit brief and will build the required register from Git's tracked-file list. I will create separate personal-material drafts only after the technical evidence audit; they will not be committed to this source repository.

## Plan strengths

- It explicitly protects the Gate-5 baseline, tags, benchmark definitions and negative D045/D047 result.
- It separates documentation, tooling and raw-artifact work into reviewable pull requests.
- It requires evidence classification, reproducible commands and independent patch review instead of relying on prose claims.
- It correctly prevents deleting historical failures merely to reduce repository size and rejects unauthorized RTL or QoS changes.
- It distinguishes same-host clean-clone reproduction from independent-hardware reproduction and keeps formal/PPA claims appropriately bounded.

## Gaps and corrections

1. **The audit helper/package is unavailable.** Do not execute an unknown script. The reviewed replacement reads the named baseline using `git ls-tree`/`git cat-file`, hashes every blob and checked-out path, and writes redacted registers without executing repository code.
2. **Current authoritative documents contain stale status headers.** `docs/REQUIREMENTS.md`, `docs/MICROARCHITECTURE.md` and `docs/VERIFICATION_PLAN.md` still describe implementation or the A/B comparison as not started/open. Several early evidence-index entries also say B benchmarking remains open. Correct these as dated/current-state pointers while retaining their original technical contracts and clearly historical evidence.
3. **The master plan is a dated planning snapshot, but its opening status reads as present tense.** Clarify that implementation had not started at its September 2026 planning snapshot. Do not rewrite the frozen design contract or acceptance criteria.
4. **README replacement is unnecessary.** The current README is concise and technically specific. Add only high-value source navigation or a clarification where the source/evidence audit demonstrates a gap.
5. **Raw duplicates do not justify removal by themselves.** The full hash-based inventory contains 827 files (about 149 MiB) and 64 byte-identical duplicate groups (171 extra paths, about 43.5 MB). The earlier 54-group/155-path count was a preliminary estimate and is superseded by the complete register. No durable external archive was supplied. Keep all raw evidence and do not open a deletion PR.
6. **No blanket licence may be inferred.** Review current manifests and source provenance. If project-wide reuse terms are absent, document that finding; do not add a licence without the owner choosing one.
7. **Tool-path work is potentially experiment-sensitive.** Inspect each hard-coded path and centralize only if a small, tested configuration helper preserves exact pinned tool selection and fails clearly. Benchmark/RTL/endpoint/metric behavior remains fixed. Treat this as a separate PR and record changed script hashes.
8. **Plot path cleanup is a narrow candidate.** Accept explicit PPA summary roots only if the existing defaults remain unchanged and regenerated numerical tables match frozen outputs.
9. **Independent review has no supplied audit package or known reviewer.** First check for a supported independent reviewer. If none is available, perform a separately recorded patch-focused review and disclose that it is not a fresh-context review.
10. **No test/source cleanup is presumed.** The existing `pytest` package-name collision is not a defect if the committed unittest workflow is the supported command. Do not rename packages merely to make arbitrary root-level pytest collection work.
11. **Personal career claims require user ownership.** Prepare drafts grounded in project artifacts, label them for user review, and do not state that the user authored or understands code solely because the repository contains it.

## Risks and dependencies

- Moving setup prompts may break literal path references in the historical project tree, bootstrap instructions or task records. Preserve the two current authority files at the root. Archive one-time documents only after exhaustive path/link checks; otherwise mark them historical in place.
- Old SVG and plan-era prose can be mistaken for current implementation. Prefer a historical caption or status note over redrawing a diagram without a source-derived need.
- Raw logs may include machine paths or identity metadata. Scan locally and report only redacted counts/locations; do not echo credential-like values. Preserve original bytes unless an authorized and verifiable redaction/archive process is established.
- GitHub branch/PR/CI permissions are dependencies. Never force-push, rewrite history, merge a failing PR or create a new release tag for this cleanup.
- The reference repository is useful as an example of result provenance and explicit limits, not a style or architecture authority. Its longer README is not a reason to lengthen this README.

## Approved execution order

1. Capture baseline commit, protected-tag commits, source/workload/decision hashes and GitHub state.
2. Produce a complete per-tracked-file inventory, exact-duplicate report, redacted raw-log scan, source-review issue list and claim/evidence matrix. Classify every tracked file `KEEP`, `IMPROVE`, `ARCHIVE` or `REMOVE`, with action execution status; default to `KEEP` absent evidence and a safe destination.
3. **PR 1 — documentation/navigation:** fix only stale status, clarify planning snapshots, label historical material, improve concise source/evidence navigation and preserve D045/D047. No RTL, formal, workload, raw evidence or benchmark changes.
4. **PR 2 — reproducibility tooling:** make narrowly justified tool-root/plot-input improvements, validate shell/Python behavior, representative A/B tests, formal checks and benchmark plan hashes. Do not rerun full canonical measurements unless a substantive measurement behavior changes.
5. Do not create PR 3 unless a durable archive destination exists and byte-for-byte verification/reference migration is proven. At present, preserve duplicates.
6. Prepare personal interview/CV drafts outside the RTL repository, clearly distinguishing project evidence from personal contribution claims.
7. Run a separate final diff review (fresh context/reviewer if supported), validate links and relevant regressions, open and normally merge approved PRs, then verify `main`, cleanliness and protected tags.

## Stop conditions

- A contradiction in the frozen technical contract, a proposed D045/D047/workload/RTL/formal change, or an evidence-integrity issue requiring a new engineering decision.
- Detection of an active secret/credential: stop handling the value, record a redacted finding and require a separate incident/remediation decision.
- No safe archive mechanism for an intended raw deletion; in that case retain the files and skip the raw-cleanup PR.
- Required tests/CI fail and the issue cannot be isolated to a documentation/tooling change without changing experiment behavior.
- GitHub permissions or branch protection prevent a normal PR/merge; preserve the branch and report the exact blocker rather than bypassing controls.

**No production defect or specification contradiction is established by the read-only Phase-0 review.** The stale project-status wording is documentation drift and can be corrected without changing the frozen contract.
