FROM node:24-bookworm

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

ENV PNPM_HOME=/pnpm
ENV PATH="$PNPM_HOME:$PATH"

RUN npm install -g bun pnpm \
  && mkdir -p /pnpm \
  && pnpm config set global-bin-dir /pnpm \
  && pnpm add -g clawdhub

RUN pip3 install --no-cache-dir --break-system-packages homeassistant-cli uv

# --- GO -----------------------------------------------------------------------
#RUN curl -fsSL https://go.dev/dl/go1.25.6.linux-amd64.tar.gz | tar xz -C /usr/local

COPY --from=golang:1.25-bookworm /usr/local/go /usr/local/go

ENV GOPATH="/go"
ENV PATH="${GOPATH}/bin:/usr/local/go/bin:${PATH}"
# ------------------------------------------------------------------------------

# --- HOMEBREW -----------------------------------------------------------------
#ENV HOMEBREW_NO_ANALYTICS=1 \
#    HOMEBREW_NO_AUTO_UPDATE=1
#
#RUN mkdir -p /home/linuxbrew/.linuxbrew/bin \
#    && git clone https://github.com/Homebrew/brew /home/linuxbrew/.linuxbrew/Homebrew \
#    && ln -s /home/linuxbrew/.linuxbrew/Homebrew/bin/brew /home/linuxbrew/.linuxbrew/bin/brew \
#    && chown -R node: /home/linuxbrew
#
#ENV PATH="/home/linuxbrew/.linuxbrew/bin:${PATH}"
# ------------------------------------------------------------------------------

# --- UV -----------------------------------------------------------------------
#ENV UV_TOOL_DIR=/config/clawdbot/.local/share/uv/tools \
#    UV_BIN_DIR=/config/clawdbot/.local/bin
# ------------------------------------------------------------------------------



# --- Install Skill Requirements -----------------------------------------------

