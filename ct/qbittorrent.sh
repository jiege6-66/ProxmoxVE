#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: tteck (tteckster) | Co-Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.qbittorrent.org/

APP="qBittorrent"
var_tags="${var_tags:-torrent}"
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
  if [[ ! -f /etc/systemd/system/qbittorrent-nox.service ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if [[ ! -f ~/.qbittorrent ]]; then
    msg_error "Please create new qBittorrent LXC. 正在更新 from v4.x to v5.x is not supported!"
    exit
  fi
  if check_for_gh_release "qbittorrent" "userdocs/qbittorrent-nox-static"; then
    msg_info "正在停止 Service"
    systemctl stop qbittorrent-nox
    msg_ok "已停止 Service"

    rm -f /opt/qbittorrent/qbittorrent-nox
    fetch_and_deploy_gh_release "qbittorrent" "userdocs/qbittorrent-nox-static" "singlefile" "latest" "/opt/qbittorrent" "x86_64-qbittorrent-nox"
    mv /opt/qbittorrent/qbittorrent /opt/qbittorrent/qbittorrent-nox

    msg_info "正在启动 Service"
    systemctl start qbittorrent-nox
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8090${CL}"
