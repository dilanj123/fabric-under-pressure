#!/usr/bin/env python3
"""Read-only inventory for the repository baseline named on the command line.

The script hashes tracked Git blobs, compares their checkout paths, records Git
status, scans common raw formats and credential patterns, and writes registers.
It never executes repository files or changes tracked project inputs.
"""
from __future__ import annotations

import argparse
import csv
import gzip
import hashlib
import json
import mimetypes
import re
import subprocess
import xml.etree.ElementTree as ET
from collections import defaultdict
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
AUDIT = ROOT / "portfolio_audit"
OUT = AUDIT / "generated"
TEXT_SUFFIXES = {
    ".md", ".sv", ".v", ".py", ".sh", ".sby", ".smtc", ".yw", ".yml",
    ".yaml", ".json", ".jsonl", ".xml", ".txt", ".csv", ".log", ".diff",
    ".tcl", ".sdc", ".mk", ".ini", ".cfg", ".ys", ".vh", ".svh", ".rst",
}
HISTORICAL_PARTS = (
    "investigation", "pre_fix", "prefx", "failed", "gate3_random_v2",
    "gate3_random_long", "historical", "formal_prototype",
)
ROOT_ARCHIVE = {
    "02_PHASE0_BOOTSTRAP_TASK.md": "docs/history/02_PHASE0_BOOTSTRAP_TASK.md",
    "03_START_NEW_CHATGPT_PROJECT.md": "docs/history/03_START_NEW_CHATGPT_PROJECT.md",
    "MASTER_CHATGPT_HANDOFF_PROMPT.md": "docs/history/MASTER_CHATGPT_HANDOFF_PROMPT.md",
}
IMPROVE = {
    "00_MASTER_PROJECT_PLAN.md": "Clarify dated planning snapshot; preserve frozen contract.",
    "docs/REQUIREMENTS.md": "Replace stale no-implementation status with current evidence pointer.",
    "docs/MICROARCHITECTURE.md": "Replace stale not-started status with current implementation pointer.",
    "docs/VERIFICATION_PLAN.md": "Update stale B-benchmark/open status after Gate 4/5.",
    "docs/EVIDENCE_INDEX.md": "Mark superseded early B/open entries as historical/current-state superseded.",
    "docs/TRADEOFFS.md": "Record frozen measured B disposition D047.",
    "docs/architecture_a_overview.md": "Label implementation blocks as historical planning diagram.",
    "docs/architecture_a_overview.svg": "SVG labels integration as planned; preserve as historical visual.",
}
SECRET_PATTERNS = [
    re.compile(rb"-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----"),
    re.compile(rb"\b(?:gh[pousr]_[A-Za-z0-9_]{20,}|github_pat_[A-Za-z0-9_]{20,})\b"),
    re.compile(rb"\bAKIA[0-9A-Z]{16}\b"),
    re.compile(rb"(?i)\b(?:password|passwd|client_secret|api_key|access_token)\s*[:=]\s*['\"]?[^\s'\"]{16,}"),
]


def git(*args: str, data: bytes | None = None) -> bytes:
    return subprocess.check_output(["git", *args], cwd=ROOT, input=data)


def classify(path: str) -> tuple[str, str, str, str, str]:
    if path.startswith("results/raw/"):
        kind = "generated raw evidence"
        reproducibility = "yes: tool/test evidence or preserved failure"
    elif path.startswith("results/processed/"):
        kind = "generated/reviewed processed evidence"
        reproducibility = "yes: derived result or claim support"
    elif path.startswith(("rtl/", "tb/", "formal/", "scripts/", "bench/")):
        kind = "source/configuration"
        reproducibility = "yes: implementation, verification or experiment input"
    elif path.startswith(("docs/", "tasks/")) or path.endswith(".md"):
        kind = "project-authored documentation"
        reproducibility = "yes: contract, method, history or result traceability"
    else:
        kind = "project configuration or supporting material"
        reproducibility = "reviewed for source/build/evidence role"

    parts = path.lower().split("/")
    historical = path in ROOT_ARCHIVE or path.startswith("tasks/") or any(
        part in HISTORICAL_PARTS for part in parts
    )
    issue = IMPROVE.get(path, "")
    decision = "IMPROVE" if issue else ("ARCHIVE" if path in ROOT_ARCHIVE else "KEEP")
    if path.startswith("results/raw/"):
        decision = "KEEP"
    return kind, reproducibility, "yes" if historical else "no", decision, issue


