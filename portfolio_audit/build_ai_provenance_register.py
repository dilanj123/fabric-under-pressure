#!/usr/bin/env python3
"""Build a file-origin register for the pinned Gate-5 public baseline.

The repository-wide AI-assisted workflow context is stored separately from
individual file origin. Unattributed authored files remain UNKNOWN.
"""
from __future__ import annotations

import argparse
import csv
import gzip
import json
import re
import subprocess
from collections import Counter
from pathlib import Path


PINNED_REVISION = "35911fc63a1621f931aeaaa41ad632e28bf0ea72"
PROJECT_CONTEXT_ID = "PCTX-001"
PROJECT_CONTEXT = {
    "id": PROJECT_CONTEXT_ID,
    "classification": "AI_ASSISTED_CONFIRMED",
    "scope": "Project-wide workflow context only; it is not an authorship label for any file.",
    "evidence": [
        "01_CHATGPT_PROJECT_OPERATING_INSTRUCTIONS.md",
        "docs/history/",
        "Merged PR descriptions #1–#6",
    ],
    "limitations": "Records establish substantial ChatGPT/Codex participation in project planning and execution, but not which person or model authored each file or line.",
}

FIELDS = [
    "path", "category", "git_blob_sha", "blob_size_bytes",
    "origin_classification", "file_specific_evidence", "file_specific_confidence",
    "project_ai_workflow_context_id", "review_or_execution_provenance",
    "authorship_statement_supported",
]

CLASSIFICATIONS = {
    "HUMAN_CONFIRMED", "AI_GENERATED_CONFIRMED", "AI_ASSISTED_CONFIRMED",
    "MIXED_CONFIRMED", "TOOL_GENERATED", "THIRD_PARTY", "UNKNOWN",
}

# This entry is supported by the PR that changed the README and explicitly
# documented ChatGPT/Codex involvement. No other authored file gets this label
# without similarly specific evidence.
DIRECT_FILE_EVIDENCE = {
    "README.md": {
        "classification": "AI_ASSISTED_CONFIRMED",
        "evidence": "PR #1 changed README.md and its description expressly records ChatGPT/Codex assistance in the project presentation.",
        "confidence": "MEDIUM; confirms an AI-assisted contribution to this file, not authorship of all README text.",
    }
}

AUDIT_GENERATORS = {
    "baseline_worktree_differences.csv": "portfolio_audit/build_register.py",
    "checkout_status.csv": "portfolio_audit/build_register.py",
    "duplicate_groups.csv": "portfolio_audit/build_register.py",
    "raw_artifact_audit.csv": "portfolio_audit/build_register.py",
    "sensitive_pattern_scan.csv": "portfolio_audit/build_register.py",
    "tracked_file_audit.csv": "portfolio_audit/build_register.py",
    "current_head_delta_from_gate5.csv": "portfolio_audit/build_semantic_review.py",
    "current_review_scope.json": "portfolio_audit/build_semantic_review.py",
}

