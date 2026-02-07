FROM node:24-bookworm

COPY --from=golang:1.25-bookworm /usr/local/go /usr/local/go

ARG TARGETARCH

# Default to latest, but allow override via --build-arg
ARG BLOGWATCHER_VERSION=latest
ARG BLUCLI_VERSION=latest
ARG CAMSNAP_VERSION=latest
ARG EIGHTCTL_VERSION=latest
ARG GIFGREP_VERSION=latest
ARG GH_VERSION=latest
ARG GOGCLI_VERSION=latest
ARG GOPLACES_VERSION=latest
ARG OBSIDIAN_CLI_VERSION=latest
ARG ORDERCLI_VERSION=latest
ARG SAG_VERSION=latest
ARG SONGSEE_VERSION=latest
ARG SONOSCLI_VERSION=latest
ARG WACLI_VERSION=latest

ENV GOPATH="/go"
ENV PNPM_HOME="/pnpm"
ENV UV_TOOL_DIR="/usr/local/share/uv/tools"
ENV UV_BIN_DIR="/usr/local/bin"
ENV PATH="${GOPATH}/bin:/usr/local/go/bin:${PNPM_HOME}:${UV_BIN_DIR}:${PATH}"

# Use bash with pipefail so curl|tar failures stop the build.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Upgrade packages and install dependencies, then clean apt caches.
RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends \
    ffmpeg \
    jq \
    libasound2-dev \
    nano \
    openssh-server \
    python3-pip \
    ripgrep \
    tmux \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ENV BUN_INSTALL=/usr/local/bun
ENV PNPM_HOME=/pnpm
ENV PATH="${BUN_INSTALL}/bin:${PNPM_HOME}:${PATH}"

RUN npm install -g bun pnpm \
  && mkdir -p /pnpm \
  && pnpm config set global-bin-dir /pnpm

RUN pip3 install --no-cache-dir --break-system-packages homeassistant-cli uv

# --- Install Skill Requirements -----------------------------------------------

# [🐚] 🔐 1password - Set up and use 1Password CLI (op). Use when installing the CLI, enabling desktop app integration, signing in (single or multi-account), or …
RUN export OP_VER=$(curl -s https://app-updates.agilebits.com/check/1/0/CLI2/en/2.0.0/N | grep -oP '"version":"\K[^"]+') \
    && case "${TARGETARCH}" in \
         "amd64") OP_ARCH="amd64" ;; \
         "arm64") OP_ARCH="arm64" ;; \
         *) echo "Unsupported architecture for 1Password CLI: ${TARGETARCH}"; exit 1 ;; \
       esac \
    && curl -sSo op.zip "https://cache.agilebits.com/dist/1P/op2/pkg/v${OP_VER}/op_linux_${OP_ARCH}_v${OP_VER}.zip" \
    && unzip -od /usr/local/bin/ op.zip op \
    && rm op.zip

# [🟥] 🐦 bird - X/Twitter CLI for reading, searching, and posting via cookies or Sweetistics.
RUN pnpm add -g @steipete/bird

# [🐹] 📰 blogwatcher - Monitor blogs and RSS/Atom feeds for updates using the blogwatcher CLI.
RUN go install github.com/Hyaxia/blogwatcher/cmd/blogwatcher@${BLOGWATCHER_VERSION} && go clean -cache -modcache

# [🐹] 🫐 blucli - BluOS CLI (blu) for discovery, playback, grouping, and volume.
RUN go install github.com/steipete/blucli/cmd/blu@${BLUCLI_VERSION} && go clean -cache -modcache

# [🐹] 📸 camsnap - Capture frames or clips from RTSP/ONVIF cameras.
RUN go install github.com/steipete/camsnap/cmd/camsnap@${CAMSNAP_VERSION} && go clean -cache -modcache

# [🟥] clawhub - Use the ClawHub CLI to search, install, update, and publish agent skills from clawhub.com. Use when you need to fetch new skills on the fly…
RUN pnpm add -g clawhub

# [🐹] 🎛️ eightctl - Control Eight Sleep pods (status, temperature, alarms, schedules).
RUN go install github.com/steipete/eightctl/cmd/eightctl@${EIGHTCTL_VERSION} && go clean -cache -modcache

# [🟥] ♊️ gemini - Gemini CLI for one-shot Q&A, summaries, and generation.
RUN npm install -g @google/gemini-cli

# [🐹] 🧲 gifgrep - Search GIF providers with CLI/TUI, download results, and extract stills/sheets.
RUN go install github.com/steipete/gifgrep/cmd/gifgrep@${GIFGREP_VERSION} && go clean -cache -modcache

# [🐹] github - Interact with GitHub using the `gh` CLI. Use `gh issue`, `gh pr`, `gh run`, and `gh api` for issues, PRs, CI runs, and advanced queries.
RUN go install github.com/cli/cli/v2/cmd/gh@${GH_VERSION} && go clean -cache -modcache

