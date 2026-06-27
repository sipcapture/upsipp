#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CMD="${1:-help}"

case "$CMD" in
  update|check)
    exec "${ROOT}/scripts/check.sh" update
    ;;
  response-time)
    exec "${ROOT}/scripts/check.sh" response-time
    ;;
  generate-upptimerc)
    exec "${ROOT}/scripts/generate-upptimerc.sh"
    ;;
  generate-workflows)
    exec "${ROOT}/scripts/generate-workflows.sh"
    ;;
  install-gossipper)
    exec "${ROOT}/scripts/install-gossipper.sh"
    ;;
  help|--help|-h)
    cat <<EOF
UPSIPP — SIP monitoring via GitHub Actions

Usage: upsipp.sh <command>

Commands:
  update            Run gossipper checks, update history, manage incidents
  response-time     Record response times without incident updates
  generate-upptimerc  Build .upptimerc.yml from upsipp.yml
  generate-workflows  Apply workflowSchedule to .github/workflows
  install-gossipper Download gossipper release binary
EOF
    ;;
  *)
    echo "Unknown command: ${CMD}" >&2
    exit 1
    ;;
esac
