# Development provenance

Fabric Under Pressure is a self-directed engineering project developed with
substantial ChatGPT and Codex assistance. The repository records AI involvement
in technical planning, RTL and testbench implementation, debugging, regression
automation, evidence processing and documentation. This was not limited to
formatting or copy editing.

The project records establish the use of AI tools, but do not preserve a
reliable line-by-line division between owner-authored and model-generated code.
Git author names, reviewability, and the fact that a source file was examined do
not establish who wrote it. No human-versus-AI authorship percentage is claimed.

Project scope and acceptance decisions are recorded in the requirements,
decision log and task history. Their records do not prove which ideas originated
with the owner versus AI-assisted discussion. Likewise, checked-in logs prove
that a tool produced an output, but do not consistently identify who launched
the command or independently inspected its result. Codex review contexts are
model reviews, not human peer review. Owner-specific contribution claims remain
for the owner to confirm.

The path-level register at
[`portfolio_audit/generated/ai_provenance_register.csv`](../portfolio_audit/generated/ai_provenance_register.csv)
is a conservative classification of files in the recorded baseline commit.
For engineering source sets it records confirmed project-level AI assistance;
it does not assert per-line provenance. The source and semantic review records
show what was inspected, not who authored the inspected material. The baseline
and classification method are described in
[`portfolio_audit/ai_authorship_review.md`](../portfolio_audit/ai_authorship_review.md).

The project’s original operating instructions and completed task prompts remain
available in the repository history and [`docs/history/`](history/). The
third-party notices state that no third-party Fabric implementation source is
vendored; dependencies remain listed separately in the manifest and notices.

## Evidence limits

- The repository does not contain a complete transcript of the ChatGPT/Codex
  sessions that produced the work.
- No reliable per-file manual-authorship inventory or personal execution log is
  available.
- Technical verification, formal runs and measurements are reported at the
  scope documented by their evidence; repository records alone do not establish
  the owner personally ran or independently validated every result.
- This statement is not a claim of unrestricted AXI4 compliance, exhaustive
  formal proof, or production timing signoff.
