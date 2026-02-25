#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://www.grandstream.com/products/networking-solutions/wi-fi-management/product/gwn-manager

APP="GWN-Manager"
var_tags="${var_tags:-network;management}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-6144}"
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
  if [[ ! -d /gwn ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  msg_custom "🚀" "${GN}" "The app offers a built-in updater. Please use it."
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:8443${CL}"
