#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/eko/pihole-exporter/

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
APP="pihole-exporter"
APP_TYPE="tools"
INSTALL_PATH="/opt/pihole-exporter"
CONFIG_PATH="/opt/pihole-exporter.env"

# ==============================================================================
# OS DETECTION
# ==============================================================================
if [[ -f "/etc/alpine-release" ]]; then
  OS="Alpine"
  SERVICE_PATH="/etc/init.d/pihole-exporter"
elif grep -qE 'ID=debian|ID=ubuntu' /etc/os-release; then
  OS="Debian"
  SERVICE_PATH="/etc/systemd/system/pihole-exporter.service"
else
  echo -e "${CROSS} 检测到不支持的操作系统。正在退出。"
  exit 1
fi

# ==============================================================================
# UNINSTALL
# ==============================================================================
function uninstall() {
  msg_info "正在卸载 Pihole-Exporter"
  if [[ "$OS" == "Alpine" ]]; then
    rc-service pihole-exporter stop &>/dev/null
    rc-update del pihole-exporter &>/dev/null
    rm -f "$SERVICE_PATH"
  else
    systemctl disable -q --now pihole-exporter
    rm -f "$SERVICE_PATH"
  fi
  rm -rf "$INSTALL_PATH" "$CONFIG_PATH"
  rm -f "/usr/local/bin/update_pihole-exporter"
  rm -f "$HOME/.pihole-exporter"
  msg_ok "Pihole-Exporter 已卸载"
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  if check_for_gh_release "pihole-exporter" "eko/pihole-exporter"; then
    msg_info "正在停止服务"
    if [[ "$OS" == "Alpine" ]]; then
      rc-service pihole-exporter stop &>/dev/null
    else
      systemctl stop pihole-exporter
    fi
    msg_ok "已停止服务"

    fetch_and_deploy_gh_release "pihole-exporter" "eko/pihole-exporter" "tarball" "latest"
    setup_go

    msg_info "正在构建 Pihole-Exporter"
    cd /opt/pihole-exporter/
    $STD /usr/local/bin/go build -o ./pihole-exporter
    msg_ok "已构建 Pihole-Exporter"

    msg_info "正在启动服务"
    if [[ "$OS" == "Alpine" ]]; then
      rc-service pihole-exporter start &>/dev/null
    else
      systemctl start pihole-exporter
    fi
    msg_ok "已启动服务"
    msg_ok "更新成功！"
    exit
  fi
}

# ==============================================================================
# INSTALL
# ==============================================================================
function install() {
  read -erp "输入要使用的协议（http/https），默认 https: " pihole_PROTOCOL
  read -erp "输入 Pihole 的主机名，例如：(127.0.0.1): " pihole_HOSTNAME
  read -erp "输入 Pihole 的端口，默认 443: " pihole_PORT
  read -rsp "输入 Pihole 密码: " pihole_PASSWORD
  printf "\n"
  read -erp "是否跳过 TLS 验证（如果 Pi-Hole 使用自签名证书）[y/N]: " SKIP_TLS
  if [[ "${SKIP_TLS,,}" =~ ^(y|yes)$ ]]; then
    pihole_SKIP_TLS="true"
  fi

  fetch_and_deploy_gh_release "pihole-exporter" "eko/pihole-exporter" "tarball" "latest"
  setup_go
  msg_info "正在 ${OS} 上构建 Pihole-Exporter"
  cd /opt/pihole-exporter/
  $STD /usr/local/bin/go build -o ./pihole-exporter
  msg_ok "已构建 Pihole-Exporter"

  msg_info "正在创建配置"
  cat <<EOF >"$CONFIG_PATH"
# https://github.com/eko/pihole-exporter/?tab=readme-ov-file#available-cli-options
PIHOLE_PASSWORD="${pihole_PASSWORD}"
PIHOLE_HOSTNAME="${pihole_HOSTNAME:-127.0.0.1}"
PIHOLE_PORT="${pihole_PORT:-443}"
SKIP_TLS_VERIFICATION="${pihole_SKIP_TLS:-false}"
PIHOLE_PROTOCOL="${pihole_PROTOCOL:-https}"
EOF
  msg_ok "已创建配置"

  msg_info "正在创建服务"
  if [[ "$OS" == "Debian" ]]; then
    cat <<EOF >"$SERVICE_PATH"
[Unit]
Description=pihole-exporter
After=network.target

[Service]
User=root
WorkingDirectory=/opt/pihole-exporter
EnvironmentFile=$CONFIG_PATH
ExecStart=/opt/pihole-exporter/pihole-exporter
Restart=always

[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable -q --now pihole-exporter
  else
    cat <<EOF >"$SERVICE_PATH"
#!/sbin/openrc-run

name="pihole-exporter"
description="Pi-hole Exporter for Prometheus"
command="${INSTALL_PATH}/pihole-exporter"
command_background=true
directory="/opt/pihole-exporter"
pidfile="/run/\${RC_SVCNAME}.pid"
output_log="/var/log/pihole-exporter.log"
error_log="/var/log/pihole-exporter.log"

depend() {
    need net
    after firewall
}

start_pre() {
    if [ -f "$CONFIG_PATH" ]; then
        export \$(grep -v '^#' $CONFIG_PATH | xargs)
    fi
}
EOF
    chmod +x "$SERVICE_PATH"
    $STD rc-update add pihole-exporter default
    $STD rc-service pihole-exporter start
  fi
  msg_ok "已创建并启动服务"

  # Create update script
  msg_info "正在创建更新脚本"
  ensure_usr_local_bin_persist
  cat <<'UPDATEEOF' >/usr/local/bin/update_pihole-exporter
#!/usr/bin/env bash
# pihole-exporter Update Script
type=update bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/pihole-exporter.sh)"
UPDATEEOF
  chmod +x /usr/local/bin/update_pihole-exporter
  msg_ok "已创建更新脚本 (/usr/local/bin/update_pihole-exporter)"

  echo ""
  msg_ok "Pihole-Exporter 安装成功"
  msg_ok "指标: ${BL}http://${LOCAL_IP}:9617/metrics${CL}"
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
  if [[ -d "$INSTALL_PATH" && -f "$INSTALL_PATH/pihole-exporter" ]]; then
    update
  else
    msg_error "Pihole-Exporter 未安装。无需更新。"
    exit 1
  fi
  exit 0
fi

# Check if already installed
if [[ -d "$INSTALL_PATH" && -f "$INSTALL_PATH/pihole-exporter" ]]; then
  msg_warn "Pihole-Exporter 已安装。"
  echo ""

  echo -n "${TAB}卸载 Pihole-Exporter? (y/N): "
  read -r uninstall_prompt
  if [[ "${uninstall_prompt,,}" =~ ^(y|yes)$ ]]; then
    uninstall
    exit 0
  fi

  echo -n "${TAB}更新 Pihole-Exporter? (y/N): "
  read -r update_prompt
  if [[ "${update_prompt,,}" =~ ^(y|yes)$ ]]; then
    update
    exit 0
  fi

  msg_warn "未选择操作。正在退出。"
  exit 0
fi

# Fresh installation
msg_warn "Pihole-Exporter 未安装。"
echo ""
echo -e "${TAB}${INFO} 这将安装："
echo -e "${TAB}  - Pi-hole Exporter（Go 二进制文件）"
echo -e "${TAB}  - Systemd/OpenRC 服务"
echo ""

echo -n "${TAB}安装 Pihole-Exporter? (y/N): "
read -r install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  install
else
  msg_warn "安装已取消。正在退出。"
  exit 0
fi
