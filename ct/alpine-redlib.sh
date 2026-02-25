#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: andrej-kocijan (Andrej Kocijan)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/redlib-org/redlib

APP="Alpine-Redlib"
var_tags="${var_tags:-alpine;frontend}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-1}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.23}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_resources

  if [[ ! -d /opt/redlib ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  msg_info "正在更新 Alpine Packages"
  $STD apk -U upgrade
  msg_ok "Updated Alpine Packages"

  msg_info "正在停止 Service"
  $STD rc-service redlib stop
  msg_ok "已停止 Service"

  fetch_and_deploy_gh_release "redlib" "redlib-org/redlib" "prebuild" "latest" "/opt/redlib" "redlib-x86_64-unknown-linux-musl.tar.gz"

  msg_info "正在启动 Service"
  $STD rc-service redlib start
  msg_ok "已启动 Service"
  msg_ok "已成功更新!"
  exit 0
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5252${CL}"