# Exact pinned-snapshot output mapping. New files remain UNKNOWN until their
# producing command is checked and added here.
PROCESSED_GENERATORS = {
    "results/processed/ab_comparison/d045_evaluation.json": "bench/compare_ab.py",
    "results/processed/ab_comparison/key_event_traces.json": "bench/compare_ab.py",
    "results/processed/ab_comparison/manager_aggregate_throughput_median.csv": "bench/compare_ab.py",
    "results/processed/ab_comparison/manager_aggregate_throughput_per_seed.csv": "bench/compare_ab.py",
    "results/processed/ab_comparison/matched_median_of_five.csv": "bench/compare_ab.py",
    "results/processed/ab_comparison/matched_per_seed.csv": "bench/compare_ab.py",
    "results/processed/ab_comparison/matched_run_details.json": "bench/compare_ab.py",
    "results/processed/ab_comparison/run_matrix.csv": "bench/compare_ab.py",
    "results/processed/ab_comparison/source_manifest_comparison.json": "bench/compare_ab.py",
    "results/processed/ab_comparison/ppa_resource_comparison.json": "bench/plot_ab_comparison.py",
    "results/processed/ab_comparison/ppa_route_comparison.csv": "bench/plot_ab_comparison.py",
    "results/processed/arch_a_measurement/latency_throughput.csv": "bench/summarize_benchmark.py",
    "results/processed/arch_a_measurement/ppa_summary.json": "bench/summarize_ppa.py",
    "results/processed/arch_a_measurement/route_summary.csv": "bench/summarize_ppa.py",
    "results/processed/arch_a_measurement/run_summary.json": "bench/summarize_benchmark.py",
    "results/processed/architecture_b_functional/coverage_2048.json": "tb/cocotb/test_axi_fabric_a_random.py",
    "results/processed/architecture_b_functional/coverage_512.json": "tb/cocotb/test_axi_fabric_a_random.py",
    "results/processed/architecture_b_functional/seed_results.csv": "tb/cocotb/test_axi_fabric_a_random.py",
    "results/processed/ab_comparison/figures/admission_p99.png": "bench/plot_ab_comparison.py",
    "results/processed/ab_comparison/figures/resources_routed_timing.png": "bench/plot_ab_comparison.py",
    "results/processed/ab_comparison/figures/starvation_fairness.png": "bench/plot_ab_comparison.py",
    "results/processed/ab_comparison/figures/throughput.png": "bench/plot_ab_comparison.py",
    "results/processed/gate5_reproduction/ab_comparison/d045_evaluation.json": "bench/compare_ab.py",
    "results/processed/gate5_reproduction/ab_comparison/matched_median_of_five.csv": "bench/compare_ab.py",
    "results/processed/gate5_reproduction/ab_comparison/matched_per_seed.csv": "bench/compare_ab.py",
    "results/processed/gate5_reproduction/ab_comparison/matched_run_details.json": "bench/compare_ab.py",
    "results/processed/gate5_reproduction/ab_comparison/ppa_resource_comparison.json": "bench/plot_ab_comparison.py",
    "results/processed/gate5_reproduction/ab_comparison/ppa_route_comparison.csv": "bench/plot_ab_comparison.py",
    "results/processed/gate5_reproduction/ab_comparison/run_matrix.csv": "bench/compare_ab.py",
    "results/processed/gate5_reproduction/ab_comparison/source_manifest_comparison.json": "bench/compare_ab.py",
    "results/processed/gate5_reproduction/figures/admission_p99.png": "bench/plot_ab_comparison.py",
    "results/processed/gate5_reproduction/figures/resources_routed_timing.png": "bench/plot_ab_comparison.py",
    "results/processed/gate5_reproduction/figures/starvation_fairness.png": "bench/plot_ab_comparison.py",
    "results/processed/gate5_reproduction/figures/throughput.png": "bench/plot_ab_comparison.py",
}


def git(*args: str) -> bytes:
    return subprocess.check_output(["git", *args])


def batch_blobs(oids: list[str]) -> dict[str, bytes]:
    """Read requested Git blobs in one process without checking files out."""
    if not oids:
        return {}
    payload = ("\n".join(oids) + "\n").encode()
    result = subprocess.run(["git", "cat-file", "--batch"], input=payload,
                            stdout=subprocess.PIPE, check=True).stdout
    blobs: dict[str, bytes] = {}
    offset = 0
    for oid in oids:
        header_end = result.index(b"\n", offset)
        returned_oid, kind, size_text = result[offset:header_end].decode().split()
        size = int(size_text)
        start = header_end + 1
        end = start + size
        if returned_oid != oid or kind != "blob" or result[end:end + 1] != b"\n":
            raise ValueError(f"unexpected git cat-file response for {oid}")
        blobs[oid] = result[start:end]
        offset = end + 1
    return blobs


