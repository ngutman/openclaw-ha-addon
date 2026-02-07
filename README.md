# OpenClaw Home Assistant Add-ons

This repository contains Home Assistant add-ons for OpenClaw.

## Add-ons

### clawdbot_gateway
OpenClaw Gateway for HA OS with SSH tunnel support for remote connections.

**Included tools:**
- **hass-cli** — Home Assistant CLI for controlling and managing Home Assistant
- **clawhub** — Search, install, update, and publish agent skills from clawhub.com
- **op** — 1Password CLI for password management
- **bird** — X/Twitter CLI for reading, searching, and posting
- **blogwatcher** — Monitor blogs and RSS/Atom feeds for updates
- **blu** — BluOS CLI for discovery, playback, grouping, and volume control
- **camsnap** — Capture frames or clips from RTSP/ONVIF cameras
- **eightctl** — Control Eight Sleep pods (status, temperature, alarms, schedules)
- **gemini** — Gemini CLI for one-shot Q&A, summaries, and generation
- **gifgrep** — Search GIF providers with CLI/TUI, download results, extract stills/sheets
- **gh** — GitHub CLI for issues, PRs, CI runs, and advanced queries
- **gog** — Google Workspace CLI (Gmail, Calendar, Drive, Contacts, Sheets, Docs)
- **goplaces** — Query Google Places API for text search, place details, and reviews
- **himalaya** — Email management via IMAP/SMTP
- **mcporter** — MCP servers/tools CLI for listing, configuring, and calling MCP servers
- **nano-pdf** — Edit PDFs with natural-language instructions
- **obsidian-cli** — Work with Obsidian vaults (plain Markdown notes)
- **whisper** — Local speech-to-text with OpenAI Whisper (no API key required)
- **openhue** — Control Philips Hue lights and scenes
- **oracle** — Prompt + file bundling CLI for AI interactions
- **ordercli** — Foodora CLI for checking past orders and active order status
- **sag** — ElevenLabs text-to-speech with mac-style say UX
- **songsee** — Generate spectrograms and feature-panel visualizations from audio
- **sonos** — Control Sonos speakers (discover/status/play/volume/group)
- **summarize** — Summarize or extract text/transcripts from URLs, podcasts, and local files
- **tmux** — Remote-control tmux sessions for interactive CLIs
- **video-frames** — Extract frames or short clips from videos using ffmpeg
- **wacli** — Send WhatsApp messages or search/sync WhatsApp history

## Installation

1. Go to **Settings → Add-ons → Add-on Store → ⋮ → Repositories**
2. Add this repository:
   ```
   https://github.com/ngutman/clawdbot-ha-addon
   ```
3. Find "OpenClaw Gateway" in the add-on store and install

## Configuration

| Option | Description |
|--------|-------------|
| `port` | Gateway WebSocket port (default: 18789) |
| `verbose` | Enable verbose logging |
| `repo_url` | OpenClaw source repository |
| `branch` | Branch to checkout (optional, uses repo's default if omitted) |
| `github_token` | GitHub token for private repos |
| `ssh_port` | SSH server port for tunnel access (default: 2222) |
| `ssh_authorized_keys` | Public keys for SSH access |

## Links
- [OpenClaw](https://github.com/openclaw/openclaw)
- [gog CLI](https://gogcli.sh)
- [GitHub CLI](https://cli.github.com)
