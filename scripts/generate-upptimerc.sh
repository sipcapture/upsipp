#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${ROOT}/upsipp.yml"
OUT="${ROOT}/.upptimerc.yml"

source "${ROOT}/scripts/bootstrap.sh"

if [[ ! -f "$CONFIG" ]]; then
  echo "Missing ${CONFIG}" >&2
  exit 1
fi

slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-|-$//g'
}

append_block() {
  local key="$1"
  if yq -e ".${key}" "$CONFIG" >/dev/null 2>&1; then
    {
      echo "${key}:"
      yq ".${key}" "$CONFIG" | sed 's/^/  /'
      echo ""
    } >> "$OUT"
  fi
}

OWNER="$(yq -r '.owner // ""' "$CONFIG")"
REPO="$(yq -r '.repo // ""' "$CONFIG")"
COUNT="$(yq '.endpoints | length' "$CONFIG")"

{
  echo "# Generated from upsipp.yml — do not edit manually."
  echo "owner: ${OWNER}"
  echo "repo: ${REPO}"
  echo "sites:"
} > "$OUT"

for ((i = 0; i < COUNT; i++)); do
  enabled="$(yq -r ".endpoints[$i].enabled // true" "$CONFIG")"
  if [[ "$enabled" == "false" ]]; then
    continue
  fi

  name="$(yq -r ".endpoints[$i].name" "$CONFIG")"
  slug="$(yq -r ".endpoints[$i].slug // \"\"" "$CONFIG")"
  remote="$(yq -r ".endpoints[$i].remote" "$CONFIG")"
  if [[ -z "$slug" || "$slug" == "null" ]]; then
    slug="$(slugify "$name")"
  fi
  {
    echo "  - name: ${name}"
    echo "    url: sip:${remote}"
    echo "    slug: ${slug}"
  } >> "$OUT"
done

echo "" >> "$OUT"

append_block "assignees"
append_block "skipDeleteIssues"
append_block "commitMessages"
append_block "workflowSchedule"
append_block "i18n"
append_block "user-agent"
append_block "runner"

if yq -e '."status-website"' "$CONFIG" >/dev/null 2>&1; then
  {
    echo "status-website:"
    yq '."status-website"' "$CONFIG" | sed 's/^/  /'
  } >> "$OUT"
fi

echo "Wrote ${OUT}"

# Quick sanity check
yq -e '.owner and .repo and (.sites | length) > 0' "$OUT" >/dev/null
