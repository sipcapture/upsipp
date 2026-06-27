#!/usr/bin/env bash
# Apply workflowSchedule from upsipp.yml to .github/workflows/*.yml cron lines.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="${ROOT}/upsipp.yml"

source "${ROOT}/scripts/bootstrap.sh"

if [[ ! -f "$CONFIG" ]]; then
  echo "Missing ${CONFIG}" >&2
  exit 1
fi

schedule_for() {
  local key="$1"
  local default="$2"
  yq -r ".workflowSchedule.${key} // \"${default}\"" "$CONFIG"
}

update_workflow_cron() {
  local workflow_file="$1"
  local cron="$2"
  local path="${ROOT}/.github/workflows/${workflow_file}"

  if [[ ! -f "$path" ]]; then
    echo "Missing workflow: ${path}" >&2
    return 1
  fi

  awk -v cron="$cron" '
    /- cron:/ && !done {
      print "    - cron: \"" cron "\""
      done = 1
      next
    }
    { print }
  ' "$path" > "${path}.tmp"
  mv "${path}.tmp" "$path"
  echo "  ${workflow_file} → ${cron}"
}

echo "Applying workflowSchedule from upsipp.yml..."

update_workflow_cron "sip-check.yml" "$(schedule_for uptime "0 * * * *")"
update_workflow_cron "response-time.yml" "$(schedule_for responseTime "0 23 * * *")"
update_workflow_cron "graphs.yml" "$(schedule_for graphs "0 0 * * *")"
update_workflow_cron "summary.yml" "$(schedule_for summary "0 0 * * *")"
update_workflow_cron "site.yml" "$(schedule_for staticSite "0 1 * * *")"

echo "Workflow schedules updated."
