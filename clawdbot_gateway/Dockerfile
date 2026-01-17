FROM node:24-bookworm-slim

# Use bash with pipefail so curl|tar failures stop the build.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Pull latest Debian security updates, then clean apt caches.
RUN apt-get update \
  && apt-get upgrade -y \
  && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    git \
    jq \
    ripgrep \
    curl \
    nano \
    python3 \
    python3-pip \
    make \
    g++ \
    openssh-server \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

ENV PNPM_HOME=/pnpm
ENV PATH="${PNPM_HOME}:${PATH}"

RUN npm install -g pnpm \
  && mkdir -p /pnpm \
  && pnpm config set global-bin-dir /pnpm \
  && pnpm add -g clawdhub

RUN pip3 install --no-cache-dir --break-system-packages homeassistant-cli

# Install gog CLI (Google Workspace: Gmail, Calendar, Drive, Contacts, Sheets, Docs)
ARG GOG_VERSION=0.6.1
ARG TARGETARCH
RUN ARCH=$(echo ${TARGETARCH:-$(uname -m)} | sed 's/aarch64/arm64/;s/x86_64/amd64/') \
  && curl -fsSL "https://github.com/steipete/gogcli/releases/download/v${GOG_VERSION}/gogcli_${GOG_VERSION}_linux_${ARCH}.tar.gz" \
     | tar xz -C /usr/local/bin gog \
  && chmod +x /usr/local/bin/gog

WORKDIR /opt/clawdbot

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD [ "/run.sh" ]
