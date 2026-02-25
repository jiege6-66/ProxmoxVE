#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/xperimental/nextcloud-exporter

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
VERBOSE=${var_verbose:-no}
APP="nextcloud-exporter"
APP_TYPE="tools"
BINARY_PATH="/usr/bin/nextcloud-exporter"
CONFIG_PATH="/etc/nextcloud-exporter.env"
SERVICE_PATH="/etc/systemd/system/nextcloud-exporter.service"

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
  msg_info "正在卸载 Nextcloud-Exporter"
  systemctl disable -q --now nextcloud-exporter
  rm -f "$SERVICE_PATH"

  if dpkg -l | grep -q nextcloud-exporter; then
    $STD apt-get remove -y nextcloud-exporter || $STD dpkg -r nextcloud-exporter
  fi

  rm -f "$CONFIG_PATH"
  rm -f "/usr/local/bin/update_nextcloud-exporter"
  rm -f "$HOME/.nextcloud-exporter"
  msg_ok "Nextcloud-Exporter 已卸载"
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  if check_for_gh_release "nextcloud-exporter" "xperimental/nextcloud-exporter"; then
    msg_info "正在停止服务"
    systemctl stop nextcloud-exporter
    msg_ok "已停止服务"

    fetch_and_deploy_gh_release "nextcloud-exporter" "xperimental/nextcloud-exporter" "binary" "latest"

    msg_info "正在启动服务"
    systemctl start nextcloud-exporter
    msg_ok "已启动服务"
    msg_ok "更新成功！"
    exit
  fi
}

# ==============================================================================
# INSTALL
# ==============================================================================
function install() {
  read -erp "输入 Nextcloud URL，例如：(http://127.0.0.1:8080): " NEXTCLOUD_SERVER
  read -rsp "输入 Nextcloud 认证令牌（按 Enter 使用用户名/密码）: " NEXTCLOUD_AUTH_TOKEN
  printf "\n"

  if [[ -z "$NEXTCLOUD_AUTH_TOKEN" ]]; then
    read -erp "输入 Nextcloud 用户名: " NEXTCLOUD_USERNAME
    read -rsp "输入 Nextcloud 密码: " NEXTCLOUD_PASSWORD
    printf "\n"
  fi

  read -erp "查询应用的额外信息？[Y/n]: " QUERY_APPS
  if [[ "${QUERY_APPS,,}" =~ ^(n|no)$ ]]; then
    NEXTCLOUD_INFO_APPS="false"
  fi

  read -erp "查询更新信息？[Y/n]: " QUERY_UPDATES
  if [[ "${QUERY_UPDATES,,}" =~ ^(n|no)$ ]]; then
    NEXTCLOUD_INFO_UPDATE="false"
  fi

  read -erp "是否跳过 TLS 验证（如果 Nextcloud 使用自签名证书）[y/N]: " SKIP_TLS
  if [[ "${SKIP_TLS,,}" =~ ^(y|yes)$ ]]; then
    NEXTCLOUD_TLS_SKIP_VERIFY="true"
  fi

  fetch_and_deploy_gh_release "nextcloud-exporter" "xperimental/nextcloud-exporter" "binary" "latest"

  msg_info "正在创建配置"
  cat <<EOF >"$CONFIG_PATH"
# https://github.com/xperimental/nextcloud-exporter
NEXTCLOUD_SERVER="${NEXTCLOUD_SERVER}"
NEXTCLOUD_AUTH_TOKEN="${NEXTCLOUD_AUTH_TOKEN:-}"
NEXTCLOUD_USERNAME="${NEXTCLOUD_USERNAME:-}"
NEXTCLOUD_PASSWORD="${NEXTCLOUD_PASSWORD:-}"
NEXTCLOUD_INFO_UPDATE=${NEXTCLOUD_INFO_UPDATE:-"true"}
NEXTCLOUD_INFO_APPS=${NEXTCLOUD_INFO_APPS:-"true"}
NEXTCLOUD_TLS_SKIP_VERIFY=${NEXTCLOUD_TLS_SKIP_VERIFY:-"false"}
NEXTCLOUD_LISTEN_ADDRESS=":9205"
EOF
  msg_ok "已创建配置"

  msg_info "正在创建服务"
  cat <<EOF >"$SERVICE_PATH"
[Unit]
Description=nextcloud-exporter
After=network.target

[Service]
User=root
EnvironmentFile=$CONFIG_PATH
ExecStart=$BINARY_PATH
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable -q --now nextcloud-exporter
  msg_ok "已创建并启动服务"

  # Create update script
  msg_info "正在创建更新脚本"
  ensure_usr_local_bin_persist
  cat <<'UPDATEEOF' >/usr/local/bin/update_nextcloud-exporter
#!/usr/bin/env bash
# nextcloud-exporter Update Script
type=update bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/nextcloud-exporter.sh)"
UPDATEEOF
  chmod +x /usr/local/bin/update_nextcloud-exporter
  msg_ok "已创建更新脚本 (/usr/local/bin/update_nextcloud-exporter)"

  echo ""
  msg_ok "Nextcloud-Exporter 安装成功"
  msg_ok "指标: ${BL}http://${LOCAL_IP}:9205/metrics${CL}"
  msg_ok "配置文件: ${BL}${CONFIG_PATH}${CL}"
}

# ==============================================================================
# MAIN
# ==============================================================================
header_info
ensure_usr_local_bin_persist
get_lxc_ip

# Handle type=update (called from update script)
if [[ "${type:-}" == "update" ]]; then
  if [[ -f "$BINARY_PATH" ]]; then
    update
  else
    msg_error "Nextcloud-Exporter 未安装。无需更新。"
    exit 1
  fi
  exit 0
fi

# Check if already installed
if [[ -f "$BINARY_PATH" ]]; then
  msg_warn "Nextcloud-Exporter 已安装。"
  echo ""

  echo -n "${TAB}卸载 Nextcloud-Exporter? (y/N): "
  read -r uninstall_prompt
  if [[ "${uninstall_prompt,,}" =~ ^(y|yes)$ ]]; then
    uninstall
    exit 0
  fi

  echo -n "${TAB}更新 Nextcloud-Exporter? (y/N): "
  read -r update_prompt
  if [[ "${update_prompt,,}" =~ ^(y|yes)$ ]]; then
    update
    exit 0
  fi

  msg_warn "未选择操作。正在退出。"
  exit 0
fi

# Fresh installation
msg_warn "Nextcloud-Exporter 未安装。"
echo ""
echo -e "${TAB}${INFO} 这将安装："
echo -e "${TAB}  - Nextcloud Exporter（二进制文件）"
echo -e "${TAB}  - Systemd 服务"
echo ""

echo -n "${TAB}安装 Nextcloud-Exporter? (y/N): "
read -r install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  install
else
  msg_warn "安装已取消。正在退出。"
  exit 0
fi
