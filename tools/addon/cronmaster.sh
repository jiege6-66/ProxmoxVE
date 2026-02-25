#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/fccview/cronmaster

if ! command -v curl &>/dev/null; then
  printf "\r\e[2K%b" '\033[93m Setup Source \033[m' >&2
  apt-get update >/dev/null 2>&1
  apt-get install -y curl >/dev/null 2>&1
fi
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/error_handler.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR
load_functions
init_tool_telemetry "" "addon"

# ==============================================================================
# CONFIGURATION
# ==============================================================================
APP="CronMaster"
APP_TYPE="addon"
INSTALL_PATH="/opt/cronmaster"
CONFIG_PATH="/opt/cronmaster/.env"
SERVICE_PATH="/etc/systemd/system/cronmaster.service"
DEFAULT_PORT=3000

# ==============================================================================
# HEADER
# ==============================================================================
function header_info {
  clear
  cat <<"EOF"
   ______                __  ___           __
  / ____/________  ____ /  |/  /___ ______/ /____  _____
 / /   / ___/ __ \/ __ \/ /|_/ / __ `/ ___/ __/ _ \/ ___/
/ /___/ /  / /_/ / / / / /  / / /_/ (__  ) /_/  __/ /
\____/_/   \____/_/ /_/_/  /_/\__,_/____/\__/\___/_/

EOF
}

# ==============================================================================
# OS DETECTION
# ==============================================================================
if ! grep -qE 'ID=debian|ID=ubuntu' /etc/os-release 2>/dev/null; then
  echo -e "${CROSS} 检测到不支持的操作系统。此脚本仅支持 Debian 和 Ubuntu。"
  exit 1
fi

# ==============================================================================
# UNINSTALL
# ==============================================================================
function uninstall() {
  msg_info "正在卸载 ${APP}"
  systemctl disable --now cronmaster.service &>/dev/null || true
  rm -f "$SERVICE_PATH"
  rm -rf "$INSTALL_PATH"
  rm -f "/usr/local/bin/update_cronmaster"
  rm -f "$HOME/.cronmaster"
  rm -f "/root/cronmaster.creds"
  msg_ok "${APP} 已卸载"
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  if check_for_gh_release "cronmaster" "fccview/cronmaster"; then
    msg_info "正在停止服务"
    systemctl stop cronmaster.service &>/dev/null || true
    msg_ok "已停止服务"

    msg_info "正在备份配置"
    cp "$CONFIG_PATH" /tmp/cronmaster.env.bak 2>/dev/null || true
    msg_ok "已备份配置"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "cronmaster" "fccview/cronmaster" "prebuild" "latest" "$INSTALL_PATH" "cronmaster_*_prebuild.tar.gz"

    msg_info "正在恢复配置"
    cp /tmp/cronmaster.env.bak "$CONFIG_PATH" 2>/dev/null || true
    rm -f /tmp/cronmaster.env.bak
    msg_ok "已恢复配置"

    msg_info "正在启动服务"
    systemctl start cronmaster
    msg_ok "已启动服务"
    msg_ok "更新成功"
    exit
  fi
}

# ==============================================================================
# INSTALL
# ==============================================================================
function install() {
  # Setup Node.js (only installs if not present or different version)
  if command -v node &>/dev/null; then
    msg_ok "Node.js 已安装 ($(node -v))"
  else
    NODE_VERSION="22" setup_nodejs
  fi

  fetch_and_deploy_gh_release "cronmaster" "fccview/cronmaster" "prebuild" "latest" "$INSTALL_PATH" "cronmaster_*_prebuild.tar.gz"

  local AUTH_PASS
  AUTH_PASS="$(openssl rand -base64 18 | cut -c1-13)"

  msg_info "正在创建配置"
  cat <<EOF >"$CONFIG_PATH"
NODE_ENV=production
AUTH_PASSWORD=${AUTH_PASS}
PORT=${DEFAULT_PORT}
HOSTNAME=0.0.0.0
NEXT_TELEMETRY_DISABLED=1
EOF
  chmod 600 "$CONFIG_PATH"
  msg_ok "已创建配置"

  msg_info "正在创建服务"
  cat <<EOF >"$SERVICE_PATH"
[Unit]
Description=CronMaster Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_PATH}
EnvironmentFile=${CONFIG_PATH}
ExecStart=/usr/bin/node ${INSTALL_PATH}/server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now cronmaster
  msg_ok "已创建并启动服务"

  # Create update script
  msg_info "正在创建更新脚本"
  ensure_usr_local_bin_persist
  cat <<EOF >/usr/local/bin/update_cronmaster
#!/usr/bin/env bash
# CronMaster Update Script
type=update bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/cronmaster.sh)"
EOF
  chmod +x /usr/local/bin/update_cronmaster
  msg_ok "已创建更新脚本 (/usr/local/bin/update_cronmaster)"

  # Save credentials
  local CREDS_FILE="/root/cronmaster.creds"
  cat <<EOF >"$CREDS_FILE"
CronMaster 凭据
======================
密码: ${AUTH_PASS}

Web UI: http://${LOCAL_IP}:${DEFAULT_PORT}
EOF
  echo ""
  msg_ok "${APP} 可通过以下地址访问: ${BL}http://${LOCAL_IP}:${DEFAULT_PORT}${CL}"
  msg_ok "凭据已保存到: ${BL}${CREDS_FILE}${CL}"
  echo ""
}

# ==============================================================================
# MAIN
# ==============================================================================
header_info
ensure_usr_local_bin_persist
get_lxc_ip

# Handle type=update (called from update script)
if [[ "${type:-}" == "update" ]]; then
  if [[ -d "$INSTALL_PATH" ]]; then
    update
  else
    msg_error "${APP} 未安装。无需更新。"
    exit 1
  fi
  exit 0
fi

# Check if already installed
if [[ -d "$INSTALL_PATH" && -n "$(ls -A "$INSTALL_PATH" 2>/dev/null)" ]]; then
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
echo -e "${TAB}  - Node.js 22"
echo -e "${TAB}  - CronMaster (预构建版)"
echo ""

echo -n "${TAB}安装 ${APP}? (y/N): "
read -r install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  install
else
  msg_warn "安装已取消。正在退出。"
  exit 0
fi
