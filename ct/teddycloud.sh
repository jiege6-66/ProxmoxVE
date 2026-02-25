#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Dominik Siebel (dsiebel)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/toniebox-reverse-engineering/teddycloud

APP="TeddyCloud"
var_tags="${var_tags:-media}"
var_cpu="${var_cpu:-2}"
var_disk="${var_disk:-8}"
var_ram="${var_ram:-1024}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "${APP}"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/teddycloud ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "teddycloud" "toniebox-reverse-engineering/teddycloud"; then
    msg_info "正在停止 Service"
    systemctl stop teddycloud
    msg_ok "已停止 Service"

    msg_info "正在创建 backup"
    mv /opt/teddycloud /opt/teddycloud_bak
    msg_ok "Backup created"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "teddycloud" "toniebox-reverse-engineering/teddycloud" "prebuild" "latest" "/opt/teddycloud" "teddycloud.amd64.release*.zip"

    msg_info "正在恢复 data"
    cp -R /opt/teddycloud_bak/certs /opt/teddycloud_bak/config /opt/teddycloud_bak/data /opt/teddycloud
    rm -rf /opt/teddycloud_bak
    msg_ok "Data restored"

    msg_info "正在启动 Service"
    systemctl start teddycloud
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
