#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/alangrainger/immich-public-proxy

if ! command -v curl &>/dev/null; then
  printf "\r\e[2K%b" '\033[93m Setup Source \033[m' >&2
  apt-get update >/dev/null 2>&1
  apt-get install -y curl >/dev/null 2>&1
fi
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/tools.func)
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/error_handler.func)
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/api.func) 2>/dev/null || true

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR

# ==============================================================================
# CONFIGURATION
# ==============================================================================
APP="Immich Public Proxy"
APP_TYPE="addon"
INSTALL_PATH="/opt/immich-proxy"
CONFIG_PATH="/opt/immich-proxy/app"
DEFAULT_PORT=3000

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions
init_tool_telemetry "" "addon"

# ==============================================================================
# HEADER
# ==============================================================================
function header_info {
  clear
  cat <<"EOF"
    ____                    _      __          ____
   /  _/___ ___  ____ ___  (_)____/ /_        / __ \_________  _  ____  __
   / // __ `__ \/ __ `__ \/ / ___/ __ \______/ /_/ / ___/ __ \| |/_/ / / /
 _/ // / / / / / / / / / / / /__/ / / /_____/ ____/ /  / /_/ />  </ /_/ /
/___/_/ /_/ /_/_/ /_/ /_/_/\___/_/ /_/     /_/   /_/   \____/_/|_|\__, /
                                                                 /____/
EOF
}

# ==============================================================================
# OS DETECTION
# ==============================================================================
if [[ -f "/etc/alpine-release" ]]; then
  msg_error "Alpine 不支持 ${APP}。请使用 Debian。"
  exit 1
elif [[ -f "/etc/debian_version" ]]; then
  OS="Debian"
  SERVICE_PATH="/etc/systemd/system/immich-proxy.service"
else
  echo -e "${CROSS} 检测到不支持的操作系统。正在退出。"
  exit 1
fi

# ==============================================================================
# UNINSTALL
# ==============================================================================
function uninstall() {
  msg_info "正在卸载 ${APP}"
  systemctl disable --now immich-proxy.service &>/dev/null || true
  rm -f "$SERVICE_PATH"
  rm -rf "$INSTALL_PATH"
  rm -f "/usr/local/bin/update_immich-public-proxy"
  rm -f "$HOME/.immichpublicproxy"
  msg_ok "${APP} 已卸载"
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  if check_for_gh_release "Immich Public Proxy" "alangrainger/immich-public-proxy"; then
    msg_info "正在停止服务"
    systemctl stop immich-proxy.service &>/dev/null || true
    msg_ok "已停止服务"

    msg_info "正在备份配置"
    cp "$CONFIG_PATH"/.env /tmp/ipp.env.bak 2>/dev/null || true
    cp "$CONFIG_PATH"/config.json /tmp/ipp.config.json.bak 2>/dev/null || true
    msg_ok "已备份配置"

    NODE_VERSION="24" setup_nodejs
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Immich Public Proxy" "alangrainger/immich-public-proxy" "tarball" "latest" "$INSTALL_PATH"

    msg_info "正在恢复配置"
    cp /tmp/ipp.env.bak "$CONFIG_PATH"/.env 2>/dev/null || true
    cp /tmp/ipp.config.json.bak "$CONFIG_PATH"/config.json 2>/dev/null || true
    rm -f /tmp/ipp.*.bak
    msg_ok "已恢复配置"

    msg_info "正在安装依赖项"
    cd "$CONFIG_PATH"
    $STD npm install
    msg_ok "已安装依赖项"

    msg_info "正在构建 ${APP}"
    $STD npm run build
    msg_ok "已构建 ${APP}"

    msg_info "正在更新服务"
    create_service
    msg_ok "已更新服务"

    msg_info "正在启动服务"
    systemctl start immich-proxy
    msg_ok "已启动服务"
    msg_ok "更新成功"
    exit
  fi
}

function create_service() {
  cat <<EOF >"$SERVICE_PATH"
[Unit]
Description=Immich Public Proxy
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_PATH}/app
EnvironmentFile=${CONFIG_PATH}/.env
ExecStart=/usr/bin/node ${INSTALL_PATH}/app/dist/index.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
}

