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

1. **Settings → Actions → General** — allow Actions (enable if prompted).
2. **Settings → Actions → General → Workflow permissions** — select **Read and write permissions** so the built-in `GITHUB_TOKEN` can commit history, update the README, and deploy Pages. UPSIPP does not use a personal access token (`GH_PAT`).
3. **Settings → Pages** — set source to **Deploy from a branch**, branch **`gh-pages`**, folder **`/ (root)`**.
   The first Static Site CI run creates the `gh-pages` branch.

## 3. Run Setup CI (first time)

1. Go to **Actions → Setup CI → Run workflow**.
2. Setup CI will:
   - Auto-fill `owner` and `repo` in `upsipp.yml` from your GitHub repository
   - Create issue labels (`upsipp`, `incident`)
   - Generate the README status table
   - Trigger graphs and status page builds

Alternatively, push any edit to `upsipp.yml` on `main` to trigger Setup CI.

## 4. Configure SIP endpoints

Edit **`upsipp.yml`** in your repository (not in the template source):

```yaml
endpoints:
  - name: Lab SBC
    slug: lab-sbc
    remote: 10.0.0.1:5060
    transport: u1
    scenario: options
    timeout_global: 15
```

Replace `sip.example.com:5060` with a reachable SIP target. Remove the example endpoint when you add real ones.

Commit and push. Setup CI runs again; **SIP Check CI** starts on the 5-minute schedule (or run it manually).

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
