#!/usr/bin/env bash
set -euo pipefail

log() {
  printf "[addon] %s\n" "$*"
}

log "run.sh version=2026-01-05-public"

BASE_DIR=/config/clawdbot
STATE_DIR="${BASE_DIR}/.clawdbot"
REPO_DIR="${BASE_DIR}/clawdbot-src"
WORKSPACE_DIR="${BASE_DIR}/workspace"
SSH_AUTH_DIR="${BASE_DIR}/.ssh"

mkdir -p "${BASE_DIR}" "${STATE_DIR}" "${WORKSPACE_DIR}" "${SSH_AUTH_DIR}"

if [ -d /root/.clawdbot ] && [ ! -f "${STATE_DIR}/clawdbot.json" ]; then
  cp -a /root/.clawdbot/. "${STATE_DIR}/"
fi

if [ -d /root/clawdbot-src ] && [ ! -d "${REPO_DIR}" ]; then
  mv /root/clawdbot-src "${REPO_DIR}"
fi

if [ -d /root/workspace ] && [ ! -d "${WORKSPACE_DIR}" ]; then
  mv /root/workspace "${WORKSPACE_DIR}"
fi

export HOME="${BASE_DIR}"
export CLAWDBOT_STATE_DIR="${STATE_DIR}"
export CLAWDBOT_CONFIG_PATH="${STATE_DIR}/clawdbot.json"

log "config path=${CLAWDBOT_CONFIG_PATH}"

cat > /etc/profile.d/clawdbot.sh <<EOF
if [ -n "\${SSH_CONNECTION:-}" ]; then
  export CLAWDBOT_STATE_DIR="${STATE_DIR}"
  export CLAWDBOT_CONFIG_PATH="${STATE_DIR}/clawdbot.json"
  cd "${REPO_DIR}" 2>/dev/null || true
fi
EOF

auth_from_opts() {
  local val
  val="$(jq -r .ssh_authorized_keys /data/options.json 2>/dev/null || true)"
  if [ -n "${val}" ] && [ "${val}" != "null" ]; then
    printf "%s" "${val}"
  fi
}

REPO_URL="$(jq -r .repo_url /data/options.json)"
BRANCH="$(jq -r .branch /data/options.json 2>/dev/null || true)"
TOKEN_OPT="$(jq -r .github_token /data/options.json)"

if [ -z "${REPO_URL}" ] || [ "${REPO_URL}" = "null" ]; then
  log "repo_url is empty; set it in add-on options"
  exit 1
fi

if [ -n "${TOKEN_OPT}" ] && [ "${TOKEN_OPT}" != "null" ]; then
  REPO_URL="https://${TOKEN_OPT}@${REPO_URL#https://}"
fi

SSH_PORT="$(jq -r .ssh_port /data/options.json 2>/dev/null || true)"
SSH_KEYS="$(auth_from_opts || true)"
SSH_PORT_FILE="${STATE_DIR}/ssh_port"
SSH_KEYS_FILE="${STATE_DIR}/ssh_authorized_keys"

if [ -z "${SSH_PORT}" ] || [ "${SSH_PORT}" = "null" ]; then
  if [ -f "${SSH_PORT_FILE}" ]; then
    SSH_PORT="$(cat "${SSH_PORT_FILE}")"
  else
    SSH_PORT="2222"
  fi
fi

if [ -z "${SSH_KEYS}" ] || [ "${SSH_KEYS}" = "null" ]; then
  if [ -f "${SSH_KEYS_FILE}" ]; then
    SSH_KEYS="$(cat "${SSH_KEYS_FILE}")"
  fi
fi

if [ -n "${SSH_KEYS}" ] && [ "${SSH_KEYS}" != "null" ]; then
  printf "%s\n" "${SSH_PORT}" > "${SSH_PORT_FILE}"
  printf "%s\n" "${SSH_KEYS}" > "${SSH_KEYS_FILE}"
  chmod 700 "${SSH_AUTH_DIR}"
  printf "%s\n" "${SSH_KEYS}" > "${SSH_AUTH_DIR}/authorized_keys"
  chmod 600 "${SSH_AUTH_DIR}/authorized_keys"

  mkdir -p /var/run/sshd
  cat > /etc/ssh/sshd_config <<EOF_SSH
