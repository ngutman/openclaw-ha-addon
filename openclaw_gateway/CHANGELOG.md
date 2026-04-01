# Changelog

## 0.4.14

- **Fix**: Make first-run onboarding available through Home Assistant ingress.
  - Start the ingress proxy before the onboarding server so the add-on panel works on first boot.
  - Render nginx against the configured gateway port instead of hard-coding `18789`.
- **Fix**: Restrict the ingress listener to Home Assistant's internal proxy path.
  - Stop publishing the ingress port as a host port.
  - Deny direct non-ingress access at nginx level.
- **Fix**: Ensure `gateway.auth.token` exists before the gateway starts.
- **Docs**: Update quick-start and docs to point users at ingress onboarding first.

## 0.4.13

- **Feature**: Add Home Assistant API integration.
  - Enable `hassio_api`, `homeassistant_api`, and `auth_api` for Supervisor access.
  - Export `HA_URL` (http://supervisor/core/api) and `HA_TOKEN` env vars.
  - Uses SUPERVISOR_TOKEN automatically, or user-provided `ha_token` option.
  - OpenClaw can now interact with Home Assistant entities and services.

## 0.4.12

- **Fix**: Auto-configure `gateway.trustedProxies` for nginx reverse proxy.
  - The gateway was rejecting connections because it didn't trust nginx's proxy headers.
  - Now trusts `127.0.0.1` and `172.30.32.0/24` (HA Supervisor network).

## 0.4.11

- **Fix**: Auto-enable `gateway.controlUi.allowInsecureAuth: true` for HA Ingress.
  - Ingress uses HTTP internally, which triggers OpenClaw's secure context check.
  - This setting allows token-only auth over HTTP.

## 0.4.10

- **Fix**: Disable `host_network` for proper Ingress support.
  - Ingress requires standard Docker networking to reach add-on via internal IP.
  - SSH port (2222) is now exposed via port mapping instead.
  - Added `proxy_buffering off` to nginx for better WebSocket support.

## 0.4.9

- **Fix**: Add nginx reverse proxy to enable HA Ingress with `host_network: true`.
  - nginx binds to `0.0.0.0:8099` and forwards to gateway on `127.0.0.1:18789`.
  - `ingress_port` changed to 8099 to match nginx.
  - Removed invalid `--host` flag and `HOST` env var (didn't work).

## 0.4.8

- **Fix**: Use `HOST=0.0.0.0` environment variable instead of `--host` flag (which doesn't exist).

## 0.4.7

- **Fix**: Gateway now binds to `0.0.0.0` instead of `127.0.0.1` so HA Ingress can reach it.

## 0.4.6

- **Fix**: Replace `node-pty` with built-in `child_process` to avoid native module loading issues.
- **Fix**: Use compatible `import.meta.url` approach for ESM path resolution.
- **Added**: Extensive logging in onboarding server for easier debugging.

## 0.4.5

- **Reverted**: Removed Antigravity User-Agent fix (did not work as expected).
- **Fix**: Onboarding UI now starts correctly.
  - Read `port` from options before launching the onboarding server.
  - Copy onboarding files into `REPO_DIR` so native modules (`node-pty`) can be loaded.

## 0.4.0

- Major: Add Home Assistant Sidebar integration (`panel: true`).
- Feature: New interactive Onboarding UI with embedded terminal (`xterm.js`).
- Feature: Auto-reload logic to transition from setup to the OpenClaw Dashboard.
- Fix: Gateway now uses `ingress` for secure internal proxy access.

## 0.3.21

- Fix: CLI invocation now uses `node scripts/run-node.mjs` instead of `pnpm exec openclaw` to match how the openclaw monorepo runs its CLI.

## 0.3.0

- BREAKING: Migrated from Clawdbot to OpenClaw (https://github.com/openclaw/openclaw)
- Renamed addon slug from `clawdbot_gateway` to `openclaw_gateway`
- Updated all paths from `/config/clawdbot` to `/config/openclaw`
- Updated CLI commands from `clawdbot` to `openclaw`
- Updated config files from `clawdbot.json` to `openclaw.json`
- Fixed CLI invocation to use `pnpm exec openclaw` instead of `pnpm clawdbot`

## 0.2.15

- Fix: install dev dependencies so gateway builds include tsc. (#9)

## 0.2.14

- Add pretty log formatting options for the add-on Log tab.

## 0.2.13

- Add icon.png and logo.png (cyber-lobster mascot).
- Add DOCS.md with detailed documentation.
- Simplify README.md as add-on store intro.
- Follow Home Assistant add-on presentation best practices.

## 0.2.12

- Docker: install Bun runtime.

## 0.2.11

- Docker: install GitHub CLI.
- Storage: persist root home directories under /config/clawdbot.
- Docker: refresh base image/toolchain and update gogcli. Thanks @niemyjski! (PR #2)

## 0.2.10

- Fix: remove unsupported pnpm install flag in add-on image.

## 0.2.9

- Install: auto-confirm module purge only when needed.

## 0.2.8

- Install: always reinstall dependencies without confirmation.

## 0.2.7

- Docker: install clawdhub and Home Assistant CLI.

## 0.2.6

- Auto-restart gateway on unclean exits (e.g., shutdown timeout).

## 0.2.5

- BREAKING: Renamed `repo_ref` to `branch`. Set to track a specific branch; omit to use repo's default.
- Config: `github_token` now uses password field (masked in UI).

## 0.2.4

- Docs: repo-based install steps and add-on info links.
- Docker: set WORKDIR to /opt/clawdbot.
- Logs: stream gateway log file into add-on stdout.
- Docker: add ripgrep for faster log searches.

## 0.2.3

- Docs: repo-based install steps and add-on info links.
- Docker: set WORKDIR to /opt/clawdbot.
- Logs: stream gateway log file into add-on stdout.

## 0.2.2

- Add HA add-on repository layout and improved SIGUSR1 handling.
- Support pinning upstream refs and clean checkouts.

## 0.2.1

- Ensure gateway.mode=local on first boot.

## 0.2.0

- Initial Home Assistant add-on.
