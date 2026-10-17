#!/usr/bin/env bash
# Resolve endpoint credentials without ever receiving the whole secrets context.
#
# GitHub Actions only exposes secrets that are explicitly listed in a workflow's
# `env:` block (for example `SIP_USER: ${{ secrets.SIP_USER }}`). `upsipp.yml`
# stores the *name* of that environment variable in `auth.user_secret` /
# `auth.pass_secret`; resolve_secret looks the value up from the environment.
set -euo pipefail

# resolve_secret NAME -> prints the environment value of NAME (empty if unset).
resolve_secret() {
  local name="${1:-}"
  if [[ -z "$name" || "$name" == "null" ]]; then
    return 0
  fi
  printf '%s' "${!name:-}"
}