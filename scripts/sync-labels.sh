#!/usr/bin/env bash
# Sync issue labels declared in .github/labels.yml via the GitHub CLI.
#
# Replaces the unmaintained micnncim/action-label-sync action. Run with
# --dry-run to print the commands without changing anything.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LABELS="${ROOT}/.github/labels.yml"
DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
fi

source "${ROOT}/scripts/bootstrap.sh"

if [[ ! -f "$LABELS" ]]; then
  echo "Missing ${LABELS}" >&2
  exit 1
fi

if [[ "$DRY_RUN" != "true" ]] && ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI not available; skipping label sync" >&2
  exit 0
fi

count="$(yq '. | length' "$LABELS")"
if [[ "$count" -eq 0 ]]; then
  echo "No labels defined in ${LABELS}" >&2
  exit 1
fi

for ((i = 0; i < count; i++)); do
  name="$(yq -r ".[$i].name // \"\"" "$LABELS")"
  color="$(yq -r ".[$i].color // \"ededed\"" "$LABELS")"
  description="$(yq -r ".[$i].description // \"\"" "$LABELS")"

  if [[ -z "$name" || "$name" == "null" ]]; then
    echo "Skipping label without a name at index ${i}" >&2
    continue
  fi

  if [[ "$DRY_RUN" == "true" ]]; then
    printf 'gh label create %q --color %q --description %q --force\n' \
      "$name" "$color" "$description"
    continue
  fi

  gh label create "$name" --color "$color" --description "$description" --force
  echo "Synced label: ${name}"
done

if [[ "$DRY_RUN" == "true" ]]; then
  echo "Dry run complete (no labels changed)."
else
  echo "Label sync complete."
fi
