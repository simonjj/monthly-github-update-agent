# Monthly Azure Container Apps GitHub update agent

This project deploys an unattended GitHub Copilot CLI agent that researches,
publishes, and pins the monthly Azure Container Apps update in
[`microsoft/azure-container-apps`](https://github.com/microsoft/azure-container-apps).
The agent runs inside an ACA Sandbox and uses only public, date-verified sources.

## Architecture

`azd up` deploys these resources to the existing `prodish-stuff` resource group
in Central US:

1. An ACA Sandbox Group named `github-aca-updater-group`.
2. A logically named sandbox, `github-aca-updater`. The preview Sandbox API
   assigns UUIDs, so the stable name is represented by the
   `name=github-aca-updater` label and selector.
3. An Azure Container Registry for the orchestrator image.
4. A Container Apps managed environment and scheduled job.
5. Managed-identity role assignments for ACR pull and
   `Container Apps SandboxGroup Data Owner`.

At each run, the scheduled job creates a clean `copilot` sandbox with the stable
name label, copies in the agent workspace, runs Copilot CLI non-interactively,
verifies `result.json`, and suspends the sandbox.

## End-of-month schedule

The job uses `0 0 1 * *` in UTC. Midnight on the first day of a month is the
exact boundary after the previous month ends, so the agent can cover the
previous complete calendar month without invalid dates for February or
30-day months. This is more reliable than scheduling the 30th or using
nonstandard cron extensions such as `L`.

## Prerequisites

- Azure CLI authenticated to the target subscription
- Azure Developer CLI (`azd`)
- ACA Sandbox CLI `aca` 1.0.0-preview.1 or later
- GitHub CLI authenticated as `simonjj`
- A GitHub token that:
  - authenticates Copilot CLI for an account with a Copilot entitlement
  - can create, label, pin, and unpin issues in
    `microsoft/azure-container-apps`

The token is stored in the local ignored `.azure` environment and as a secret
on the Container Apps job. Use a dedicated, narrowly scoped token and rotate it
by rerunning `azd up`.

Install the ACA CLI when needed:

```powershell
irm https://aka.ms/aca-cli-install-ps | iex
```

```bash
curl -fsSL https://aka.ms/aca-cli-install | sh
```

This same install path is also used inside sandboxes and containers for
agent-driven self-installs.

## Deploy

PowerShell:

```powershell
gh auth switch --user simonjj
$env:GITHUB_TOKEN = gh auth token

azd auth login
azd env new prod
azd up --no-prompt
```

Bash:

```bash
gh auth switch --user simonjj
export GITHUB_TOKEN="$(gh auth token)"

azd auth login
azd env new prod
azd up --no-prompt
```

The preprovision hook fixes the target to `prodish-stuff` and `centralus`,
registers providers, and resolves the deployer principal. The postprovision hook
builds the orchestrator in ACR, updates the scheduled job, creates the sandbox,
and leaves it suspended.

## Operations

Start an idempotent run manually:

```powershell
az containerapp job start `
  --name github-aca-update-scheduler `
  --resource-group prodish-stuff
```

List executions:

```powershell
az containerapp job execution list `
  --name github-aca-update-scheduler `
  --resource-group prodish-stuff `
  --output table
```

List or inspect the logical sandbox:

```powershell
aca sandbox list `
  --group github-aca-updater-group `
  --resource-group prodish-stuff `
  --region centralus `
  -l "name=github-aca-updater"
```

The agent checks for an exact issue title before creating anything. It unpins
only older pinned `ANNOUNCEMENT` issues whose titles end in `Updates`, leaves
unrelated pinned notices alone, creates the new issue, pins it, and reads it
back before reporting success.

Research is gated on a broad-search checklist. Each run performs at least 12
distinct searches across Microsoft sources, general web results, community
blogs and videos, public GitHub projects, and feature-specific follow-ups. The
agent records the queries, opened canonical pages, and exclusion reasons in
private research notes before it can draft the issue.
