#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Andy Grunwald (andygrunwald)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/hansmi/prometheus-paperless-exporter

source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/tools.func)
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/error_handler.func)
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/api.func) 2>/dev/null || true

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR
load_functions
init_tool_telemetry "" "addon"

# ==============================================================================
# CONFIGURATION
# ==============================================================================
VERBOSE=${var_verbose:-no}
APP="prometheus-paperless-ngx-exporter"
APP_TYPE="tools"
BINARY_PATH="/usr/bin/prometheus-paperless-exporter"
CONFIG_PATH="/etc/prometheus-paperless-ngx-exporter/config.env"
SERVICE_PATH="/etc/systemd/system/prometheus-paperless-ngx-exporter.service"
AUTH_TOKEN_FILE="/etc/prometheus-paperless-ngx-exporter/paperless_auth_token_file"

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
  msg_info "正在卸载 Prometheus-Paperless-NGX-Exporter"
  systemctl disable -q --now prometheus-paperless-ngx-exporter

  if dpkg -l | grep -q prometheus-paperless-exporter; then
    $STD apt-get remove -y prometheus-paperless-exporter || $STD dpkg -r prometheus-paperless-exporter
  fi

  rm -f "$SERVICE_PATH"
  rm -rf /etc/prometheus-paperless-ngx-exporter
  rm -f "/usr/local/bin/update_prometheus-paperless-ngx-exporter"
  rm -f "$HOME/.prometheus-paperless-ngx-exporter"
  msg_ok "Prometheus-Paperless-NGX-Exporter 已卸载"
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  if check_for_gh_release "prom-paperless-exp" "hansmi/prometheus-paperless-exporter"; then
    msg_info "正在停止服务"
    systemctl stop prometheus-paperless-ngx-exporter
    msg_ok "已停止服务"

    fetch_and_deploy_gh_release "prom-paperless-exp" "hansmi/prometheus-paperless-exporter" "binary" "latest"

    msg_info "正在启动服务"
    systemctl start prometheus-paperless-ngx-exporter
    msg_ok "已启动服务"
    msg_ok "更新成功！"
    exit
  fi
}

# ==============================================================================
# INSTALL
# ==============================================================================
function install() {
  read -erp "输入 Paperless-NGX URL，例如：(http://127.0.0.1:8000): " PAPERLESS_URL
  read -rsp "输入 Paperless-NGX 认证令牌: " PAPERLESS_AUTH_TOKEN
  printf "\n"

  fetch_and_deploy_gh_release "prom-paperless-exp" "hansmi/prometheus-paperless-exporter" "binary" "latest"

  msg_info "正在创建配置"
  mkdir -p /etc/prometheus-paperless-ngx-exporter
  cat <<EOF >"$CONFIG_PATH"
# https://github.com/hansmi/prometheus-paperless-exporter
PAPERLESS_URL="${PAPERLESS_URL}"
EOF
  echo "${PAPERLESS_AUTH_TOKEN}" >"$AUTH_TOKEN_FILE"
  chmod 600 "$AUTH_TOKEN_FILE"
  msg_ok "已创建配置"

  msg_info "正在创建服务"
  cat <<EOF >"$SERVICE_PATH"
[Unit]
Description=Prometheus Paperless NGX Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=root
EnvironmentFile=$CONFIG_PATH
ExecStart=$BINARY_PATH \\
    --paperless_url=\${PAPERLESS_URL} \\
    --paperless_auth_token_file=$AUTH_TOKEN_FILE
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  systemctl enable -q --now prometheus-paperless-ngx-exporter
  msg_ok "已创建并启动服务"

  # Create update script
  msg_info "正在创建更新脚本"
  ensure_usr_local_bin_persist
  cat <<'UPDATEEOF' >/usr/local/bin/update_prometheus-paperless-ngx-exporter
#!/usr/bin/env bash
# prometheus-paperless-ngx-exporter Update Script
type=update bash -c "$(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/tools/addon/prometheus-paperless-ngx-exporter.sh)"
UPDATEEOF
  chmod +x /usr/local/bin/update_prometheus-paperless-ngx-exporter
  msg_ok "已创建更新脚本 (/usr/local/bin/update_prometheus-paperless-ngx-exporter)"

  echo ""
  msg_ok "Prometheus-Paperless-NGX-Exporter 安装成功"
  msg_ok "指标: ${BL}http://${LOCAL_IP}:8081/metrics${CL}"
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
    msg_error "Prometheus-Paperless-NGX-Exporter 未安装。无需更新。"
    exit 1
  fi
  exit 0
fi

# Check if already installed
if [[ -f "$BINARY_PATH" ]]; then
  msg_warn "Prometheus-Paperless-NGX-Exporter 已安装。"
  echo ""

  echo -n "${TAB}卸载 Prometheus-Paperless-NGX-Exporter? (y/N): "
  read -r uninstall_prompt
  if [[ "${uninstall_prompt,,}" =~ ^(y|yes)$ ]]; then
    uninstall
    exit 0
  fi

  echo -n "${TAB}更新 Prometheus-Paperless-NGX-Exporter? (y/N): "
  read -r update_prompt
  if [[ "${update_prompt,,}" =~ ^(y|yes)$ ]]; then
    update
    exit 0
  fi

  msg_warn "未选择操作。正在退出。"
  exit 0
fi

# Fresh installation
msg_warn "Prometheus-Paperless-NGX-Exporter 未安装。"
echo ""
echo -e "${TAB}${INFO} 这将安装："
echo -e "${TAB}  - Prometheus Paperless NGX Exporter（二进制文件）"
echo -e "${TAB}  - Systemd 服务"
echo ""

echo -n "${TAB}安装 Prometheus-Paperless-NGX-Exporter? (y/N): "
read -r install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  install
else
  msg_warn "安装已取消。正在退出。"
  exit 0
fi
