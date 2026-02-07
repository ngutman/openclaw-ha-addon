# OpenClaw Gateway

Run [OpenClaw](https://github.com/openclaw/openclaw) on Home Assistant OS with secure SSH tunnel access.

## Features

- 🦞 **OpenClaw Gateway** — AI agent with messaging, automation, and more
- 🔒 **SSH Tunnel** — Secure remote access for the OpenClaw app or CLI
- 📦 **Persistent Storage** — All data survives add-on updates
- 🛠️ **Included Tools** — 28 CLI tools including:
  - **Core**: hass-cli (Home Assistant), clawdhub
  - **Productivity**: gog (Google Workspace), gh (GitHub), op (1Password), himalaya (Email), obsidian-cli
  - **AI & Media**: gemini, oracle, nano-pdf, whisper (speech-to-text), summarize, sag (text-to-speech), songsee, video-frames
  - **Smart Home**: openhue (Philips Hue), sonos, eightctl (Eight Sleep)
  - **Communication**: bird (X/Twitter), wacli (WhatsApp)
  - **Development**: mcporter (MCP servers), tmux
  - **Utilities**: blogwatcher (RSS/Atom), goplaces (Google Places), camsnap (RTSP/ONVIF), blu (BluOS), gifgrep, ordercli (Foodora)

## Quick Start

1. Add this repository to Home Assistant
2. Install "OpenClaw Gateway" from the Add-on Store
3. Configure your SSH public key in the add-on options
4. Start the add-on and connect via SSH tunnel

After connecting, run `openclaw configure` to finish setup (including gateway mode and auth token).

## Links

- [Documentation](https://docs.clawd.bot)
- [GitHub](https://github.com/openclaw/openclaw)
- [Discord](https://discord.com/invite/clawd)