def classify(path: str, size: int, data: bytes = b"", direct_evidence: dict | None = None) -> dict[str, str]:
    """Return file-specific origin classification, separate from project context."""
    if direct_evidence is None:
        direct_evidence = DIRECT_FILE_EVIDENCE.get(path)
    if direct_evidence:
        origin = direct_evidence["classification"]
        if origin not in CLASSIFICATIONS or origin == "UNKNOWN":
            raise ValueError(f"invalid direct origin classification for {path}: {origin}")
        return {
            "category": "project documentation",
            "origin_classification": origin,
            "file_specific_evidence": direct_evidence["evidence"],
            "file_specific_confidence": direct_evidence["confidence"],
            "review_or_execution_provenance": "PR description records an AI-assisted edit; it does not establish authorship of the entire file.",
            "authorship_statement_supported": "Only that this file received an AI-assisted contribution; no claim about all text or the owner’s contribution is supported.",
        }

    if size == 0:
        category = "empty placeholder" if Path(path).name == ".keep" else "empty file or output"
        return unknown(category, "Empty blobs contain no content from which to infer an author or producer.")

    if path.startswith("results/raw/"):
        evidence = raw_output_evidence(path, data)
        if evidence:
            return tool_output("raw simulation/build/formal output", evidence)
        return unknown("raw evidence with unverified file origin", "No file-specific tool signature or producing-run record was identified; raw/ directory placement alone is not treated as proof.")

    audit_generator = AUDIT_GENERATORS.get(Path(path).name) if path.startswith("portfolio_audit/generated/") else None
    if audit_generator:
        return tool_output("generated audit inventory", f"{audit_generator} writes this named generated inventory.")

    suffix = Path(path).suffix.lower()
    if path in PROCESSED_GENERATORS:
        generator = PROCESSED_GENERATORS[path]
        return tool_output("processed measurement or comparison artifact", f"Pinned-snapshot output mapping identifies {generator} as the producer; the processed evidence summary records regeneration.")
    if path.startswith("third_party/") and Path(path).name != ".keep":
        return unknown("third-party area; no vendored source identified", "Directory location alone does not establish third-party origin; inspect the manifest for dependency provenance.")

    if path.startswith(".github/"):
        return unknown("CI configuration", "No file-specific authorship evidence located; workflow configuration is not classified from its directory.")

    if path.startswith("results/processed/"):
        return unknown("processed narrative or unverified derived artifact", "No direct per-file generator record was found for this file; extension and directory alone are not treated as origin evidence.")

    if path.startswith(("rtl/", "formal/", "tb/", "bench/", "scripts/", "smoke/", "constraints/", "docs/", "requirements/", "portfolio_audit/")) or path in {
        "README.md", "00_MASTER_PROJECT_PLAN.md", "01_CHATGPT_PROJECT_OPERATING_INSTRUCTIONS.md", "04_MASTER_CHECKLIST.md", "AGENTS.md", ".gitignore"
    }:
        return unknown("engineering source or project documentation", "Project-wide AI assistance is recorded separately; no direct evidence identifies this file’s author or specific AI contribution.")

    return unknown("project or repository file", "No file-specific origin evidence located.")


def unknown(category: str, evidence: str) -> dict[str, str]:
    return {
        "category": category,
        "origin_classification": "UNKNOWN",
        "file_specific_evidence": evidence,
        "file_specific_confidence": "No authorship attribution made.",
        "review_or_execution_provenance": "Reviewing or executing a file does not establish its author.",
        "authorship_statement_supported": "No file-specific authorship claim supported.",
    }


