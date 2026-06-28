# UPSIPP

[![Use this template](https://img.shields.io/badge/Use%20this%20template-2ea44f?style=for-the-badge&logo=github)](https://github.com/sipcapture/upsipp/generate)

**UPSIPP** is a SIP endpoint monitor and status page powered entirely by GitHub Actions, Issues, and Pages — inspired by [Upptime](https://github.com/upptime/upptime), with probes executed by [gossipper](https://github.com/sipcapture/gossipper) instead of HTTP pings.

> **This repository is a GitHub template.** To monitor your SIP infrastructure, click **Use this template** above and create your own repository.

## Quick start

1. **[Use this template](https://github.com/sipcapture/upsipp/generate)** → create a new repository under your account or org.
2. Follow **[GETTING_STARTED.md](./GETTING_STARTED.md)** — enable Actions (required), optionally enable **GitHub Pages** for the status site, run **Setup CI**, edit `upsipp.yml`.
3. Replace the example endpoint with your SIP target; **SIP Check CI** runs hourly by default (configurable in `upsipp.yml`).

## Live status (your repo)

After Setup CI runs in **your** generated repository, this README section is updated automatically:

| Endpoint                                            | Status | History | Response time | Uptime |
| --------------------------------------------------- | ------ | ------- | ------------- | ------ |
| _Run Setup CI in your repo to populate this table._ |        |         |               |        |

## How it works

| Layer                   | Upptime                  | UPSIPP                                        |
| ----------------------- | ------------------------ | --------------------------------------------- |
| Config                  | `.upptimerc.yml`         | **`upsipp.yml`** → generates `.upptimerc.yml` |
| Probe                   | HTTP `curl`              | **gossipper** SIP scenario (OPTIONS default)  |
| History / graphs / site | `upptime/uptime-monitor` | **Same** (compatible `history/*.yml`)         |
| Incidents               | GitHub Issues            | **Same**                                      |
| Status page             | GitHub Pages             | **Same**                                      |

### Workflows

| Workflow             | Schedule                        | Purpose                                                             |
| -------------------- | ------------------------------- | ------------------------------------------------------------------- |
| **Setup CI**         | On `upsipp.yml` change / manual | Auto-configure owner/repo, workflow schedules, labels, README, site |
| **SIP Check CI**     | Hourly (default)                | gossipper probes, history, incidents                                |
| **Response Time CI** | Daily                           | Response time samples                                               |
| **Summary CI**       | Daily                           | README status table                                                 |
| **Graphs CI**        | Daily                           | Response-time graphs                                                |
| **Static Site CI**   | Daily + config change           | GitHub Pages deploy                                                 |

## Configuration

All user configuration lives in **`upsipp.yml`**. The template includes **commented examples** for every supported feature — enable them with `enabled: true` and set your SIP targets.

### Check frequency

```yaml
workflowSchedule:
  uptime: "0 * * * *" # SIP Check CI — every hour (default)
  # uptime: "*/5 * * * *"   # every 5 minutes (GitHub Actions minimum)
```

Setup CI applies `workflowSchedule` to the workflow files. GitHub cron minimum is 5 minutes.

### Endpoint features (see `upsipp.yml` for full examples)

| Feature                  | Config keys                                                    |
| ------------------------ | -------------------------------------------------------------- |
| OPTIONS health check     | `scenario: options` (default, enabled)                         |
| Built-in INVITE          | `scenario: uac`                                                |
| Custom XML scenario      | `scenario: scenarios/example_uac.xml`                          |
| Digest auth              | `auth.user_secret` / `auth.pass_secret` → GitHub Secrets       |
| TLS signaling            | `transport: l1`, `tls_skip_verify: true`                       |
| Health gates             | `health.min_success_ratio`, `max_failed_calls`, `max_timeouts` |
| Per-endpoint assignees   | `assignees: [username]`                                        |
| Disable without deleting | `enabled: false`                                               |

```yaml
owner: YOUR_GITHUB_USERNAME # auto-filled by Setup CI
repo: YOUR_REPO_NAME

endpoints:
  - name: Example Trunk — OPTIONS
    enabled: true
    remote: sip.example.com:5060
    scenario: options
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
