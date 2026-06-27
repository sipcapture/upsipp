# Template repository maintenance

This document is for **maintainers of the UPSIPP template source** (`sipcapture/upsipp`), not for users who created their own repo from the template.

## Enable GitHub template mode

1. **Settings → General**
2. Check **Template repository**
3. Save

Until this is enabled, the **Use this template** button will not appear.

## Recommended repository metadata

| Field | Suggested value |
| --- | --- |
| Description | SIP uptime monitor and status page powered by GitHub Actions and gossipper |
| Topics | `sip`, `voip`, `uptime-monitor`, `status-page`, `github-actions`, `gossipper`, `template` |
| Website | Your demo status page URL (after first deploy) |

## What must stay in the template

- `upsipp.yml` with **`YOUR_GITHUB_USERNAME`** and **`YOUR_REPO_NAME`** placeholders
- Empty `history/` (only `.gitkeep`) — no committed check results
- No `.upptimerc.yml`, `bin/`, or gossipper artifacts in git
- All workflows under `.github/workflows/`

## Validate before publishing template changes

```bash
./scripts/validate-template.sh
```

**Template Validate CI** runs the same checks on every push to `main`.

## Testing changes (use template flow)

Do **not** test monitoring only in the template source repo. Instead:

1. **Use this template** → create a throwaway repo (e.g. `upsipp-test-001`)
2. Run **Setup CI** in the new repo
3. Point one endpoint at a lab SIP server
4. Run **SIP Check CI** manually
5. Confirm history, issues, README, and Pages

Delete the test repo when finished.

## Placeholder contract

| File | Placeholder | Replaced by |
| --- | --- | --- |
| `upsipp.yml` | `owner: YOUR_GITHUB_USERNAME` | Setup CI / `configure-from-github.sh` |
| `upsipp.yml` | `repo: YOUR_REPO_NAME` | Setup CI / `configure-from-github.sh` |
| `upsipp.yml` | `baseUrl: /YOUR_REPO_NAME` | Setup CI / `configure-from-github.sh` |
| README / status page | `$OWNER`, `$REPO` | Upptime monitor at build time |

## Version tracking

`.templaterc.json` records the template version. Bump when making breaking workflow or config changes.
