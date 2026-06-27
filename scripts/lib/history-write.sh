#!/usr/bin/env bash
set -euo pipefail

write_history() {
  local history_file="$1"
  local url="$2"
  local status="$3"
  local code="$4"
  local response_time="$5"
  local now="$6"
  local generator="UPSIPP <https://github.com/sipcapture/upsipp>"

  local start_time="$now"
  if [[ -f "$history_file" ]]; then
    start_time="$(grep '^startTime:' "$history_file" | head -1 | sed 's/startTime: //' || echo "$now")"
  fi

  cat > "$history_file" <<EOF
url: ${url}
status: ${status}
code: ${code}
responseTime: ${response_time}
lastUpdated: ${now}
startTime: ${start_time}
generator: ${generator}
EOF
}

format_commit_message() {
  local template="$1"
  local emoji="$2"
  local name="$3"
  local status="$4"
  local code="$5"
  local response_time="$6"

  local upper_status
  upper_status="$(echo "$status" | tr '[:lower:]' '[:upper:]')"

  echo "$template" \
    | sed "s/\$EMOJI/${emoji}/g" \
    | sed "s/\$SITE_NAME/${name}/g" \
    | sed "s/\$STATUS/${upper_status}/g" \
    | sed "s/\$RESPONSE_CODE/${code}/g" \
    | sed "s/\$RESPONSE_TIME/${response_time}/g"
}
