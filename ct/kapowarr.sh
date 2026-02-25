#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Casvt/Kapowarr

APP="Kapowarr"
var_tags="${var_tags:-Arr}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
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

  if [[ ! -f /etc/systemd/system/kapowarr.service ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  setup_uv

  if check_for_gh_release "kapowarr" "Casvt/Kapowarr"; then
    msg_info "正在停止 Service"
    systemctl stop kapowarr
    msg_ok "已停止 Service"

    msg_info "正在创建 Backup"
    mv /opt/kapowarr/db /opt/
    msg_ok "Backup 已创建"

    fetch_and_deploy_gh_release "kapowarr" "Casvt/Kapowarr" "tarball"

    msg_info "正在更新 Kapowarr"
    mv /opt/db /opt/kapowarr
    msg_ok "Updated Kapowarr"

    msg_info "正在启动 Service"
    systemctl start kapowarr
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5656${CL}"
