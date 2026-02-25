#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Omar Minaya | MickLesk (CanbiZ)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/C4illin/ConvertX

APP="ConvertX"
var_tags="${var_tags:-converter}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
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
  if [[ ! -d /var ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "ConvertX" "C4illin/ConvertX"; then
    msg_info "正在停止 Service"
    systemctl stop convertx
    msg_info "已停止 Service"

    msg_info "Move data-Folder"
    if [[ -d /opt/convertx/data ]]; then
      mv /opt/convertx/data /opt/data
    fi
    msg_ok "Moved data-Folder"

    fetch_and_deploy_gh_release "ConvertX" "C4illin/ConvertX" "tarball" "latest" "/opt/convertx"

    msg_info "正在更新 ConvertX"
    if [[ -d /opt/data ]]; then
      mv /opt/data /opt/convertx/data
    fi
    cd /opt/convertx 
    $STD bun install
    msg_ok "Updated ConvertX"

    msg_info "正在启动 Service"
    systemctl start convertx
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
