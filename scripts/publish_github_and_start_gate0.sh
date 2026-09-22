#!/usr/bin/env bash
set -euo pipefail

REPO="${FABRIC_GITHUB_REPO:-dilanj123/fabric-under-pressure}"
VISIBILITY="${FABRIC_GITHUB_VISIBILITY:-public}"
DESC="Fabric Under Pressure — Deterministic QoS-Aware AXI4 SoC Interconnect"
WORKFLOW="gate0-macos-arm64.yml"

need() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "ERROR: required command '$1' not found" >&2
    exit 2
  }
}

need git
need gh

echo "[1/7] Checking GitHub authentication"
gh auth status

owner="${REPO%%/*}"
name="${REPO##*/}"

if gh repo view "$REPO" >/dev/null 2>&1; then
  echo "[2/7] Repository already exists: $REPO"
else
  echo "[2/7] Creating $VISIBILITY repository: $REPO"
  case "$VISIBILITY" in
    public) vis_flag="--public" ;;
    private) vis_flag="--private" ;;
    *) echo "ERROR: FABRIC_GITHUB_VISIBILITY must be public or private" >&2; exit 2 ;;
  esac
  gh repo create "$REPO" "$vis_flag" --description "$DESC"
fi

repo_url="https://github.com/${REPO}.git"
if git remote get-url origin >/dev/null 2>&1; then
  current="$(git remote get-url origin)"
  if [[ "$current" != "$repo_url" && "$current" != "git@github.com:${REPO}.git" ]]; then
    echo "ERROR: existing origin points to '$current', not '$repo_url'" >&2
    exit 3
  fi
else
  git remote add origin "$repo_url"
fi

echo "[3/7] Verifying repository state"
test "$(git branch --show-current)" = "main" || {
  echo "ERROR: expected current branch 'main'" >&2
  exit 3
}
if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: working tree is not clean" >&2
  git status --short >&2
  exit 3
fi

echo "[4/7] Pushing main"
git push -u origin main

echo "[5/7] Dispatching Gate-0 Apple-Silicon workflow"
gh workflow run "$WORKFLOW" --repo "$REPO" --ref main

# Allow GitHub a moment to register the new run, then resolve the newest run for this workflow/ref.
sleep 3
run_id="$(gh run list \
  --repo "$REPO" \
  --workflow "$WORKFLOW" \
  --branch main \
  --limit 1 \
  --json databaseId \
  --jq '.[0].databaseId')"

if [[ -z "$run_id" || "$run_id" = "null" ]]; then
  echo "ERROR: workflow was dispatched but no run id could be resolved" >&2
  exit 4
fi

echo "Gate-0 run id: $run_id"
echo "[6/7] Watching Gate-0 run"
set +e
gh run watch "$run_id" --repo "$REPO" --exit-status
run_rc=$?
set -e

artifact_dir="results/raw/gate0/github-actions/run-${run_id}"
mkdir -p "$artifact_dir"
echo "[7/7] Downloading Gate-0 artifacts to $artifact_dir"
# Download whatever the workflow uploaded, including failure evidence.
gh run download "$run_id" --repo "$REPO" --dir "$artifact_dir" || true

echo
if [[ $run_rc -eq 0 ]]; then
  echo "Gate-0 CI completed successfully. Evidence is downloaded locally."
  echo "IMPORTANT: do not create kg-g0-env until the evidence is reviewed against FABRIC-001."
else
  echo "Gate-0 CI failed. Evidence/logs are downloaded where available."
  echo "Keep Gate 0 OPEN and repair only the evidenced failure before rerunning."
fi

exit "$run_rc"
