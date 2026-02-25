#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Andy Grunwald (andygrunwald)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/prometheus-pve/prometheus-pve-exporter

APP="Prometheus-PVE-Exporter"
var_tags="${var_tags:-monitoring}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/systemd/system/prometheus-pve-exporter.service ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  msg_info "正在停止 Service"
  systemctl stop prometheus-pve-exporter
  msg_ok "已停止 Service"

  export PVE_VENV_PATH="/opt/prometheus-pve-exporter/.venv"
  export PVE_EXPORTER_BIN="${PVE_VENV_PATH}/bin/pve_exporter"

  if [[ ! -d "$PVE_VENV_PATH" || ! -x "$PVE_EXPORTER_BIN" ]]; then
    PYTHON_VERSION="3.12" setup_uv
    msg_info "正在迁移 to uv/venv"
    rm -rf "$PVE_VENV_PATH"
    mkdir -p /opt/prometheus-pve-exporter
    cd /opt/prometheus-pve-exporter
    $STD uv venv --clear "$PVE_VENV_PATH"
    $STD "$PVE_VENV_PATH/bin/python" -m ensurepip --upgrade
    $STD "$PVE_VENV_PATH/bin/python" -m pip install --upgrade pip
    $STD "$PVE_VENV_PATH/bin/python" -m pip install prometheus-pve-exporter
    msg_ok "已迁移 to uv/venv"
  else
    msg_info "正在更新 Prometheus Proxmox VE Exporter"
    PYTHON_VERSION="3.12" setup_uv
    $STD "$PVE_VENV_PATH/bin/python" -m pip install --upgrade prometheus-pve-exporter
    msg_ok "Updated Prometheus Proxmox VE Exporter"
  fi
  local service_file="/etc/systemd/system/prometheus-pve-exporter.service"
  if ! grep -q "${PVE_VENV_PATH}/bin/pve_exporter" "$service_file"; then
    msg_info "正在更新 systemd service"
    cat <<EOF >"$service_file"
[Unit]
Description=Prometheus Proxmox VE Exporter
Documentation=https://github.com/znerol/prometheus-pve-exporter
After=syslog.target network.target

[Service]
User=root
Restart=always
Type=simple
ExecStart=${PVE_VENV_PATH}/bin/pve_exporter \\
    --config.file=/opt/prometheus-pve-exporter/pve.yml \\
    --web.listen-address=0.0.0.0:9221
ExecReload=/bin/kill -HUP \$MAINPID

[Install]
WantedBy=multi-user.target
EOF
    $STD systemctl daemon-reload
    msg_ok "Updated systemd service"
  fi

  msg_info "正在启动 Service"
  systemctl start prometheus-pve-exporter
  msg_ok "已启动 Service"

  msg_ok "已成功更新!"
  exit 0
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9221${CL}"
