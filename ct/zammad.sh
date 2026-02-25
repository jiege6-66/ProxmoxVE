#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://zammad.com

APP="Zammad"
var_tags="${var_tags:-webserver;ticket-system}"
var_disk="${var_disk:-8}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/zammad ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  msg_info "正在停止 Service"
  systemctl stop zammad
  msg_ok "已停止 Service"

  msg_info "正在更新 Zammad"
  $STD apt update
  $STD apt-mark hold zammad
  $STD apt upgrade -y
  $STD apt-mark unhold zammad
  $STD apt upgrade -y
  msg_ok "Updated Zammad"

  msg_info "正在启动 Service"
  systemctl start zammad
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
