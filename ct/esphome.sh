#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://esphome.io/

APP="ESPHome"
var_tags="${var_tags:-automation}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-10}"
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
  if [[ ! -f /etc/systemd/system/esphomeDashboard.service ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  msg_info "正在停止 Service"
  systemctl stop esphomeDashboard
  msg_ok "已停止 Service"

  VENV_PATH="/opt/esphome/.venv"
  ESPHOME_BIN="${VENV_PATH}/bin/esphome"
  export PYTHON_VERSION="3.12"

  if [[ ! -d "$VENV_PATH" || ! -x "$ESPHOME_BIN" ]]; then
    PYTHON_VERSION="3.12" setup_uv
    msg_info "正在迁移 to uv/venv"
    rm -rf "$VENV_PATH"
    mkdir -p /opt/esphome
    cd /opt/esphome
    $STD uv venv --clear "$VENV_PATH"
    $STD "$VENV_PATH/bin/python" -m ensurepip --upgrade
    $STD "$VENV_PATH/bin/python" -m pip install --upgrade pip
    $STD "$VENV_PATH/bin/python" -m pip install esphome tornado esptool
    msg_ok "已迁移 to uv/venv"
  else
    msg_info "正在更新 ESPHome"
    PYTHON_VERSION="3.12" setup_uv
    $STD "$VENV_PATH/bin/python" -m pip install --upgrade esphome tornado esptool
    msg_ok "Updated ESPHome"
  fi
  SERVICE_FILE="/etc/systemd/system/esphomeDashboard.service"
  if ! grep -q "${VENV_PATH}/bin/esphome" "$SERVICE_FILE"; then
    msg_info "正在更新 systemd service"
    cat <<EOF >"$SERVICE_FILE"
[Unit]
Description=ESPHome Dashboard
After=network.target

[Service]
ExecStart=${VENV_PATH}/bin/esphome dashboard /root/config/
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
    $STD systemctl daemon-reload
    msg_ok "Updated systemd service"
  fi

  msg_info "Linking esphome to /usr/local/bin"
  rm -f /usr/local/bin/esphome
  ln -s /opt/esphome/.venv/bin/esphome /usr/local/bin/esphome
  msg_ok "Linked esphome binary"

  msg_info "正在启动 Service"
  systemctl start esphomeDashboard
  msg_ok "已启动 Service"
  msg_ok "已成功更新!"
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6052${CL}"
