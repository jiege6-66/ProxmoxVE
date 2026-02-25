#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://caddyserver.com/

APP="Caddy"
var_tags="${var_tags:-webserver}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-6}"
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
  if [[ ! -d /etc/caddy ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  msg_info "正在更新 Caddy LXC"
  $STD apt update
  $STD apt upgrade -y
  msg_ok "Updated Caddy LXC"

  if command -v xcaddy >/dev/null 2>&1; then
    if check_for_gh_release "xcaddy" "caddyserver/xcaddy"; then
      setup_go
      fetch_and_deploy_gh_release "xcaddy" "caddyserver/xcaddy" "binary"

      msg_info "正在更新 xCaddy"
      $STD xcaddy build
      msg_ok "Updated xCaddy"
    fi
  fi
  msg_ok "已成功更新!"
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:80${CL}"