def inspect_raw(path: str, data: bytes) -> tuple[str, str, str]:
    suffix = Path(path).suffix.lower()
    format_status = "not applicable"
    xml_counts = "not applicable"
    scan_data = data
    if suffix == ".json":
        try:
            json.loads(data)
            format_status = "valid JSON"
        except (UnicodeDecodeError, json.JSONDecodeError):
            format_status = "invalid JSON"
    elif suffix == ".jsonl":
        try:
            for line in data.splitlines():
                if line.strip():
                    json.loads(line)
            format_status = "valid JSONL"
        except (UnicodeDecodeError, json.JSONDecodeError):
            format_status = "invalid JSONL"
    elif suffix == ".xml":
        try:
            root = ET.fromstring(data)
            format_status = "valid XML"
            suites = list(root.iter("testsuite"))
            if root.tag == "testsuite" and not suites:
                suites = [root]
            if suites:
                totals = {
                    key: sum(int(suite.attrib.get(key, "0")) for suite in suites)
                    for key in ("tests", "failures", "errors", "skipped")
                }
                xml_counts = ", ".join(f"{key}={value}" for key, value in totals.items())
            else:
                xml_counts = f"testcases={len(list(root.iter('testcase')))}; no testsuite counters"
        except ET.ParseError:
            format_status = "invalid XML"
    elif suffix == ".gz":
        try:
            scan_data = gzip.decompress(data)
            format_status = "valid gzip"
        except (OSError, EOFError):
            format_status = "invalid gzip"

    text = scan_data.decode("utf-8", errors="ignore")
    flags = []
    if any(pattern.search(scan_data) for pattern in SECRET_PATTERNS):
        flags.append("credential-like pattern (value withheld)")
    if re.search(r"/Users/[^/\s]+/", text):
        flags.append("user-specific absolute path")
    if re.search(r"[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}", text):
        flags.append("email-shaped text (value withheld)")
    if re.search(r"(?im)^\s*(?:FAIL|ERROR|FATAL)(?:\b|:)", text):
        flags.append("failure/error marker; classify against historical run intent")
    return format_status, xml_counts, "; ".join(flags) or "none detected"


