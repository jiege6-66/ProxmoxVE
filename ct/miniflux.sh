#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: omernaveedxyz
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://miniflux.app/

APP="Miniflux"
var_tags="${var_tags:-media}"
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
  if ! systemctl -q is-enabled miniflux 2>/dev/null; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  msg_info "正在停止 Service"
  $STD miniflux -flush-sessions -config-file /etc/miniflux.conf
  systemctl stop miniflux
  msg_ok "Service 已停止"

  fetch_and_deploy_gh_release "miniflux" "miniflux/v2" "binary" "latest"

  msg_info "正在更新 Miniflux"
  $STD miniflux -migrate -config-file /etc/miniflux.conf
  msg_ok "Updated Miniflux"
  msg_info "正在启动 Service"
  $STD systemctl start miniflux
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
