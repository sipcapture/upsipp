#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${ROOT}/upsipp.yml"
MODE="${1:-update}"

source "${ROOT}/scripts/bootstrap.sh"
source "${ROOT}/scripts/lib/gossipper-run.sh"
source "${ROOT}/scripts/lib/history-write.sh"
source "${ROOT}/scripts/lib/issues.sh"

if [[ ! -f "$CONFIG" ]]; then
  echo "Missing ${CONFIG}" >&2
  exit 1
fi

if [[ -n "${GITHUB_REPOSITORY:-}" ]]; then
  "${ROOT}/scripts/configure-from-github.sh"
fi

"${ROOT}/scripts/generate-upptimerc.sh"

# Export repository secrets referenced in upsipp.yml (same pattern as Upptime).
if [[ -n "${SECRETS_CONTEXT:-}" ]]; then
  while IFS= read -r key; do
    [[ -z "$key" ]] && continue
    val="$(echo "$SECRETS_CONTEXT" | jq -r --arg k "$key" '.[$k] // empty')"
    if [[ -n "$val" ]]; then
      export "$key=$val"
    fi
  done < <(echo "$SECRETS_CONTEXT" | jq -r 'keys[]?')
fi

if [[ -x "${ROOT}/bin/gossipper" ]]; then
  export PATH="${ROOT}/bin:${PATH}"
fi

COUNT="$(yq '.endpoints | length' "$CONFIG")"
if [[ "$COUNT" -eq 0 ]]; then
  echo "No endpoints configured in upsipp.yml" >&2
  exit 1
fi

COMMIT_TEMPLATE=$(yq -r '.commitMessages.statusChange // "$EMOJI $SITE_NAME is $STATUS ($RESPONSE_CODE in $RESPONSE_TIME ms) [skip ci] [upsipp]"' "$CONFIG")
SKIP_DELETE="$(yq -r '.skipDeleteIssues // false' "$CONFIG")"
ASSIGNEES_JSON="$(yq -o=json '.assignees // []' "$CONFIG")"
NOW="$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")"

mkdir -p "${ROOT}/history"
CHANGES=0

git -C "$ROOT" config user.name "UPSIPP Bot"
git -C "$ROOT" config user.email "upsipp-bot@users.noreply.github.com"

for ((i = 0; i < COUNT; i++)); do
  name="$(yq -r ".endpoints[$i].name" "$CONFIG")"
  slug="$(yq -r ".endpoints[$i].slug // \"\"" "$CONFIG")"
  remote="$(yq -r ".endpoints[$i].remote" "$CONFIG")"
  transport="$(yq -r ".endpoints[$i].transport // \"u1\"" "$CONFIG")"
  scenario="$(yq -r ".endpoints[$i].scenario // \"options\"" "$CONFIG")"
  timeout="$(yq -r ".endpoints[$i].timeout_global // 15" "$CONFIG")"
  service="$(yq -r ".endpoints[$i].service // \"options\"" "$CONFIG")"

  if [[ -z "$slug" || "$slug" == "null" ]]; then
    slug="$(echo "$name" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-|-$//g')"
  fi

  user_secret="$(yq -r ".endpoints[$i].auth.user_secret // \"\"" "$CONFIG")"
  pass_secret="$(yq -r ".endpoints[$i].auth.pass_secret // \"\"" "$CONFIG")"
  user=""
  pass=""
  if [[ -n "$user_secret" && "$user_secret" != "null" && -n "${!user_secret:-}" ]]; then
    user="${!user_secret}"
  fi
  if [[ -n "$pass_secret" && "$pass_secret" != "null" && -n "${!pass_secret:-}" ]]; then
    pass="${!pass_secret}"
  fi

  url="sip:${remote}"
  history_file="${ROOT}/history/${slug}.yml"
  summary_json="$(mktemp)"

  echo "Checking ${name} (${slug}) → ${remote}..."

  set +e
  run_gossipper "$ROOT" "$remote" "$transport" "$scenario" "$timeout" "$service" "$summary_json" "$user" "$pass"
  exit_code=$?
  set -e

  IFS='|' read -r status code response_time <<< "$(parse_summary "$summary_json" "$exit_code")"

  prev_status=""
  if [[ -f "$history_file" ]]; then
    prev_status="$(grep '^status:' "$history_file" | head -1 | awk '{print $2}' || true)"
  fi

  write_history "$history_file" "$url" "$status" "$code" "$response_time" "$NOW"

  if [[ "$MODE" != "response-time" ]]; then
    if [[ "$status" != "$prev_status" || -z "$prev_status" ]]; then
      manage_incident "$slug" "$name" "$status" "$code" "$response_time" "$summary_json" "$SKIP_DELETE" "$ASSIGNEES_JSON" || true
    fi
  fi

  if [[ "$status" == "up" ]]; then
    emoji="🟩"
  else
    emoji="🟥"
  fi

  commit_msg="$(format_commit_message "$COMMIT_TEMPLATE" "$emoji" "$name" "$status" "$code" "$response_time")"
  git -C "$ROOT" add "$history_file"

  if ! git -C "$ROOT" diff --cached --quiet; then
    git -C "$ROOT" commit -m "$commit_msg" || true
    CHANGES=$((CHANGES + 1))
  fi

  rm -f "$summary_json"
done

if [[ -n "${GITHUB_REPOSITORY:-}" ]]; then
  git -C "$ROOT" add upsipp.yml 2>/dev/null || true
  if ! git -C "$ROOT" diff --cached --quiet -- upsipp.yml 2>/dev/null; then
    git -C "$ROOT" commit -m ":wrench: Configure upsipp.yml for ${GITHUB_REPOSITORY} [skip ci] [upsipp]" || true
    CHANGES=$((CHANGES + 1))
  fi
fi

if [[ "$CHANGES" -gt 0 ]]; then
  git -C "$ROOT" push origin HEAD 2>/dev/null || git -C "$ROOT" push 2>/dev/null || true
fi

echo "Checked ${COUNT} endpoint(s)."
