#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/orhun/rustypaste

APP="Alpine-RustyPaste"
var_tags="${var_tags:-alpine;pastebin;storage}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
var_disk="${var_disk:-4}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.23}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if ! apk info -e rustypaste >/dev/null 2>&1; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  msg_info "正在更新 RustyPaste"
  $STD apk update
  $STD apk upgrade rustypaste --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community
  msg_ok "Updated RustyPaste"

  msg_info "正在重启 Services"
  $STD rc-service rustypaste restart
  msg_ok "已重启 Services"
  msg_ok "已成功更新!"
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
