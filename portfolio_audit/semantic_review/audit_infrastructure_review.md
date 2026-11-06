> Separate Codex CLI read-only review context. These are source-review observations, not test execution or human approval.

## Concerns

- **The baseline counts are being used where current counts are needed.** The audit records **1,110 tracked files and 827 raw files** at baseline commit `d2ef2bb…`. The current checkout is `05440c3…` and has **1,179 tracked files, including 877 raw files**. The added raw files include the A/B PR2 qualification runs. The register is a baseline audit, but its “baseline-to-current” wording says it contains 32 changes; that register only compares paths present in the baseline and omits additions. The current Git diff has 102 changed paths. See [audit findings](portfolio_audit/audit_findings.md:3) and [baseline difference register](portfolio_audit/generated/baseline_worktree_differences.csv).

- **The duplicate totals are mislabeled as raw-only.** The script hashes every tracked baseline file, not only `results/raw/`. Of the 64 reported duplicate groups, 11 include non-raw paths; only 53 groups contain raw members exclusively. So “64 raw duplicate groups” and the associated 43.5 MB figure describe repository-wide duplicates, not raw-only redundancy. See [audit findings](portfolio_audit/audit_findings.md:9) and [duplicate groups](portfolio_audit/generated/duplicate_groups.csv).

- **The privacy scan supports narrower claims than a general privacy audit.** The 301 path hits are raw-file matches for a specific `/Users/<name>/` pattern. The credential scan checks four regex classes; the email-shaped scan runs on raw artifacts, while the all-tracked-file scan covers credential patterns only. The report does disclose that secret detection is pattern-based, but its “all-tracked-file” phrasing could be read more broadly than the actual coverage. See [scanner implementation](portfolio_audit/build_register.py:64) and [scan findings](portfolio_audit/audit_findings.md:26).

- **The audit does not establish semantic correctness across the repository.** It verifies baseline file hashes and selected raw formats, then performs targeted source/status review; it explicitly says it is not a line-by-line RTL re-verification. Treat “full tracked-file/hash/raw-structure audit” as inventory and structural validation, not full semantic verification. See [audit scope](portfolio_audit/audit_findings.md:32).

- **The current PR2 qualification evidence is outside the audited baseline.** Its A/B manifests mark runs as `qualification_only`, with 25 warm-up and 75 samples for six workloads and one seed. Those records should not be conflated with the canonical 70-run-per-architecture benchmark evidence. The evidence index keeps those claims separate, but the count discrepancy makes the distinction important. See the [PR2 A manifest](results/raw/portfolio_audit_pr2_A/source_manifest.json) and [baseline/current difference register](portfolio_audit/generated/baseline_worktree_differences.csv).
## Additional file-specific inspection

The audit package has three tracked Python files in the review revision. `portfolio_audit/__init__.py` is a package marker; `build_register.py` reads Git objects, calculates hashes and scans selected raw formats/pattern classes without executing source; `test_build_register.py` exercises filtering of generated worktree output versus staged and non-generated changes. The initial scope note did not list these three filenames individually; this addendum records their direct inspection.

- `portfolio_audit/__init__.py` — package docstring only; no runtime behavior.
- `portfolio_audit/test_build_register.py` — three unit tests distinguish generated unstaged output from staged and non-generated changes in the dirty-check filter.
