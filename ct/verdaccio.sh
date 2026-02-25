#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: BrynnJKnight
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://verdaccio.org/

APP="Verdaccio"
var_tags="${var_tags:-dev-tools;npm;registry}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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
  if [[ ! -f /etc/systemd/system/verdaccio.service ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  msg_info "正在更新 LXC Container"
  $STD apt update
  $STD apt upgrade -y
  msg_ok "Updated LXC Container"

  NODE_VERSION="22" NODE_MODULE="verdaccio" setup_nodejs
  systemctl restart verdaccio
  msg_ok "已成功更新!"
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:4873${CL}"
