#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://nodebb.org/

APP="NodeBB"
var_tags="${var_tags:-forum}"
var_disk="${var_disk:-10}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-2048}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_unprivileged="${var_unprivileged:-1}"

# App Output & Base Settings
header_info "$APP"

# Core
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/nodebb ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "nodebb" "NodeBB/NodeBB"; then
    msg_info "正在停止 Service"
    systemctl stop nodebb
    msg_ok "已停止 Service"

    msg_info "正在更新 ${APP}"
    cd /opt/nodebb
    $STD ./nodebb upgrade
    echo "${CHECK_UPDATE_RELEASE}" >~/.nodebb
    msg_ok "Updated ${APP}"

    msg_info "正在启动 Service"
    systemctl start nodebb
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:4567${CL}"
