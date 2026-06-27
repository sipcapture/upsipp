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
yq -e '.owner and .repo and (.endpoints | length) > 0' upsipp.yml >/dev/null

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

echo ""
echo "All offline checks passed."
echo ""
echo "Template users: create a repo via GitHub 'Use this template', then follow GETTING_STARTED.md"
echo "Maintainers: run ./scripts/validate-template.sh before publishing template changes"
