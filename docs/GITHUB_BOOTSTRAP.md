# GitHub Bootstrap and Gate-0 Launch

This is the shortest path from the prepared local repository to real intended-host evidence.

## Purpose
Create the dedicated public GitHub repository, push the clean `main` branch, dispatch the Apple-Silicon Gate-0 workflow, wait for completion, and download its evidence artifact.

## Preconditions
- run from the repository root on a machine with `git` and GitHub CLI `gh`;
- authenticate first with `gh auth login` if required;
- current branch must be `main`;
- working tree must be clean;
- the default target repository is `dilanj123/fabric-under-pressure`.

## One command

```bash
./scripts/publish_github_and_start_gate0.sh
```

The script will create `dilanj123/fabric-under-pressure` if it does not exist, add the `origin` remote, push `main`, dispatch `.github/workflows/gate0-macos-arm64.yml`, watch the run, and download evidence under `results/raw/gate0/github-actions/`.

To override the target repository or visibility:

```bash
FABRIC_GITHUB_REPO=owner/name \
FABRIC_GITHUB_VISIBILITY=private \
./scripts/publish_github_and_start_gate0.sh
```

## Evidence rule
A green GitHub Actions run is necessary but not by itself permission to declare Gate 0 closed. Review the downloaded evidence against `tasks/FABRIC-001.md`. Only after every acceptance criterion is supported by actual logs may `docs/PROJECT_STATE.md` / `docs/EVIDENCE_INDEX.md` be updated and the `kg-g0-env` known-good tag be created.
