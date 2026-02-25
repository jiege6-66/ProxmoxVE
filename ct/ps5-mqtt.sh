#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: liecno
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/FunkeyFlo/ps5-mqtt/

APP="PS5-MQTT"
var_tags="${var_tags:-smarthome;automation}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-3}"
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
  if [[ ! -d /opt/ps5-mqtt ]]; then
    msg_error "No ${APP} installation found!"
    exit
  fi
  if check_for_gh_release "ps5-mqtt" "FunkeyFlo/ps5-mqtt"; then
    msg_info "正在停止 service"
    systemctl stop ps5-mqtt
    msg_ok "已停止 service"

    fetch_and_deploy_gh_release "ps5-mqtt" "FunkeyFlo/ps5-mqtt" "tarball"

    msg_info "正在配置 ${APP}"
    cd /opt/ps5-mqtt/ps5-mqtt/
    $STD npm install
    $STD npm run build
    msg_ok "已配置 ${APP}"

    msg_info "正在启动 service"
    systemctl start ps5-mqtt
    msg_ok "已启动 service"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8645${CL}"