def raw_output_evidence(path: str, data: bytes) -> str | None:
    """Recognize tool output from content signatures, not raw/ path alone."""
    if not data:
        return None
    name = Path(path).name.lower()
    ext = Path(path).suffix.lower()
    if ext == ".gz":
        try:
            inner = gzip.decompress(data)
        except OSError:
            return None
        evidence = raw_output_evidence(path[:-3], inner)
        return f"gzip-wrapped {evidence}" if evidence else None
    text = data[:200_000].decode("utf-8", "replace")
    low = text.lower()
    if ext == ".log" or name in {"logfile.txt", "simulation.log", "build.log"}:
        lines = [line.strip() for line in text.splitlines() if line.strip()]
        if not lines:
            return None
        first = lines[0]
        if re.match(r"^SBY \d\d:\d\d:\d\d \[", first):
            return "First log line is the timestamped SymbiYosys run banner."
        if first.startswith("-- Running command `") or first.startswith("1. Executing "):
            return "First log line is a Yosys command/execution record."
        if re.match(r"^- V e r i l a t i o n\s+R e p o r t: Verilator \d", first):
            return "First log line is Verilator's versioned report banner."
        if first.startswith("Info: [nextpnr-ecp5]"):
            return "First log line is nextpnr-ecp5's tool banner."
        if re.match(r"^g\+\+ .* -DVERILATOR=1 .* -c -o ", first):
            return "First line is a captured Verilator-generated C++ compile command."
        if re.match(r"^PASS \S+ checks=\d+", first) and any("Verilog $finish" in line for line in lines):
            if any(re.match(r"^- S i m u l a t i o n\s+R e p o r t: Verilator \d", line) for line in lines):
                return "Log contains a testbench PASS/check count, Verilog finish record and Verilator report."
        return None
    if ext == ".json":
        try:
            obj = json.loads(data)
        except (ValueError, UnicodeDecodeError):
            return None
        if isinstance(obj, dict):
            creator = str(obj.get("creator", ""))
            if re.match(r"^Yosys \d+(?:\.\d+)+", creator):
                return "JSON creator field has the versioned Yosys format."
            if (
                type(obj.get("seed")) is int
                and type(obj.get("random_operations")) is int
                and isinstance(obj.get("accepted_reads"), list)
                and isinstance(obj.get("accepted_writes"), list)
            ):
                return "JSON has the generated random-run coverage schema (seed, operation count and observed accepted transfers)."
            if (
                type(obj.get("seed")) is int
                and isinstance(obj.get("architecture"), str)
                and isinstance(obj.get("operations"), list)
                and isinstance(obj.get("target_distribution"), dict)
            ):
                return "JSON has the immutable pre-generated random-plan schema and seed/target metadata."
            if all(isinstance(obj.get(key), list) for key in ("seeds", "accepted_reads", "accepted_writes", "lengths", "targets")):
                return "JSON has the generated aggregate random-coverage schema across frozen seeds."
            if (
                isinstance(obj.get("architecture"), str)
                and isinstance(obj.get("dut_top"), str)
                and re.fullmatch(r"[0-9a-fA-F]{64}", str(obj.get("source_manifest_sha256", "")))
                and isinstance(obj.get("workload"), str)
                and type(obj.get("seed")) is int
            ):
                return "JSON has the benchmark runner manifest/configuration schema and source identity fields."
            architecture = obj.get("architecture")
            expected_top = {"A": "axi_fabric_a", "B": "axi_fabric_b"}.get(architecture)
            if (
                expected_top
                and obj.get("dut_top") == expected_top
                and re.fullmatch(r"0x[0-9A-Fa-f]{8}", str(obj.get("seed", "")))
                and re.fullmatch(r"W(?:0[0-9]|1[0-3])", str(obj.get("workload", "")))
                and isinstance(obj.get("source_manifest_sha256"), str)
                and re.fullmatch(r"[0-9a-fA-F]{64}", obj["source_manifest_sha256"])
                and type(obj.get("warmup")) is int
                and type(obj.get("samples")) is int
                and type(obj.get("qualification_only")) is bool
            ):
                return "JSON has the benchmark run-configuration schema with architecture/top, workload/seed and quota fields."
            if (
                expected_top
                and obj.get("dut_top") == expected_top
                and re.fullmatch(r"0x[0-9A-Fa-f]{8}", str(obj.get("seed", "")))
                and re.fullmatch(r"W(?:0[0-9]|1[0-3])", str(obj.get("workload", "")))
                and all(re.fullmatch(r"[0-9a-fA-F]{64}", str(obj.get(key, ""))) for key in (
                    "source_manifest_sha256", "run_config_sha256", "workload_sha256",
                    "intent_sha256", "benchmark_driver_sha256", "generator_sha256",
                ))
                and type(obj.get("intent_count")) is int
                and type(obj.get("retained_completions_per_manager")) is int
            ):
                return "JSON has the benchmark run-metadata schema with architecture/top and component/plan hashes."
            if (
                isinstance(obj.get("architecture"), str)
                and isinstance(obj.get("dut_top"), str)
                and isinstance(obj.get("rtl_sources"), list)
                and isinstance(obj.get("benchmark_engine"), dict)
                and isinstance(obj.get("generator"), dict)
                and isinstance(obj.get("endpoint"), dict)
                and all(isinstance(obj.get(key), dict) for key in ("runner", "wrapper", "workload"))
                and isinstance(obj.get("workloads"), list)
                and isinstance(obj.get("seeds"), list)
                and all(isinstance(item, dict) and isinstance(item.get("path"), str) and re.fullmatch(r"[0-9a-fA-F]{64}", str(item.get("sha256", ""))) for item in obj["rtl_sources"])
            ):
                return "JSON has the generated benchmark source manifest with selected DUT and component identities."
        return None
    # JUnit XML and event JSONL structures are useful evidence formats, but
    # their shape alone does not identify the process that created a file.
    # Without a file-specific producer record they remain UNKNOWN.
    if ext == ".yw" and "yosys witness trace" in low and '"generator": "smtbmc"' in low:
        return "Yosys witness trace identifies its format and smtbmc generator."
    if ext == ".smtc" and "/engine_0/" in path and "initial" in low and "[dut." in low and "assume" in low:
        return "SMTC trace contains solver-generated initial assumptions and DUT witness signals."
    if name == "pass":
        lines = [line.strip() for line in text.splitlines() if line.strip()]
        has_elapsed = any(re.match(r"^Elapsed process time \[H:MM:SS \(secs\)\]:", line) for line in lines)
        has_engine_result = any(re.match(r"^engine_\d+ \(smtbmc(?: [^)]+)?\) returned pass(?: for (?:basecase|induction))?$", line) for line in lines)
        if has_elapsed and has_engine_result:
            return "Formal PASS file contains structured elapsed-time and SymbiYosys engine-result records."
    if ext == ".txt" and re.match(r"^SBY \d\d:\d\d:\d\d \[", text.lstrip()):
        return "First text line is the timestamped SymbiYosys run banner."
    return None