# [🐹] 🎮 gog - Google Workspace CLI for Gmail, Calendar, Drive, Contacts, Sheets, and Docs.
RUN go install github.com/steipete/gogcli/cmd/gog@${GOGCLI_VERSION} && go clean -cache -modcache

# [🐹] 📍 goplaces - Query Google Places API (New) via the goplaces CLI for text search, place details, resolve, and reviews. Use for human-friendly place looku…
RUN go install github.com/steipete/goplaces/cmd/goplaces@${GOPLACES_VERSION} && go clean -cache -modcache

# [🐚] 📧 himalaya - CLI to manage emails via IMAP/SMTP. Use `himalaya` to list, read, write, reply, forward, search, and organize emails from the terminal. Sup…
RUN case "${TARGETARCH}" in \
         "amd64") HIMALAYA_ARCH="x86_64" ;; \
         "arm64") HIMALAYA_ARCH="aarch64" ;; \
         *) echo "Unsupported architecture for himalaya: ${TARGETARCH}"; exit 1 ;; \
       esac \
    && curl -fsSL "https://github.com/pimalaya/himalaya/releases/latest/download/himalaya.${HIMALAYA_ARCH}-linux.tgz" | tar xz -C /usr/local/bin himalaya

# [🟥] 📦 mcporter - Use the mcporter CLI to list, configure, auth, and call MCP servers/tools directly (HTTP or stdio), including ad-hoc servers, config edits,…
RUN pnpm add -g mcporter

# [🐍] 📄 nano-pdf - Edit PDFs with natural-language instructions using the nano-pdf CLI.
RUN uv tool install nano-pdf

# [🐹] 💎 obsidian - Work with Obsidian vaults (plain Markdown notes) and automate via obsidian-cli.
RUN go install github.com/Yakitrak/obsidian-cli@${OBSIDIAN_CLI_VERSION} && go clean -cache -modcache

# [🐍] 🎙️ openai-whisper - Local speech-to-text with the Whisper CLI (no API key).
RUN uv tool install whisper-cli

# [🐚] 💡 openhue - Control Philips Hue lights/scenes via the OpenHue CLI.
RUN case "${TARGETARCH}" in \
         "amd64") OPENHUE_ARCH="x86_64" ;; \
         "arm64") OPENHUE_ARCH="arm64" ;; \
         *) echo "Unsupported architecture for openhue: ${TARGETARCH}"; exit 1 ;; \
       esac \
    && curl -fsSL "https://github.com/openhue/openhue-cli/releases/latest/download/openhue_Linux_${OPENHUE_ARCH}.tar.gz" | tar xz -C /usr/local/bin openhue

# [🟥] 🧿 oracle - Best practices for using the oracle CLI (prompt + file bundling, engines, sessions, and file attachment patterns).
RUN npm install -g @steipete/oracle

# [🐹] 🛵 ordercli - Foodora-only CLI for checking past orders and active order status (Deliveroo WIP).
RUN go install github.com/steipete/ordercli/cmd/ordercli@${ORDERCLI_VERSION} && go clean -cache -modcache

# [🍥+🐹] 🗣️ sag - ElevenLabs text-to-speech with mac-style say UX.
# apt install libasound2-dev
RUN go install github.com/steipete/sag/cmd/sag@${SAG_VERSION} && go clean -cache -modcache

# [🐹] 🌊 songsee - Generate spectrograms and feature-panel visualizations from audio with the songsee CLI.
RUN go install github.com/steipete/songsee/cmd/songsee@${SONGSEE_VERSION} && go clean -cache -modcache

# [🐹] 🔊 sonoscli - Control Sonos speakers (discover/status/play/volume/group).
RUN go install github.com/steipete/sonoscli/cmd/sonos@${SONOSCLI_VERSION} && go clean -cache -modcache

# [🟥] 🧾 summarize - Summarize or extract text/transcripts from URLs, podcasts, and local files (great fallback for “transcribe this YouTube/video”).
RUN npm install -g @steipete/summarize

# [🍥] 🧵 tmux - Remote-control tmux sessions for interactive CLIs by sending keystrokes and scraping pane output.
# apt install tmux

# [🍥] 🎞️ video-frames - Extract frames or short clips from videos using ffmpeg.
# apt install ffmpeg

# 📱 wacli - Send WhatsApp messages to other people or search/sync WhatsApp history via the wacli CLI (not for normal user chats).
RUN go install github.com/steipete/wacli/cmd/wacli@${WACLI_VERSION} && go clean -cache -modcache

# ------------------------------------------------------------------------------

WORKDIR /opt/openclaw

COPY run.sh /run.sh
COPY migrate.sh /migrate.sh
RUN chmod +x /run.sh /migrate.sh

CMD [ "/run.sh" ]
