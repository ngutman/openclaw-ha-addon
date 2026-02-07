#!/usr/bin/env bash
set -euo pipefail

log() {
  printf "[addon] %s\n" "$*"
}

log "run.sh version=2026-02-01-openclaw-only"

BASE_DIR=/config/openclaw
STATE_DIR="${BASE_DIR}/.openclaw"
CONFIG_PATH="${STATE_DIR}/openclaw.json"
REPO_DIR="${BASE_DIR}/openclaw-src"
WORKSPACE_DIR="${BASE_DIR}/workspace"
SSH_AUTH_DIR="${BASE_DIR}/.ssh"
PNPM_HOME="${BASE_DIR}/.local/share/pnpm"

if [ -x /migrate.sh ]; then
  /migrate.sh
fi

mkdir -p "${BASE_DIR}" "${STATE_DIR}" "${WORKSPACE_DIR}" "${SSH_AUTH_DIR}" "${PNPM_HOME}"

# Create persistent directories
mkdir -p "${BASE_DIR}/.config/gh" "${BASE_DIR}/.local" "${BASE_DIR}/.cache" "${BASE_DIR}/.npm" "${BASE_DIR}/bin"

# Symlink /root dirs to persistent storage (needed because some tools ignore $HOME for root)
for dir in .ssh .config .local .cache .npm; do
  target="${BASE_DIR}/${dir}"
  link="/root/${dir}"
  if [ -L "${link}" ]; then
    :
  elif [ -d "${link}" ]; then
    cp -rn "${link}/." "${target}/" 2>/dev/null || true
    rm -rf "${link}"
    ln -s "${target}" "${link}"
  else
    rm -f "${link}" 2>/dev/null || true
    ln -s "${target}" "${link}"
  fi
done
log "persistent home symlinks configured"

if [ -d /root/workspace ] && [ ! -d "${WORKSPACE_DIR}" ]; then
  mv /root/workspace "${WORKSPACE_DIR}"
fi

export HOME="${BASE_DIR}"
export PNPM_HOME="${PNPM_HOME}"
export PATH="${BASE_DIR}/bin:${PNPM_HOME}:${PATH}"
export CI=true
export OPENCLAW_STATE_DIR="${STATE_DIR}"
export OPENCLAW_CONFIG_PATH="${CONFIG_PATH}"

log "config path=${CONFIG_PATH}"

cat > /etc/profile.d/openclaw.sh <<EOF
export HOME="${BASE_DIR}"
export GH_CONFIG_DIR="${BASE_DIR}/.config/gh"
export PNPM_HOME="${PNPM_HOME}"
export PATH="${BASE_DIR}/bin:${PNPM_HOME}:\${PATH}"
if [ -n "\${SSH_CONNECTION:-}" ]; then
  export OPENCLAW_STATE_DIR="${STATE_DIR}"
  export OPENCLAW_CONFIG_PATH="${CONFIG_PATH}"
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

require_openclaw_repo() {
  local name
  if [ ! -f "${REPO_DIR}/package.json" ]; then
    log "missing package.json in repo; update repo_url/branch to OpenClaw"
    exit 1
  fi
  name="$(node -e "const fs=require('fs');const p='${REPO_DIR}/package.json';const data=JSON.parse(fs.readFileSync(p,'utf8'));process.stdout.write(data.name||'');")"
  if [ "${name}" != "openclaw" ]; then
    log "unsupported repo (${name}); only OpenClaw is supported"
    log "update repo_url/branch to https://github.com/openclaw/openclaw.git and restart the add-on"
    exit 1
  fi
  if [ ! -f "${REPO_DIR}/openclaw.mjs" ]; then
    log "openclaw.mjs missing; update repo_url/branch to a recent OpenClaw revision"
    exit 1
  fi
}

ensure_openclaw_wrapper() {
  cat > "${BASE_DIR}/bin/openclaw" <<'EOF_WRAPPER'
#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="/config/openclaw/openclaw-src"
exec node "${REPO_DIR}/openclaw.mjs" "$@"
EOF_WRAPPER
  chmod +x "${BASE_DIR}/bin/openclaw"
}

ensure_gateway_auth_token() {
  node -e "const fs=require('fs');const crypto=require('crypto');const JSON5=require('json5');const p=process.env.OPENCLAW_CONFIG_PATH;const raw=fs.readFileSync(p,'utf8');const data=JSON5.parse(raw);const gateway=data.gateway||{};const auth=gateway.auth||{};let updated=false;const token=String(auth.token||'').trim();if(!token){auth.token=crypto.randomBytes(24).toString('hex');auth.mode=auth.mode||'token';gateway.auth=auth;data.gateway=gateway;fs.writeFileSync(p, JSON.stringify(data,null,2)+'\\n');updated=true;}if(updated){console.log('updated');}else{console.log('unchanged');}" 2>/dev/null
}