Port ${SSH_PORT}
Protocol 2
PermitRootLogin prohibit-password
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile ${SSH_AUTH_DIR}/authorized_keys
ChallengeResponseAuthentication no
ClientAliveInterval 30
ClientAliveCountMax 3
EOF_SSH

  ssh-keygen -A
  /usr/sbin/sshd -e -f /etc/ssh/sshd_config
  log "sshd listening on ${SSH_PORT}"
else
  log "sshd disabled (no authorized keys)"
fi

if [ "${BRANCH}" = "null" ]; then
  BRANCH=""
fi

if [ -n "${BRANCH}" ]; then
  log "branch=${BRANCH}"
fi

if [ ! -d "${REPO_DIR}/.git" ]; then
  log "cloning repo ${REPO_URL} -> ${REPO_DIR}"
  rm -rf "${REPO_DIR}"
  if [ -n "${BRANCH}" ]; then
    git clone --branch "${BRANCH}" "${REPO_URL}" "${REPO_DIR}"
  else
    git clone "${REPO_URL}" "${REPO_DIR}"
  fi
else
  log "updating repo in ${REPO_DIR}"
  git -C "${REPO_DIR}" remote set-url origin "${REPO_URL}"
  git -C "${REPO_DIR}" fetch --prune
  git -C "${REPO_DIR}" reset --hard
  git -C "${REPO_DIR}" clean -fd
  if [ -n "${BRANCH}" ]; then
    git -C "${REPO_DIR}" checkout "${BRANCH}"
    git -C "${REPO_DIR}" reset --hard "origin/${BRANCH}"
  else
    DEFAULT_BRANCH=$(git -C "${REPO_DIR}" remote show origin | sed -n '/HEAD branch/s/.*: //p')
    git -C "${REPO_DIR}" checkout "${DEFAULT_BRANCH}"
    git -C "${REPO_DIR}" reset --hard "origin/${DEFAULT_BRANCH}"
  fi
  git -C "${REPO_DIR}" clean -fd
fi

cd "${REPO_DIR}"

log "installing dependencies"
pnpm install --no-frozen-lockfile --force
log "building gateway"
pnpm build
if [ ! -d "${REPO_DIR}/ui/node_modules" ]; then
  log "installing UI dependencies"
  pnpm ui:install
fi
log "building control UI"
pnpm ui:build

if [ ! -f "${CLAWDBOT_CONFIG_PATH}" ]; then
  pnpm clawdbot setup --workspace "${WORKSPACE_DIR}"
else
  log "config exists; skipping clawdbot setup"
fi

ensure_gateway_mode() {
  node -e "const fs=require('fs');const JSON5=require('json5');const p=process.env.CLAWDBOT_CONFIG_PATH;const raw=fs.readFileSync(p,'utf8');const data=JSON5.parse(raw);const gateway=data.gateway||{};const mode=String(gateway.mode||'').trim();if(!mode){gateway.mode='local';data.gateway=gateway;fs.writeFileSync(p, JSON.stringify(data,null,2)+'\\n');console.log('updated');}else{console.log('unchanged');}" 2>/dev/null
}

read_gateway_mode() {
  node -e "const fs=require('fs');const JSON5=require('json5');const p=process.env.CLAWDBOT_CONFIG_PATH;const raw=fs.readFileSync(p,'utf8');const data=JSON5.parse(raw);const gateway=data.gateway||{};const mode=String(gateway.mode||'').trim();if(mode){console.log(mode);}"; 2>/dev/null
}

ensure_log_file() {
  node -e "const fs=require('fs');const JSON5=require('json5');const p=process.env.CLAWDBOT_CONFIG_PATH;const raw=fs.readFileSync(p,'utf8');const data=JSON5.parse(raw);const logging=data.logging||{};const file=String(logging.file||'').trim();if(!file){logging.file='/tmp/clawdbot/clawdbot.log';data.logging=logging;fs.writeFileSync(p, JSON.stringify(data,null,2)+'\\n');console.log('updated');}else{console.log('unchanged');}" 2>/dev/null
}

