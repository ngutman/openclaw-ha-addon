# Clawdbot Home Assistant Add-on

Run the Clawdbot Gateway on Home Assistant OS and access it securely over an SSH tunnel. The add-on keeps all state under `/config/clawdbot` and bootstraps an initial config on first run.

## Overview
- Gateway runs locally on the HA host (binds to loopback by default).
- SSH server in the add-on provides secure remote access for Clawdbot.app or the CLI.
- On first start, the add-on runs `clawdbot setup` to create a minimal config and workspace.
- This README is shown in the Home Assistant add-on info panel.

## Install (Repository Add-on)
1) In Home Assistant UI:
   - Settings → Add-ons → Add-on Store → menu (⋮) → Repositories.
   - Add: `https://github.com/ngutman/clawdbot-ha-addon`
2) Reload the Add-on Store and install “Clawdbot Gateway”.

## Configure Add-on Options
In the add-on configuration UI, set:
- `ssh_authorized_keys`: your public key(s) to enable SSH access (required for tunnels).
- `ssh_port`: default `2222`.
- `repo_url`: optional fork URL.
- `repo_ref`: optional git ref (commit/tag/branch) to pin the gateway version.
- `github_token`: optional token for private forks.

## First Run
The add-on does the following on startup:
1) Clones or updates the Clawdbot repo into `/config/clawdbot/clawdbot-src`.
2) Installs dependencies and builds the gateway and control UI.
3) Runs `clawdbot setup` if no config exists.
4) Ensures `gateway.mode=local` if it was missing.
5) Starts the gateway.

## Configure Clawdbot
SSH into the add-on and run the configurator (recommended: onboarding wizard):
```bash
ssh -p 2222 root@<ha-host>
cd /config/clawdbot/clawdbot-src
pnpm clawdbot onboard
```
If you prefer the shorter flow:
```bash
pnpm clawdbot configure
```

The gateway auto-reloads config changes; a restart is usually not required.
If you change SSH keys or build settings, restart the add-on:
```bash
ha addons restart local_clawdbot
```

## Use as Remote Gateway (SSH Tunnel)
The gateway listens on loopback by default, so access it via SSH tunnel:
```bash
ssh -p 2222 -N -L 18789:127.0.0.1:18789 root@<ha-host>
```
Then point Clawdbot.app or the CLI at `ws://127.0.0.1:18789`.

## Bind Mode
Bind mode is configured via the Clawdbot CLI (over SSH), not in the add-on options.
Use `pnpm clawdbot configure` or `pnpm clawdbot onboard` to set it in `clawdbot.json`.

## Data Locations
- Config: `/config/clawdbot/.clawdbot/clawdbot.json`
- Auth: `/config/clawdbot/.clawdbot/agent/auth.json`
- Workspace: `/config/clawdbot/workspace`
- Repo checkout: `/config/clawdbot/clawdbot-src`

## Troubleshooting
- If SSH doesn’t work, ensure `ssh_authorized_keys` is set in the add-on options.
- If the gateway won’t start, check logs:
  `ha addons logs local_clawdbot -n 200`
- After any config change, restart the add-on.

## Notes
- For `bind=lan/tailnet/auto`, consider enabling gateway auth in `clawdbot.json`.
- The add-on runs builds on startup; expect the first boot to take several minutes.

## Links
- Clawdbot repo: https://github.com/clawdbot/clawdbot
- Add-on repo: https://github.com/ngutman/clawdbot-ha-addon
