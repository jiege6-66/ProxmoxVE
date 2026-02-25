#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Donkie/Spoolman

APP="Spoolman"
var_tags="${var_tags:-3d-printing}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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
  if [[ ! -d /opt/spoolman ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  PYTHON_VERSION="3.14" setup_uv

  if check_for_gh_release "spoolman" "Donkie/Spoolman"; then
    msg_info "正在停止 Service"
    systemctl stop spoolman
    msg_ok "已停止 Service"

    msg_info "正在创建 Backup"
    [ -d /opt/spoolman_bak ] && rm -rf /opt/spoolman_bak
    mv /opt/spoolman /opt/spoolman_bak
    msg_ok "已创建 Backup"

    fetch_and_deploy_gh_release "spoolman" "Donkie/Spoolman" "prebuild" "latest" "/opt/spoolman" "spoolman.zip"

    msg_info "正在更新 Spoolman"
    cd /opt/spoolman
    $STD uv sync --locked --no-install-project
    $STD uv sync --locked
    cp /opt/spoolman_bak/.env /opt/spoolman
    sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/bash /opt/spoolman/scripts/start.sh|' /etc/systemd/system/spoolman.service
    msg_ok "Updated Spoolman"

    msg_info "正在启动 Service"
    systemctl start spoolman
    msg_ok "已启动 Service"
    msg_ok "已成功更新!"
  fi
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7912${CL}"
