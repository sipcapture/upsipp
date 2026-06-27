# Getting started with UPSIPP

Use this guide after creating **your own repository** from the UPSIPP template.
Do **not** fork the template repository for production monitoring — create a new repo with **Use this template** so you get an independent copy with your own history, issues, and Pages site.

## 1. Create your monitoring repository

1. Open the [UPSIPP template repository](https://github.com/lmangani/upsipp).
2. Click **Use this template** → **Create a new repository**.
3. Choose your organization or personal account, name the repo (e.g. `sip-status`), and create it.

> **Do not clone this template repo directly** for monitoring. Always generate a new repository from the template.

## 2. Enable GitHub features

In your **new** repository:

### Required (SIP monitoring)

1. **Settings → Actions → General** — allow Actions (enable if prompted).
2. **Settings → Actions → General → Workflow permissions** — select **Read and write permissions** so the built-in `GITHUB_TOKEN` can commit history, update the README, and deploy Pages. UPSIPP does not use a personal access token (`GH_PAT`).

SIP checks, git history, and incidents work with Actions alone — no Pages setup needed.

### Optional (public status page)

To publish the Upptime-style status website:

3. Run **Setup CI** or **Static Site CI** once — this builds the site and pushes the **`gh-pages`** branch.
4. **Settings → Pages** — set source to **Deploy from a branch**, branch **`gh-pages`**, folder **`/ (root)`**.

GitHub cannot enable Pages from a workflow; this one-time setting must be done in the repository (or org) settings. Until Pages is enabled, **Static Site CI** still runs and updates `gh-pages`, but nothing is served publicly.

## 3. Run Setup CI (first time)

> Skip step 4 in section 2 if you only want monitoring (README table + Issues) without a public status page.

1. Go to **Actions → Setup CI → Run workflow**.
2. Setup CI will:
   - Auto-fill `owner` and `repo` in `upsipp.yml` from your GitHub repository
   - Apply **`workflowSchedule`** to GitHub Actions (hourly checks by default)
   - Create issue labels (`upsipp`, `incident`)
   - Generate the README status table
   - Trigger graphs and status page builds

Alternatively, push any edit to `upsipp.yml` on `main` to trigger Setup CI.

## 4. Configure SIP endpoints

**`upsipp.yml`** ships with one active example (`enabled: true`) and additional **disabled examples** showing every supported feature — OPTIONS, builtin UAC, custom XML, auth secrets, TLS, health gates, and per-endpoint assignees. Set `enabled: true` on the ones you need.

### Check frequency

```yaml
workflowSchedule:
  uptime: "0 * * * *"       # every hour (default)
  # uptime: "*/5 * * * *"   # every 5 min (GitHub minimum)
```

Changing `workflowSchedule` and pushing to `main` triggers **Setup CI**, which updates the workflow cron lines.

### Minimal endpoint

```yaml
endpoints:
  - name: Lab SBC
    slug: lab-sbc
    enabled: true
    remote: 10.0.0.1:5060
    transport: u1
    scenario: options
    timeout_global: 15
```

Replace `sip.example.com:5060` in the active example, or enable another example block. Disabled examples stay in the file as documentation until you enable them.

Commit and push. Setup CI runs again; **SIP Check CI** follows the `workflowSchedule.uptime` cron (or run it manually).

## 5. Verify monitoring

| Check | Where |
| --- | --- |
| SIP probes | **Actions → SIP Check CI** |
| History commits | `history/<slug>.yml` in your repo |
| Incidents | **Issues** with `upsipp` / `incident` labels |
| Status page | **Settings → Pages** URL (after Static Site CI) |
| README table | Updated by **Summary CI** / Setup CI |

## 6. Optional: custom domain

In `upsipp.yml`:

```yaml
status-website:
  cname: status.example.com
  # remove baseUrl when using a dedicated subdomain
  name: My SIP Status
```

Push changes and re-run **Static Site CI**.

## Troubleshooting

| Problem | Fix |
| --- | --- |
| Workflows do not run | Enable Actions in repository settings |
| Commits not pushed | Confirm **Read and write permissions** for workflows; if branch protection is enabled, allow GitHub Actions to bypass or push to `main` |
| Issue creation fails | Re-run Setup CI to sync labels |
| SIP checks fail | Confirm endpoint is reachable from GitHub-hosted runners; consider self-hosted runners for ACL-restricted trunks |
| Pages 404 | Wait for Static Site CI; confirm Pages source is `gh-pages` |

## Local testing (optional)

Clone **your** generated repository (not the template source):

```bash
git clone https://github.com/YOUR_GITHUB_USERNAME/YOUR_REPO_NAME.git
cd YOUR_REPO_NAME
./scripts/validate.sh
./scripts/install-gossipper.sh
./scripts/check.sh update
```
