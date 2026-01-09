# Changelog

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
