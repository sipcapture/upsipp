# UPSIPP

[![Use this template](https://img.shields.io/badge/Use%20this%20template-2ea44f?style=for-the-badge&logo=github)](https://github.com/lmangani/upsipp/generate)

**UPSIPP** is a SIP endpoint monitor and status page powered entirely by GitHub Actions, Issues, and Pages — inspired by [Upptime](https://github.com/upptime/upptime), with probes executed by [gossipper](https://github.com/sipcapture/gossipper) instead of HTTP pings.

> **This repository is a GitHub template.** To monitor your SIP infrastructure, click **Use this template** above and create your own repository. 

## Quick start

1. **[Use this template](https://github.com/lmangani/upsipp/generate)** → create a new repository under your account or org.
2. Follow **[GETTING_STARTED.md](./GETTING_STARTED.md)** — enable Actions & Pages, run **Setup CI**, edit `upsipp.yml`.
3. Replace the example endpoint with your SIP target; **SIP Check CI** runs every 5 minutes.

## Live status (your repo)

After Setup CI runs in **your** generated repository, this README section is updated automatically:

| Endpoint | Status | History | Response time | Uptime |
| --- | --- | --- | --- | --- |
| _Run Setup CI in your repo to populate this table._ | | | | |

## How it works

| Layer | Upptime | UPSIPP |
| --- | --- | --- |
| Config | `.upptimerc.yml` | **`upsipp.yml`** → generates `.upptimerc.yml` |
| Probe | HTTP `curl` | **gossipper** SIP scenario (OPTIONS default) |
| History / graphs / site | `upptime/uptime-monitor` | **Same** (compatible `history/*.yml`) |
| Incidents | GitHub Issues | **Same** |
| Status page | GitHub Pages | **Same** |

### Workflows

| Workflow | Schedule | Purpose |
| --- | --- | --- |
| **Setup CI** | On `upsipp.yml` change / manual | Auto-configure owner/repo, labels, README, site |
| **SIP Check CI** | Every 5 min | gossipper probes, history, incidents |
| **Response Time CI** | Daily | Response time samples |
| **Summary CI** | Daily | README status table |
| **Graphs CI** | Daily | Response-time graphs |
| **Static Site CI** | Daily + config change | GitHub Pages deploy |

## Configuration

All user configuration lives in **`upsipp.yml`**. The template ships with placeholders:

```yaml
owner: YOUR_GITHUB_USERNAME   # auto-filled by Setup CI
repo: YOUR_REPO_NAME          # auto-filled by Setup CI

endpoints:
  - name: Example SIP Trunk
    remote: sip.example.com:5060   # replace with your SIP target
    scenario: options              # OPTIONS health check (default)
```

See **[GETTING_STARTED.md](./GETTING_STARTED.md)** for the full setup guide and **[TEMPLATE.md](./TEMPLATE.md)** if you maintain this template source.

## Local development

Clone **your generated repository**, not the template source:

```bash
./scripts/validate.sh
./scripts/install-gossipper.sh
./scripts/check.sh update
```

Maintainers of this template run `./scripts/validate-template.sh` before publishing changes.

## Attribution

- Inspired by **[Upptime](https://github.com/upptime/upptime)** (MIT)
- Status page via **[upptime/uptime-monitor](https://github.com/upptime/upptime)** and **[upptime/status-page](https://github.com/upptime/status-page)**
- SIP probing via **[gossipper](https://github.com/sipcapture/gossipper)** (AGPL-3.0, downloaded at runtime)

## License

MIT — see [LICENSE](./LICENSE).