read_log_file() {
  node -e "const fs=require('fs');const JSON5=require('json5');const p=process.env.CLAWDBOT_CONFIG_PATH;const raw=fs.readFileSync(p,'utf8');const data=JSON5.parse(raw);const logging=data.logging||{};const file=String(logging.file||'').trim();if(file){console.log(file);}"; 2>/dev/null
}

if [ -f "${CLAWDBOT_CONFIG_PATH}" ]; then
  mode_status="$(ensure_gateway_mode || true)"
  if [ "${mode_status}" = "updated" ]; then
    log "gateway.mode set to local (missing)"
  elif [ "${mode_status}" = "unchanged" ]; then
    log "gateway.mode already set"
  else
    log "failed to normalize gateway.mode (invalid config?)"
  fi
fi

LOG_FILE="/tmp/clawdbot/clawdbot.log"
if [ -f "${CLAWDBOT_CONFIG_PATH}" ]; then
  log_status="$(ensure_log_file || true)"
  if [ "${log_status}" = "updated" ]; then
    log "logging.file set to ${LOG_FILE} (missing)"
  elif [ "${log_status}" = "unchanged" ]; then
    read_log="$(read_log_file || true)"
    if [ -n "${read_log}" ]; then
      LOG_FILE="${read_log}"
    fi
  else
    log "failed to normalize logging.file (invalid config?)"
  fi
fi

PORT="$(jq -r .port /data/options.json)"
VERBOSE="$(jq -r .verbose /data/options.json)"

if [ -z "${PORT}" ] || [ "${PORT}" = "null" ]; then
  PORT="18789"
fi

ALLOW_UNCONFIGURED=()
if [ ! -f "${CLAWDBOT_CONFIG_PATH}" ]; then
  log "config missing; allowing unconfigured gateway start"
  ALLOW_UNCONFIGURED=(--allow-unconfigured)
else
  gateway_mode="$(read_gateway_mode || true)"
  if [ -z "${gateway_mode}" ]; then
    log "gateway.mode missing; allowing unconfigured gateway start"
    ALLOW_UNCONFIGURED=(--allow-unconfigured)
  fi
fi

ARGS=(gateway "${ALLOW_UNCONFIGURED[@]}" --port "${PORT}")
if [ "${VERBOSE}" = "true" ]; then
  ARGS+=(--verbose)
fi

child_pid=""
tail_pid=""

forward_usr1() {
  if [ -n "${child_pid}" ]; then
    if ! pkill -USR1 -P "${child_pid}" 2>/dev/null; then
      kill -USR1 "${child_pid}" 2>/dev/null || true
    fi
    log "forwarded SIGUSR1 to gateway process"
  fi
}

shutdown_child() {
  if [ -n "${tail_pid}" ]; then
    kill -TERM "${tail_pid}" 2>/dev/null || true
  fi
  if [ -n "${child_pid}" ]; then
    kill -TERM "${child_pid}" 2>/dev/null || true
  fi
}

start_log_tail() {
  local file="$1"
  (
    while [ ! -f "${file}" ]; do
      sleep 1
    done
    tail -n +1 -F "${file}"
  ) &
  tail_pid=$!
}

trap forward_usr1 USR1
trap shutdown_child TERM INT

while true; do
  pnpm clawdbot "${ARGS[@]}" &
  child_pid=$!
  start_log_tail "${LOG_FILE}"
  set +e
  wait "${child_pid}"
  status=$?
  set -e
  if [ -n "${tail_pid}" ]; then
    kill -TERM "${tail_pid}" 2>/dev/null || true
    tail_pid=""
  fi

  if [ "${status}" -eq 0 ]; then
    log "gateway exited cleanly"
    break
  elif [ "${status}" -eq 129 ]; then
    log "gateway exited after SIGUSR1; restarting"
    continue
  else
    log "gateway exited uncleanly (status=${status}); restarting"
    continue
  fi
done

exit "${status}"
