#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://www.wireguard.com/

APP="Wireguard"
var_tags="${var_tags:-network;vpn}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_tun="${var_tun:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /etc/wireguard ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  
  ensure_dependencies git

  msg_info "正在更新 LXC"
  $STD apt update
  $STD apt upgrade -y
  if [[ -d /etc/wgdashboard ]]; then
    sleep 2
    cd /etc/wgdashboard/src
    $STD ./wgd.sh update
    $STD ./wgd.sh start
  fi
  msg_ok "Updated LXC"
  msg_ok "已成功更新!"
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW}Access WGDashboard (if installed) using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:10086${CL}"