# ==============================================================================
# INSTALL
# ==============================================================================
function install() {
  NODE_VERSION="24" setup_nodejs

  # Force fresh download by removing version cache
  rm -f "$HOME/.immichpublicproxy"
  fetch_and_deploy_gh_release "Immich Public Proxy" "alangrainger/immich-public-proxy" "tarball" "latest" "$INSTALL_PATH"

  msg_info "Installing dependencies"
  cd "$CONFIG_PATH"
  $STD npm install
  msg_ok "Installed dependencies"

  msg_info "Building ${APP}"
  $STD npm run build
  msg_ok "Built ${APP}"

  MAX_ATTEMPTS=3
  attempt=0
  while true; do
    attempt=$((attempt + 1))
    read -rp "${TAB3}输入您的本地 Immich IP 或域名（例如 192.168.1.100 或 immich.local.lan）: " DOMAIN
    if [[ -z "$DOMAIN" ]]; then
      if ((attempt >= MAX_ATTEMPTS)); then
        DOMAIN="${LOCAL_IP:-localhost}"
        msg_warn "使用备用值: $DOMAIN"
        break
      fi
      msg_warn "域名不能为空！（尝试 $attempt/$MAX_ATTEMPTS）"
    elif [[ "$DOMAIN" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
      valid_ip=true
      IFS='.' read -ra octets <<<"$DOMAIN"
      for octet in "${octets[@]}"; do
        if ((octet > 255)); then
          valid_ip=false
          break
        fi
      done
      if $valid_ip; then
        break
      else
        msg_warn "无效的 IP 地址！"
      fi
    elif [[ "$DOMAIN" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$ || "$DOMAIN" == "localhost" ]]; then
      break
    else
      msg_warn "无效的域名格式！"
    fi
  done

  msg_info "正在创建配置"
  cat <<EOF >"$CONFIG_PATH"/.env
NODE_ENV=production
IMMICH_URL=http://${DOMAIN}:2283
EOF
  chmod 600 "$CONFIG_PATH"/.env
  msg_ok "已创建配置"

  msg_info "正在创建服务"
  create_service
  systemctl enable -q --now immich-proxy
  msg_ok "已创建并启动服务"

  # Create update script (simple wrapper that calls this addon with type=update)
  msg_info "正在创建更新脚本"
  cat <<'UPDATEEOF' >/usr/local/bin/update_immich-public-proxy
#!/usr/bin/env bash
# Immich Public Proxy Update Script
type=update bash -c "$(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/tools/addon/immich-public-proxy.sh)"
UPDATEEOF
  chmod +x /usr/local/bin/update_immich-public-proxy
  msg_ok "已创建更新脚本 (/usr/local/bin/update_immich-public-proxy)"

  echo ""
  msg_ok "${APP} 可通过以下地址访问: ${BL}http://${LOCAL_IP}:${DEFAULT_PORT}${CL}"
  echo ""
  msg_warn "其他配置可在 '/opt/immich-proxy/app/config.json' 中找到"
}

# ==============================================================================
# MAIN
# ==============================================================================

# Handle type=update (called from update script)
if [[ "${type:-}" == "update" ]]; then
  header_info
  if [[ -d "$INSTALL_PATH" && -f "$SERVICE_PATH" ]]; then
    update
  else
    msg_error "${APP} 未安装。无需更新。"
    exit 1
  fi
  exit 0
fi

header_info
get_lxc_ip

# Check if already installed
if [[ -d "$INSTALL_PATH" && -f "$SERVICE_PATH" ]]; then
  msg_warn "${APP} 已安装。"
  echo ""

  echo -n "${TAB}卸载 ${APP}? (y/N): "
  read -r uninstall_prompt
  if [[ "${uninstall_prompt,,}" =~ ^(y|yes)$ ]]; then
    uninstall
    exit 0
  fi

  echo -n "${TAB}更新 ${APP}? (y/N): "
  read -r update_prompt
  if [[ "${update_prompt,,}" =~ ^(y|yes)$ ]]; then
    update
    exit 0
  fi

  msg_warn "未选择操作。正在退出。"
  exit 0
fi

# Fresh installation
msg_warn "${APP} 未安装。"
echo ""
echo -e "${TAB}${INFO} 这将安装："
echo -e "${TAB}  - Node.js 24"
echo -e "${TAB}  - Immich Public Proxy"
echo ""

echo -n "${TAB}安装 ${APP}? (y/N): "
read -r install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  install
else
  msg_warn "安装已取消。正在退出。"
  exit 0
fi