# [🍺/🐚] 🔐 1password - Set up and use 1Password CLI (op). Use when installing the CLI, enabling desktop app integration, signing in (single or multi-account), or …
#USER node
#RUN brew install --cask 1password-cli
#USER root
RUN export OP_VER=$(curl -s https://app-updates.agilebits.com/check/1/0/CLI2/en/2.0.0/N | grep -oP '"version":"\K[^"]+') \
    && curl -sSo op.zip https://cache.agilebits.com/dist/1P/op2/pkg/v${OP_VER}/op_linux_amd64_v${OP_VER}.zip \
    && unzip -od /usr/local/bin/ op.zip op \
    && rm op.zip

# [🟥] 🐦 bird - X/Twitter CLI for reading, searching, and posting via cookies or Sweetistics.
RUN pnpm add -g @steipete/bird

# [🐹] 📰 blogwatcher - Monitor blogs and RSS/Atom feeds for updates using the blogwatcher CLI.
RUN go install github.com/Hyaxia/blogwatcher/cmd/blogwatcher@latest

# [🐹] 🫐 blucli - BluOS CLI (blu) for discovery, playback, grouping, and volume.
RUN go install github.com/steipete/blucli/cmd/blu@latest

# [🐹] 📸 camsnap - Capture frames or clips from RTSP/ONVIF cameras.
RUN go install github.com/steipete/camsnap/cmd/camsnap@latest

# [🐹] 🎛️ eightctl - Control Eight Sleep pods (status, temperature, alarms, schedules).
RUN go install github.com/steipete/eightctl/cmd/eightctl@latest

# [🟥] ♊️ gemini - Gemini CLI for one-shot Q&A, summaries, and generation.
#RUN pnpm add -g @google/gemini-cli # ❗ FIXME: Ignored build scripts
RUN npm install -g @google/gemini-cli

# [🐹] 🧲 gifgrep - Search GIF providers with CLI/TUI, download results, and extract stills/sheets.
RUN go install github.com/steipete/gifgrep/cmd/gifgrep@latest

# [🐹] github - Interact with GitHub using the `gh` CLI. Use `gh issue`, `gh pr`, `gh run`, and `gh api` for issues, PRs, CI runs, and advanced queries.
RUN go install github.com/cli/cli/v2/cmd/gh@latest

# [🐹] 🎮 gog - Google Workspace CLI for Gmail, Calendar, Drive, Contacts, Sheets, and Docs.
RUN go install github.com/steipete/gogcli/cmd/gog@latest

# [🐹] 📍 goplaces - Query Google Places API (New) via the goplaces CLI for text search, place details, resolve, and reviews. Use for human-friendly place looku…
RUN go install github.com/steipete/goplaces/cmd/goplaces@latest

# [🍺/🐚] 📧 himalaya - CLI to manage emails via IMAP/SMTP. Use `himalaya` to list, read, write, reply, forward, search, and organize emails from the terminal. Sup…
#USER node
#RUN brew install himalaya
#USER root
RUN curl -fsSL https://github.com/pimalaya/himalaya/releases/latest/download/himalaya.x86_64-linux.tgz | tar xz -C /usr/local/bin himalaya

# [🟥] 📦 mcporter - Use the mcporter CLI to list, configure, auth, and call MCP servers/tools directly (HTTP or stdio), including ad-hoc servers, config edits,…
RUN pnpm add -g mcporter

# [🐍] 📄 nano-pdf - Edit PDFs with natural-language instructions using the nano-pdf CLI.
#RUN uv tool install nano-pdf # ❗ FIXME: @ /root/.local/bin | /config/clawdbot/.local/bin
RUN pip3 install --no-cache-dir --break-system-packages nano-pdf

# [🍺/🐹] 💎 obsidian - Work with Obsidian vaults (plain Markdown notes) and automate via obsidian-cli.
#USER node
#RUN brew install yakitrak/yakitrak/obsidian-cli # ❗ FIXME: Error: Broken pipe
#USER root
RUN go install github.com/Yakitrak/obsidian-cli@latest

# [🐍] 🎙️ openai-whisper - Local speech-to-text with the Whisper CLI (no API key).
#RUN uv tool install whisper-cli # ❗ FIXME: @ /root/.local/bin | /config/clawdbot/.local/bin
RUN pip3 install --no-cache-dir --break-system-packages whisper-cli

# [🍺/🐚] 💡 openhue - Control Philips Hue lights/scenes via the OpenHue CLI.
#USER node
#RUN brew install openhue/cli/openhue-cli
#USER root
RUN curl -fsSL https://github.com/openhue/openhue-cli/releases/latest/download/openhue_Linux_x86_64.tar.gz | tar xz -C /usr/local/bin openhue

# [🟥] 🧿 oracle - Best practices for using the oracle CLI (prompt + file bundling, engines, sessions, and file attachment patterns).
#RUN pnpm add -g @steipete/oracle # ❗ FIXME: Ignored build scripts
RUN npm install -g @steipete/oracle

# [🐹] 🛵 ordercli - Foodora-only CLI for checking past orders and active order status (Deliveroo WIP).
RUN go install github.com/steipete/ordercli/cmd/ordercli@latest

# [🍥+🐹] 🗣️ sag - ElevenLabs text-to-speech with mac-style say UX.
# apt install libasound2-dev
RUN go install github.com/steipete/sag/cmd/sag@latest

# [🐹] 🌊 songsee - Generate spectrograms and feature-panel visualizations from audio with the songsee CLI.
RUN go install github.com/steipete/songsee/cmd/songsee@latest

# [🐹] 🔊 sonoscli - Control Sonos speakers (discover/status/play/volume/group).
RUN go install github.com/steipete/sonoscli/cmd/sonos@latest

# [🟥] 🧾 summarize - Summarize or extract text/transcripts from URLs, podcasts, and local files (great fallback for “transcribe this YouTube/video”).
#RUN pnpm add -g @steipete/summarize # ❗ FIXME: Ignored build scripts
RUN npm install -g @steipete/summarize

# [🍥] 🧵 tmux - Remote-control tmux sessions for interactive CLIs by sending keystrokes and scraping pane output.
# apt install tmux

# [🍥] 🎞️ video-frames - Extract frames or short clips from videos using ffmpeg.
# apt install ffmpeg

# 📱 wacli - Send WhatsApp messages to other people or search/sync WhatsApp history via the wacli CLI (not for normal user chats).
RUN go install github.com/steipete/wacli/cmd/wacli@latest

# ------------------------------------------------------------------------------



WORKDIR /opt/openclaw

COPY run.sh /run.sh
COPY migrate.sh /migrate.sh
RUN chmod +x /run.sh /migrate.sh

CMD [ "/run.sh" ]
