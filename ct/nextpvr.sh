#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT
# https://github.com/tteck/Proxmox/raw/main/LICENSE
# Source: https://nextpvr.com/

APP="NextPVR"
var_tags="${var_tags:-pvr}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-5}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_gpu="${var_gpu:-yes}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/nextpvr ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  msg_info "正在停止 Service"
  systemctl stop nextpvr-server
  msg_ok "已停止 Service"

  msg_info "正在更新 LXC packages"
  $STD apt update
  $STD apt -y upgrade
  msg_ok "Updated LXC packages"

  msg_info "正在更新 ${APP}"
  cd /opt
  curl -fsSL "https://nextpvr.com/nextpvr-helper.deb" -o $(basename "https://nextpvr.com/nextpvr-helper.deb")
  $STD dpkg -i nextpvr-helper.deb
  rm -rf /opt/nextpvr-helper.deb
  msg_ok "Updated ${APP}"

  msg_info "正在启动 Service"
  systemctl start nextpvr-server
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8866${CL}"
