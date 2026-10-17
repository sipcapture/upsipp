#!/usr/bin/env bash
# Offline validation — no live SIP probe required.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> Checking required files..."
for f in upsipp.yml scenarios/options_client.xml scripts/check.sh scripts/generate-upptimerc.sh; do
  [[ -f "$f" ]] || { echo "Missing $f" >&2; exit 1; }
done

echo "==> Making scripts executable..."
chmod +x scripts/*.sh scripts/lib/*.sh 2>/dev/null || true

echo "==> Bootstrapping yq..."
source scripts/bootstrap.sh

echo "==> Validating upsipp.yml..."
yq -e '.owner and .repo and ([.endpoints[] | select(.enabled != false)] | length) > 0' upsipp.yml >/dev/null

echo "==> Generating .upptimerc.yml..."
./scripts/generate-upptimerc.sh
[[ -f .upptimerc.yml ]] || exit 1
yq -e '.sites | length > 0' .upptimerc.yml >/dev/null

echo "==> ShellCheck-style syntax (bash -n)..."
while IFS= read -r sh; do
  bash -n "$sh"
done < <(find scripts -name '*.sh' -type f)

echo "==> Testing history writer..."
source scripts/lib/history-write.sh
tmp="$(mktemp)"
write_history "$tmp" "sip:127.0.0.1:5060" "up" 200 42 "2026-06-27T12:00:00.000Z"
grep -q 'responseTime: 42' "$tmp"
rm -f "$tmp"

echo "==> Testing summary parser..."
source scripts/lib/gossipper-run.sh
sample="$(mktemp)"
cat > "$sample" <<'JSON'
{"success_ratio":1,"failed_calls":0,"health":{"passed":true},"duration_ms":55}
JSON
result="$(parse_summary "$sample" 0)"
[[ "$result" == "up|200|55" ]] || { echo "Unexpected parse result: $result" >&2; exit 1; }
rm -f "$sample"

echo "==> Testing secret handling..."
source scripts/lib/secrets.sh

export UPSIPP_TEST_SECRET="s3cr3t-value"
if [[ "$(resolve_secret UPSIPP_TEST_SECRET)" != "s3cr3t-value" ]]; then
  echo "ERROR: resolve_secret did not read the value from the environment" >&2
  exit 1
fi
unset UPSIPP_TEST_SECRET

if [[ -n "$(resolve_secret UPSIPP_MISSING_SECRET)" ]]; then
  echo "ERROR: resolve_secret should be empty for an unset variable" >&2
  exit 1
fi
if [[ -n "$(resolve_secret '')" || -n "$(resolve_secret null)" ]]; then
  echo "ERROR: resolve_secret should be empty for blank/null names" >&2
  exit 1
fi

# Comment-only lines are ignored so explanatory text cannot trip the checks.
comment_line=':[0-9]+:[[:space:]]*#'

# The whole secrets context must never be forwarded to the runner.
tojson_matches="$(grep -REn 'to[Jj]son[[:space:]]*\([[:space:]]*secrets' .github/workflows || true)"
if [[ -n "$tojson_matches" ]] && echo "$tojson_matches" | grep -Evq "$comment_line"; then
  echo "ERROR: a workflow exposes all secrets via toJson(secrets)" >&2
  exit 1
fi

# Dynamic (unquoted) secret lookups also require the full secrets context.
dynamic_secrets="$(grep -REn 'secrets\[' .github/workflows || true)"
if [[ -n "$dynamic_secrets" ]] && echo "$dynamic_secrets" | grep -Evq "${comment_line}|secrets\[[\"']"; then
  echo "ERROR: a workflow uses dynamic secret access (secrets[...])" >&2
  exit 1
fi

# Every workflow that runs the probes must expose the documented credentials.
for wf in .github/workflows/sip-check.yml .github/workflows/response-time.yml; do
  grep -q 'secrets\.SIP_USER' "$wf" || { echo "ERROR: ${wf} must expose secrets.SIP_USER explicitly" >&2; exit 1; }
  grep -q 'secrets\.SIP_PASS' "$wf" || { echo "ERROR: ${wf} must expose secrets.SIP_PASS explicitly" >&2; exit 1; }
done

echo "    secret handling OK"

echo ""
echo "All offline checks passed."
echo ""
echo "Template users: create a repo via GitHub 'Use this template', then follow GETTING_STARTED.md"
echo "Maintainers: run ./scripts/validate-template.sh before publishing template changes"
