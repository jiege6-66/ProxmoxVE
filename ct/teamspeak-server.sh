#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: tremor021 (Slaviša Arežina)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://teamspeak.com/en/

APP="Teamspeak-Server"
var_tags="${var_tags:-voice;communication}"
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
  if [[ ! -d /opt/teamspeak-server ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  RELEASE=$(curl -fsSL https://teamspeak.com/en/downloads/#server | grep -oP 'teamspeak3-server_linux_amd64-\K[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  if [[ "${RELEASE}" != "$(cat ~/.teamspeak-server 2>/dev/null)" ]] || [[ ! -f ~/.teamspeak-server ]]; then
    msg_info "正在停止 Service"
    systemctl stop teamspeak-server
    msg_ok "已停止 Service"

    msg_info "正在更新 Teamspeak Server"
    curl -fsSL "https://files.teamspeak-services.com/releases/server/${RELEASE}/teamspeak3-server_linux_amd64-${RELEASE}.tar.bz2" -o ts3server.tar.bz2
    tar -xf ./ts3server.tar.bz2
    cp -ru teamspeak3-server_linux_amd64/* /opt/teamspeak-server/
    rm -f ~/ts3server.tar.bz*
    echo "${RELEASE}" >~/.teamspeak-server
    msg_ok "Updated Teamspeak Server"

    msg_info "正在启动 Service"
    systemctl start teamspeak-server
    msg_ok "已启动 Service"
    msg_ok "已成功更新!"
  else
    msg_ok "Already up to date"
  fi
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}${IP}:9987${CL}"