def non_generated_checkout_status(lines: list[str]) -> list[str]:
    """Keep staged project changes visible; ignore only generated output edits."""
    result = []
    for line in lines:
        path = line[3:].split(" -> ")[-1].strip('"')
        generated_output = path.startswith("portfolio_audit/generated/")
        index_status, worktree_status = line[:2]
        worktree_only_generated = generated_output and (
            (index_status == " " and worktree_status == "M")
            or line[:2] == "??"
        )
        if not worktree_only_generated:
            result.append(line)
    return result


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--revision", default="HEAD", help="tracked Git revision to audit")
    parser.add_argument(
        "--allow-worktree-differences", action="store_true",
        help="explicitly record checkout differences while auditing the named Git revision",
    )
    args = parser.parse_args()
    revision = git("rev-parse", "--verify", f"{args.revision}^{{commit}}").decode().strip()
    all_status_lines = git(
        "status", "--porcelain=v1", "--untracked-files=all"
    ).decode().splitlines()
    # The generated CSVs are this tool's own outputs. Ignore only unstaged
    # changes and untracked files under that directory. Staged changes remain
    # dirty and still require the explicit override.
    checkout_status_lines = non_generated_checkout_status(all_status_lines)
    if checkout_status_lines and not args.allow_worktree_differences:
        raise SystemExit(
            f"checkout is dirty ({len(checkout_status_lines)} non-generated status entries); "
            "use --allow-worktree-differences "
            "to audit the Git revision and record checkout differences explicitly"
        )
    tree = git("ls-tree", "-r", "-z", revision).split(b"\0")
    entries: list[tuple[str, str, str]] = []
    for item in tree:
        if not item:
            continue
        header, raw_path = item.split(b"\t", 1)
        # `git ls-tree -r` emits: mode, object type, object id.
        mode, object_type, blob = header.decode().split()
        if object_type != "blob":
            continue
        path = raw_path.decode("utf-8", errors="surrogateescape")
        entries.append((path, mode, blob))

    # The inventory is scoped to a clean checkout of the named baseline.
    head = git("rev-parse", "HEAD").decode().strip()
    if revision != head:
        raise SystemExit(f"checkout HEAD {head} differs from requested audit revision {revision}")

    texts: dict[str, bytes] = {}
    records = []
    hashes: dict[str, list[tuple[str, int]]] = defaultdict(list)
    raw_checks = []
    sensitive_findings = []
    blob_mismatches = []
    reference_map: dict[str, int] = defaultdict(int)
    for path, mode, blob in entries:
        if mode == "120000":
            data = git("cat-file", "blob", blob)
            file_type = "symlink"
        else:
            data = git("cat-file", "blob", blob)
            file_type = mimetypes.guess_type(path)[0] or ("text/plain" if Path(path).suffix.lower() in TEXT_SUFFIXES else "application/octet-stream")
        digest = hashlib.sha256(data).hexdigest()
        checkout_path = ROOT / path
        if not checkout_path.exists() and not checkout_path.is_symlink():
            blob_mismatches.append((path, blob, "missing in checkout"))
        else:
            checkout_data = (
                checkout_path.readlink().as_posix().encode()
                if mode == "120000" else checkout_path.read_bytes()
            )
            # The repository uses SHA-1 object IDs. Compute this locally to
            # avoid spawning one Git process per tracked file.
            worktree_blob = hashlib.sha1(
                f"blob {len(checkout_data)}\0".encode() + checkout_data
            ).hexdigest()
            if worktree_blob != blob:
                blob_mismatches.append((path, blob, worktree_blob))
        hashes[digest].append((path, len(data)))
        if Path(path).suffix.lower() in TEXT_SUFFIXES and len(data) <= 12 * 1024 * 1024:
            texts[path] = data
        sensitive_scan_data = data
        if Path(path).suffix.lower() == ".gz":
            try:
                sensitive_scan_data = gzip.decompress(data)
            except (OSError, EOFError):
                pass
        matched_patterns = [
            name for name, pattern in zip(
                ("private-key-header", "github-token-shape", "aws-access-key-shape", "credential-assignment-shape"),
                SECRET_PATTERNS,
            ) if pattern.search(sensitive_scan_data)
        ]
        if matched_patterns:
            sensitive_findings.append({
                "path": path,
                "pattern_classes_only": "; ".join(matched_patterns),
                "matched_value": "withheld",
            })
        kind, reproducibility, historical, decision, issue = classify(path)
        status = "kept; no destructive action"
        final_path = path
        action = ""
        if path in ROOT_ARCHIVE:
            final_path = ROOT_ARCHIVE[path]
            action = "moved intact to historical documentation path"
            status = "executed in this branch; Git rename preserves history"
        elif decision == "IMPROVE":
            action = issue
            status = "improved in this branch"
        if path.startswith("results/raw/"):
            status = "retained; no safe external archive available"
        records.append({
            "path": path, "file_type": file_type, "size_bytes": len(data),
            "sha256": digest, "git_blob": blob, "content_origin": kind,
            "active_script_or_document_references": "",
            "reproducibility_role": reproducibility,
            "historical_only": historical, "duplicate_group": "",
            "concrete_issue": issue, "decision": decision,
            "action_taken": action, "action_status": status,
            "resulting_path": final_path,
        })
        if path.startswith("results/raw/"):
            format_status, xml_counts, flags = inspect_raw(path, data)
            raw_checks.append({
                "path": path, "file_type": file_type, "size_bytes": len(data),
                "sha256": digest, "git_blob": blob,
                "evidence_index_reference": "yes" if b"results/raw/" + path.removeprefix("results/raw/").encode() in texts.get("docs/EVIDENCE_INDEX.md", b"") else "see file-level register",
                "historical_or_current": "historical" if historical else "current-or-supporting",
                "duplicate_group": "", "format_check": format_status,
                "junit_counters": xml_counts,
                "redacted_scan_flags": flags,
                "retention": "KEEP; no destructive action authorized",
            })

    # Count explicit path mentions in source/document text, excluding raw logs.
    source_text = [p for p in texts if not p.startswith("results/raw/")]
    for record in records:
        needle = record["path"].encode()
        refs = [p for p in source_text if p != record["path"] and needle in texts[p]]
        record["active_script_or_document_references"] = str(sum(
            1 for p in refs if p.startswith(("README", "docs/", "scripts/", "bench/", ".github/"))
        ))

    dup_paths = {}
    # Count exact tracked-path mentions in source and documentation. This is a
    # navigation aid, not a claim that every runtime dependency is textual.
    tracked_paths = {path for path, _, _ in entries}
    path_token = re.compile(rb"(?<![A-Za-z0-9_.-])(?:[A-Za-z0-9_.-]+/)+[A-Za-z0-9_.-]+")
    for source_path, content in texts.items():
        if source_path.startswith(("docs/", "scripts/", "bench/", "tb/", "formal/")) or source_path.endswith(".md"):
            for match in set(path_token.findall(content)):
                try:
                    candidate = match.decode("utf-8")
                except UnicodeDecodeError:
                    continue
                if candidate in tracked_paths and candidate != source_path:
                    reference_map[candidate] += 1
    for record in records:
        count = reference_map.get(record["path"], 0)
        record["active_script_or_document_references"] = f"exact path appears in {count} tracked text files"

    duplicate_groups = []
    for digest, members in hashes.items():
        if len(members) < 2:
            continue
        group_id = f"DUP{len(duplicate_groups)+1:04d}"
        paths = [p for p, _ in members]
        for p in paths:
            dup_paths[p] = group_id
        duplicate_groups.append({
            "duplicate_group": group_id, "sha256": digest,
            "size_bytes_each": members[0][1], "member_count": len(members),
            "paths": " | ".join(paths),
            "decision": "KEEP pending documented archive and evidence-reference review",
        })
    for record in records:
        record["duplicate_group"] = dup_paths.get(record["path"], "")
    for record in raw_checks:
        record["duplicate_group"] = dup_paths.get(record["path"], "")

    OUT.mkdir(parents=True, exist_ok=True)
    def write_csv(name: str, rows: list[dict]) -> None:
        with (OUT / name).open("w", newline="", encoding="utf-8") as stream:
            writer = csv.DictWriter(stream, fieldnames=list(rows[0]) if rows else [], lineterminator="\n")
            writer.writeheader()
            writer.writerows(rows)
    write_csv("tracked_file_audit.csv", records)
    write_csv("raw_artifact_audit.csv", raw_checks)
    write_csv("duplicate_groups.csv", duplicate_groups)
    write_csv("sensitive_pattern_scan.csv", sensitive_findings or [{
        "path": "", "pattern_classes_only": "none detected", "matched_value": "not applicable",
    }])
    write_csv("checkout_status.csv", [
        {"porcelain_status": line[:2], "path_or_rename": line[3:]}
        for line in checkout_status_lines
    ] or [{"porcelain_status": "clean", "path_or_rename": ""}])
    if blob_mismatches:
        write_csv("baseline_worktree_differences.csv", [
            {"path": p, "baseline_blob": old, "checkout_blob": new}
            for p, old, new in blob_mismatches
        ])
    print(
        f"revision={revision} checkout_status_entries={len(checkout_status_lines)} "
        f"tracked={len(records)} raw={len(raw_checks)} "
        f"duplicate_groups={len(duplicate_groups)} sensitive_pattern_files={len(sensitive_findings)} "
        f"baseline_checkout_differences={len(blob_mismatches)}"
    )


if __name__ == "__main__":
    main()
