#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${ROOT}/upsipp.yml"

source "${ROOT}/scripts/bootstrap.sh"

if [[ ! -f "$CONFIG" ]]; then
  echo "Missing ${CONFIG}" >&2
  exit 1
fi

if [[ -z "${GITHUB_REPOSITORY:-}" ]]; then
  echo "GITHUB_REPOSITORY not set; skipping auto-configure"
  exit 0
fi

owner="${GITHUB_REPOSITORY%%/*}"
repo="${GITHUB_REPOSITORY#*/}"
current_owner="$(yq -r '.owner // ""' "$CONFIG")"
current_repo="$(yq -r '.repo // ""' "$CONFIG")"

is_placeholder_owner() {
  case "$1" in
    YOUR_GITHUB_USERNAME|YOUR_USERNAME|lmangani|upptime|"") return 0 ;;
    *) return 1 ;;
  esac
}

is_placeholder_repo() {
  case "$1" in
    YOUR_REPO_NAME|YOUR_REPOSITORY|upsipp|upptime|"") return 0 ;;
    *) return 1 ;;
  esac
}

changed=false

if is_placeholder_owner "$current_owner"; then
  yq -i ".owner = \"${owner}\"" "$CONFIG"
  changed=true
fi

if is_placeholder_repo "$current_repo"; then
  yq -i ".repo = \"${repo}\"" "$CONFIG"
  changed=true
fi

base_url="$(yq -r '."status-website".baseUrl // ""' "$CONFIG")"
if [[ "$base_url" == "/YOUR_REPO_NAME" || "$base_url" == "/upsipp" || "$base_url" == "/upptime" ]]; then
  yq -i ".\"status-website\".baseUrl = \"/${repo}\"" "$CONFIG"
  changed=true
fi

if [[ "$changed" == "true" ]]; then
  echo "Configured upsipp.yml for ${owner}/${repo}"
else
  echo "upsipp.yml already configured (${current_owner}/${current_repo})"
fi