def tool_output(category: str, evidence: str) -> dict[str, str]:
    return {
        "category": category,
        "origin_classification": "TOOL_GENERATED",
        "file_specific_evidence": evidence,
        "file_specific_confidence": "HIGH for generated artifact; command operator may be unknown.",
        "review_or_execution_provenance": "Generation provenance is distinct from who launched or reviewed the producing tool.",
        "authorship_statement_supported": "May describe this artifact as tool-generated; no personal execution claim follows.",
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--revision", default=PINNED_REVISION, help="Git tree revision (defaults to pinned 35911fc baseline)")
    parser.add_argument("--allow-nonbaseline", action="store_true", help="Required when inventorying any revision other than the pinned baseline")
    parser.add_argument("--output", default="portfolio_audit/generated/ai_provenance_register.csv")
    parser.add_argument("--context-output", default="portfolio_audit/generated/project_ai_workflow_context.json")
    args = parser.parse_args()
    rev = git("rev-parse", args.revision).decode().strip()
    if args.revision != PINNED_REVISION and not args.allow_nonbaseline:
        parser.error(f"refusing revision argument {args.revision!r} (resolved to {rev}); use the pinned revision explicitly or pass --allow-nonbaseline")
    default_register = Path("portfolio_audit/generated/ai_provenance_register.csv").resolve()
    default_context = Path("portfolio_audit/generated/project_ai_workflow_context.json").resolve()
    output_path = Path(args.output).resolve()
    context_path = Path(args.context_output).resolve()
    if (rev != PINNED_REVISION or args.revision != PINNED_REVISION) and (
        output_path in {default_register, default_context}
        or context_path in {default_register, default_context}
    ):
        parser.error("alternate revision inventories require explicit nondefault --output and --context-output paths")
    if output_path == context_path:
        parser.error("--output and --context-output must name different files")

    records = git("ls-tree", "-rlz", "--full-tree", rev).split(b"\0")
    entries = []
    for record in records:
        if not record:
            continue
        meta, raw_path = record.split(b"\t", 1)
        mode, kind, oid, raw_size = meta.decode().split()
        path = raw_path.decode("utf-8", "surrogateescape")
        if kind != "blob":
            continue
        size = int(raw_size)
        entries.append((path, oid, size))
    raw_blobs = batch_blobs([oid for path, oid, _size in entries if path.startswith("results/raw/")])
    rows = []
    for path, oid, size in entries:
        data = raw_blobs.get(oid, b"")
        row = {"path": path, "git_blob_sha": oid, "blob_size_bytes": size}
        row.update(classify(path, size, data))
        row["project_ai_workflow_context_id"] = PROJECT_CONTEXT_ID
        rows.append(row)
    rows.sort(key=lambda row: row["path"])
    output = output_path
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.DictWriter(stream, fieldnames=FIELDS, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)
    counts = Counter(row["origin_classification"] for row in rows)
    context = {
        **PROJECT_CONTEXT,
        "inventory_revision": rev,
        "inventory_path_count": len(rows),
        "file_origin_classification_counts": dict(sorted(counts.items())),
    }
    context_output = context_path
    context_output.parent.mkdir(parents=True, exist_ok=True)
    context_output.write_text(json.dumps(context, indent=2) + "\n", encoding="utf-8")
    print(f"revision={rev} files={len(rows)} output={output}")


if __name__ == "__main__":
    main()
