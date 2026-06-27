#!/usr/bin/env bash
set -euo pipefail

issue_title_down() {
  echo "🟥 $1 is down"
}

find_open_incident() {
  local slug="$1"
  local name="$2"
  gh issue list --state open --limit 100 --json number,title \
    | jq -r --arg slug "$slug" --arg name "$name" '
      .[] | select(
        (.title | test("🟥")) and
        ((.title | contains($name)) or (.title | contains($slug)))
      ) | .number' | head -1
}

to_epoch() {
  local ts="$1"
  if date --version >/dev/null 2>&1; then
    date -d "$ts" +%s 2>/dev/null || echo 0
  else
    date -j -f "%Y-%m-%dT%H:%M:%SZ" "${ts%%.*}Z" +%s 2>/dev/null || echo 0
  fi
}

manage_incident() {
  local slug="$1"
  local name="$2"
  local status="$3"
  local code="$4"
  local response_time="$5"
  local summary_json="$6"
  local skip_delete="${7:-false}"
  local assignees_json="${8:-[]}"

  if ! command -v gh >/dev/null 2>&1; then
    echo "gh CLI not available; skipping incident management"
    return 0
  fi

  local existing
  existing="$(find_open_incident "$slug" "$name" || true)"

  if [[ "$status" == "down" ]]; then
    if [[ -n "$existing" ]]; then
      echo "Incident already open: #${existing}"
      return 0
    fi

    local body
    body="**Endpoint:** ${name} (\`${slug}\`)

| Field | Value |
| --- | --- |
| Status | down |
| SIP code | ${code} |
| Response time | ${response_time} ms |
| Checked at | $(date -u +"%Y-%m-%dT%H:%M:%S.000Z") |
"
    if [[ -f "$summary_json" ]]; then
      body+="
### Gossipper summary

\`\`\`json
$(cat "$summary_json")
\`\`\`
"
    fi

    local -a create_args=(issue create --title "$(issue_title_down "$name")" --body "$body")
    create_args+=(--label "upsipp")
    create_args+=(--label "incident")

    local assignee
    while IFS= read -r assignee; do
      [[ -n "$assignee" && "$assignee" != "null" ]] && create_args+=(--assignee "$assignee")
    done < <(echo "$assignees_json" | jq -r '.[]? // empty')

    gh "${create_args[@]}"
    return 0
  fi

  if [[ -n "$existing" ]]; then
    gh issue close "$existing" --comment "✅ Endpoint recovered (${code} in ${response_time} ms)."
    if [[ "$skip_delete" != "true" ]]; then
      local created_at created_ts now_ts diff_min
      created_at="$(gh issue view "$existing" --json createdAt -q .createdAt 2>/dev/null || echo "")"
      if [[ -n "$created_at" ]]; then
        created_ts="$(to_epoch "$created_at")"
        now_ts="$(date +%s)"
        diff_min=$(( (now_ts - created_ts) / 60 ))
        if [[ "$diff_min" -lt 15 ]]; then
          gh issue delete "$existing" --yes 2>/dev/null || true
        fi
      fi
    fi
  fi
}
