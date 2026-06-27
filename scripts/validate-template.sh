#!/usr/bin/env bash
# Validate that this repository is a clean, usable GitHub template.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> Template structure checks..."

fail() {
  echo "ERROR: $1" >&2
  exit 1
}

# No generated or local runtime artifacts should be tracked.
if git ls-files --error-unmatch bin/ >/dev/null 2>&1; then
  fail "bin/ must not be tracked (add to .gitignore)"
fi
if git ls-files --error-unmatch .upptimerc.yml >/dev/null 2>&1; then
  fail ".upptimerc.yml must not be tracked (generated in CI)"
fi

# History should start empty (only .gitkeep).
tracked_history="$(git ls-files 'history/*' 2>/dev/null | grep -v '.gitkeep$' || true)"
if [[ -n "$tracked_history" ]]; then
  fail "history/ must not contain committed check results:\n${tracked_history}"
fi

# Required template files.
for f in \
  upsipp.yml \
  .templaterc.json \
  .github/labels.yml \
  .github/workflows/sip-check.yml \
  .github/workflows/setup.yml \
  .github/workflows/site.yml \
  scenarios/options_client.xml \
  scenarios/example_uac.xml \
  scripts/configure-from-github.sh \
  scripts/generate-workflows.sh \
  scripts/check.sh \
  GETTING_STARTED.md; do
  [[ -f "$f" ]] || fail "Missing required template file: $f"
done

source scripts/bootstrap.sh

echo "==> Placeholder config checks..."
owner="$(yq -r '.owner' upsipp.yml)"
repo="$(yq -r '.repo' upsipp.yml)"
if [[ "$owner" != "YOUR_GITHUB_USERNAME" ]]; then
  fail "Template upsipp.yml owner must be YOUR_GITHUB_USERNAME (got: ${owner})"
fi
if [[ "$repo" != "YOUR_REPO_NAME" ]]; then
  fail "Template upsipp.yml repo must be YOUR_REPO_NAME (got: ${repo})"
fi

base_url="$(yq -r '."status-website".baseUrl' upsipp.yml)"
if [[ "$base_url" != "/YOUR_REPO_NAME" ]]; then
  fail "Template status-website.baseUrl must be /YOUR_REPO_NAME (got: ${base_url})"
fi

echo "==> Running standard validation..."
./scripts/validate.sh

echo ""
echo "Template validation passed."
