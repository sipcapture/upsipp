#!/usr/bin/env bash
set -euo pipefail

resolve_scenario() {
  local scenario="$1"
  local root="$2"
  case "$scenario" in
    options)
      echo "${root}/scenarios/options_client.xml"
      ;;
    uac|uas)
      echo "builtin:${scenario}"
      ;;
    builtin:*)
      echo "$scenario"
      ;;
    /*)
      echo "$scenario"
      ;;
    *)
      if [[ -f "${root}/${scenario}" ]]; then
        echo "${root}/${scenario}"
      elif [[ -f "${root}/scenarios/${scenario}" ]]; then
        echo "${root}/scenarios/${scenario}"
      else
        echo "${root}/scenarios/${scenario}.xml"
      fi
      ;;
  esac
}

run_gossipper() {
  local root="$1"
  local remote="$2"
  local transport="$3"
  local scenario="$4"
  local timeout="$5"
  local service="$6"
  local summary_json="$7"
  local user="${8:-}"
  local pass="${9:-}"

  local bin="${root}/bin/gossipper"
  if [[ ! -x "$bin" ]]; then
    bin="$(command -v gossipper || true)"
  fi
  if [[ -z "$bin" || ! -x "$bin" ]]; then
    echo "gossipper binary not found" >&2
    return 127
  fi

  local -a args=(
    sipp
    -rsa "$remote"
    -t "$transport"
    -m 1
    -r 1
    -timeout_global "$timeout"
    -summary_json "$summary_json"
    -health_max_failed_calls 0
    -health_max_timeouts 0
  )

  if [[ -n "$service" && "$service" != "null" ]]; then
    args+=(-s "$service")
  fi

  if [[ -n "$user" ]]; then
    args+=(-au "$user")
  fi
  if [[ -n "$pass" ]]; then
    args+=(-ap "$pass")
  fi

  local resolved
  resolved="$(resolve_scenario "$scenario" "$root")"

  if [[ "$resolved" == builtin:* ]]; then
    local sn="${resolved#builtin:}"
    args+=(-sn "$sn")
  else
    if [[ ! -f "$resolved" ]]; then
      echo "Scenario file not found: ${resolved}" >&2
      return 1
    fi
    args+=(-sf "$resolved")
  fi

  set +e
  "$bin" "${args[@]}"
  local exit_code=$?
  return "$exit_code"
}

parse_summary() {
  local summary_json="$1"
  local exit_code="$2"

  local status code response_time
  if [[ ! -f "$summary_json" ]]; then
    echo "down|0|0"
    return
  fi

  local success_ratio failed_calls health_ok
  success_ratio="$(jq -r '.success_ratio // 0' "$summary_json" 2>/dev/null || echo 0)"
  failed_calls="$(jq -r '.failed_calls // 0' "$summary_json" 2>/dev/null || echo 0)"
  health_ok="$(jq -r '.health.passed // empty' "$summary_json" 2>/dev/null || true)"

  response_time="$(jq -r '
    if .invite_rtt_ms != null then .invite_rtt_ms
    elif .invite_rtt != null then .invite_rtt
    elif .duration_ms != null then .duration_ms
    elif .duration != null then (.duration | if type == "number" then . / 1000000 else 0 end)
    else 0 end
  ' "$summary_json" 2>/dev/null || echo 0)"
  response_time="${response_time%.*}"
  [[ -z "$response_time" ]] && response_time=0

  if [[ "$exit_code" -eq 0 && "$failed_calls" == "0" && "$success_ratio" != "0" ]]; then
    if [[ -n "$health_ok" && "$health_ok" != "true" ]]; then
      status="down"
      code=503
    else
      status="up"
      code=200
    fi
  else
    status="down"
    code="$(jq -r '.last_sip_code // .unexpected_sip_code // 0' "$summary_json" 2>/dev/null || echo 0)"
    if [[ "$code" == "0" || "$code" == "null" || -z "$code" ]]; then
      code=0
    fi
  fi

  code="${code:-0}"
  response_time="${response_time:-0}"

  echo "${status}|${code}|${response_time}"
}