needs_build="true"

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
  git -C "${REPO_DIR}" fetch --prune --tags
  current_head="$(git -C "${REPO_DIR}" rev-parse HEAD)"
  git -C "${REPO_DIR}" reset --hard
  git -C "${REPO_DIR}" clean -fd
  if [ -n "${BRANCH}" ]; then
    # Check if "origin/${BRANCH}" exists (meaning it's a branch)
    if git -C "${REPO_DIR}" rev-parse --verify "origin/${BRANCH}" >/dev/null 2>&1; then
      log "Checking out branch: ${BRANCH}"
      # Reset local branch to match remote exactly
      git -C "${REPO_DIR}" checkout -B "${BRANCH}" "origin/${BRANCH}"
      target_head="$(git -C "${REPO_DIR}" rev-parse HEAD)"
    else
      # If not found on origin, treat it as a Tag or Commit SHA
      log "Checking out tag/commit: ${BRANCH}"
      git -C "${REPO_DIR}" checkout --force "${BRANCH}"
      target_head="$(git -C "${REPO_DIR}" rev-parse HEAD)"
    fi
  else
    # Fallback to default branch if no specific branch/tag is defined
    target_branch="$(git -C "${REPO_DIR}" remote show origin | sed -n '/HEAD branch/s/.*: //p')"
    if [ -z "${target_branch}" ]; then
      log "failed to determine default branch"
      exit 1
    fi
    git -C "${REPO_DIR}" checkout "${target_branch}"
    git -C "${REPO_DIR}" reset --hard "origin/${target_branch}"
    target_head="$(git -C "${REPO_DIR}" rev-parse HEAD)"
  fi
  if [ "${current_head}" = "${target_head}" ]; then
    needs_build="false"
  fi
fi

cd "${REPO_DIR}"

require_openclaw_repo
ensure_openclaw_wrapper

if [ ! -d "${REPO_DIR}/node_modules" ]; then
  needs_build="true"
fi

needs_ui_build="${needs_build}"
if [ ! -d "${REPO_DIR}/ui/node_modules" ]; then
  needs_ui_build="true"
fi

if [ "${needs_build}" = "true" ] || [ "${needs_ui_build}" = "true" ]; then
  pnpm config set confirmModulesPurge false >/dev/null 2>&1 || true
  pnpm config set global-bin-dir "${PNPM_HOME}" >/dev/null 2>&1 || true
  pnpm config set global-dir "${BASE_DIR}/.local/share/pnpm/global" >/dev/null 2>&1 || true
fi

if [ "${needs_build}" = "true" ]; then
  log "installing dependencies"
  pnpm install --no-frozen-lockfile --prefer-frozen-lockfile --prod=false
  log "building gateway"
  pnpm build
else
  log "repo unchanged; skipping dependency install/build"
fi

if [ "${needs_ui_build}" = "true" ]; then
  if [ ! -d "${REPO_DIR}/ui/node_modules" ]; then
    log "installing UI dependencies"
    pnpm ui:install
  fi
  log "building control UI"
  pnpm ui:build
else
  log "repo unchanged; skipping UI build"
fi

if [ ! -f "${OPENCLAW_CONFIG_PATH}" ]; then
  openclaw setup --workspace "${WORKSPACE_DIR}"
else
  log "config exists; skipping openclaw setup"
fi

if [ -f "${OPENCLAW_CONFIG_PATH}" ]; then
  auth_status="$(ensure_gateway_auth_token || true)"
  if [ "${auth_status}" = "updated" ]; then
    log "gateway.auth.token set (missing)"
  elif [ "${auth_status}" = "unchanged" ]; then
    log "gateway.auth.token already set"
  else
    log "failed to normalize gateway.auth.token (invalid config?)"
  fi
fi

PORT="$(jq -r .port /data/options.json)"
VERBOSE="$(jq -r .verbose /data/options.json)"
if [ -z "${PORT}" ] || [ "${PORT}" = "null" ]; then
  PORT="18789"
fi

ALLOW_UNCONFIGURED=()
if [ ! -f "${OPENCLAW_CONFIG_PATH}" ]; then
  log "config missing; allowing unconfigured gateway start"
  ALLOW_UNCONFIGURED=(--allow-unconfigured)
fi

ARGS=(gateway "${ALLOW_UNCONFIGURED[@]}" --port "${PORT}")
if [ "${VERBOSE}" = "true" ]; then
  ARGS+=(--verbose)
fi

exec openclaw "${ARGS[@]}"
