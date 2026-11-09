# Authorship and AI-assistance review

**Inventory snapshot:** `35911fc63a1621f931aeaaa41ad632e28bf0ea72`

**Method:** Git tree/blob inventory plus project instructions, PR descriptions,
source headers, audit records and available local session-index search. No
authorship classifier or style-based inference was used.

## Findings

The record supports substantial ChatGPT/Codex involvement in technical
planning, implementation, debugging, test and tool automation, evidence
processing, and documentation. The operating instructions and merged PR
descriptions establish that project-level workflow context; they do not by
themselves establish the origin of each file.

The register separates those two claims. Its file-origin classifications are:
1 `AI_ASSISTED_CONFIRMED` (README, for the specific AI-assisted change recorded
by PR #1), 512 `TOOL_GENERATED`, and 752 `UNKNOWN`. It contains no
`HUMAN_CONFIRMED`, `AI_GENERATED_CONFIRMED`, `MIXED_CONFIRMED`, or
`THIRD_PARTY` classifications because the available records do not support
those file-specific labels. The separate
[`project_ai_workflow_context.json`](generated/project_ai_workflow_context.json)
records confirmed project-wide assistance without attributing it to every file.
No contribution percentage is calculated. No vendored third-party Fabric
source was found in the notices/manifest review.

Within `results/processed/`, 34 of 70 files are machine-readable comparison or
measurement artifacts and figures with identifiable generators or run records;
36 narrative or otherwise unattributed files remain `UNKNOWN`. Four of the 34
are Architecture-A measurement tables; the remainder are comparison and
reproduction outputs. Within `results/raw/`, 470 of 941 files match an
anchored tool signature or a validated structured output schema. The remaining 471 are `UNKNOWN`, including 469 nonempty files
without sufficiently specific origin evidence and two empty trace/output files.
Directory placement and generic tool-name text alone do not establish generated
origin. Some raw JSON records are classified from strict typed schemas; this
identifies a known output format but does not independently prove which process
wrote the file or who launched it. JUnit XML and event JSONL remain `UNKNOWN`
based on format alone because no per-file producer record was established. Six
empty `.keep` placeholders elsewhere in the repository are also `UNKNOWN`.

The local Codex session index search found no project-specific conversation
transcript. Repository prompts and task briefs are available, but they do not
constitute a complete interaction history. GitHub PR metadata for #1–#6 showed
no submitted review records. The archived patch reviews are separate Codex
contexts, not human reviews.

## Register

`generated/ai_provenance_register.csv` contains one row for each of the 1,265
tracked paths in the inventory snapshot, with its Git blob ID, file-origin
evidence and classification, and a separate project-context ID. The workflow
context is recorded in `generated/project_ai_workflow_context.json`. Regenerate
the pinned inventory with:

```bash
python3 portfolio_audit/build_ai_provenance_register.py --revision 35911fc63a1621f931aeaaa41ad632e28bf0ea72
```

The generator defaults to the pinned baseline. An explicit nonbaseline
revision requires `--allow-nonbaseline` and separate nondefault CSV/JSON output
paths, and both resolved outputs are checked against both protected destinations,
so an accidental `HEAD` invocation or output-path alias cannot replace either
checked-in artifact. Raw logs require anchored tool banners; structured JSON
requires recognized typed schemas. JUnit XML, JSONL and other unmatched content
remain `UNKNOWN` unless file-specific producer evidence is available.

## Credibility review

**Technical review perspective (Codex-assisted, not human peer review):** The README and linked requirements,
microarchitecture, formal limitations, decisions and processed A/B results
provide a traceable account of the supported AXI subset and experiment. The
project appropriately distinguishes directed four-outstanding evidence from
random depth-two observations, bounded formal checks from whole-Fabric proof,
and synthetic endpoint measurements from production memory behavior. The
recorded response-target matching limitation remains documented.

**Hiring-manager perspective (heuristic review, not recruiter feedback):** The README communicates the design question and the
negative B result without claiming universal QoS benefit. A direct provenance
link is added so AI involvement and evidence limits are easy to find. The
existing source map and architecture explanation already make a separate
walkthrough document duplicative; no extra walkthrough is proposed.

**Maintainability view:** The existing semantic source review is retained and
not repeated. Its P3 observations about stale B module headers remain deferred
because changing RTL source comments is outside this documentation/provenance
mission. The old A-only summary and historical prompts remain as dated evidence.

## Adversarial review

A fresh Codex context performed a read-only patch review; it was not a human
review. It identified (1) stale historical wording for SR-P2-03, (2) a
generator provenance reference that did not name this new generator, and (3)
three claim-matrix entries using shorthand rather than exact paths. It also
recommended labeling reviewer-perspective sections as model-assisted
assessments. These findings were corrected, and the affected links, source
paths, provenance tests and frozen-file checks were rerun. The reviewer found no
change to D045/D047, source, benchmark data or measurement claims.

A second read-only Codex review checked the final evidence-matrix refinement at
`22d8da0`: all newly specified evidence paths exist, scope wording is unchanged,
and no frozen technical data changed. A third fresh Codex review of this
corrective diff requested stricter raw-log signatures and removal of generic
Verilog-witness classification, and asked that raw/processed counts be
reconciled. Later fresh Codex reviews identified output-path alias and
processed-path fallback risks; both were corrected and covered by negative
tests. Another fresh review observed that XML/JSONL shape alone does not prove producer provenance, so
those raw files remain `UNKNOWN` absent file-specific records. The latest fresh
review found no further defects, but noted that strict JSON schema matches still
identify format rather than independently proving the writer or command operator.
That limitation is now stated above; the typed schemas, exact processed-output
map, output protections and count reconciliation were rechecked. These were
separate Codex contexts, not independent human approvals.

## Owner confirmation still needed

The private checklist `portfolio_audit/owner_attestation_checklist.local.md`
contains questions for claims requiring the owner’s own confirmation. It is
excluded locally and is not committed or treated as evidence.
