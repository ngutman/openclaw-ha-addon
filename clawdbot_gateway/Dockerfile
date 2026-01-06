FROM node:22-bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    git \
    jq \
    curl \
    nano \
    python3 \
    make \
    g++ \
    openssh-server \
  && rm -rf /var/lib/apt/lists/*

RUN npm install -g pnpm@9.12.3

WORKDIR /opt/clawdbot

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD [ "/run.sh" ]
