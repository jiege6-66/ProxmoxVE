#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://www.wireguard.com/

APP="Alpine-Wireguard"
var_tags="${var_tags:-alpine;vpn}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
var_disk="${var_disk:-1}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.23}"
var_unprivileged="${var_unprivileged:-1}"
var_tun="${var_tun:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  msg_info "正在更新 Alpine Packages"
  $STD apk -U upgrade
  msg_ok "Updated Alpine Packages"

  msg_info "update wireguard-tools"
  $STD apk add --no-cache --upgrade wireguard-tools
  msg_ok "wireguard-tools updated"

  if [[ -d /etc/wgdashboard/src ]]; then
    msg_info "update WGDashboard"
    cd /etc/wgdashboard/src
    echo "y" | ./wgd.sh update >/dev/null 2>&1
    $STD ./wgd.sh start
    msg_ok "WGDashboard updated"
  fi
  msg_ok "已成功更新!"
  exit 0
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} WGDashboard 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:10086${CL}"
