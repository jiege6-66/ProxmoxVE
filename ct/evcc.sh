#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://evcc.io/en/

APP="evcc"
var_tags="${var_tags:-solar;ev;automation}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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
  if ! command -v evcc >/dev/null 2>&1; then
    msg_error "未找到 ${APP} 安装！"
    exit 1
  fi

  if [[ -f /etc/apt/sources.list.d/evcc-stable.list ]]; then
    setup_deb822_repo \
      "evcc-stable" \
      "https://dl.evcc.io/public/evcc/stable/gpg.EAD5D0E07B0EC0FD.key" \
      "https://dl.evcc.io/public/evcc/stable/deb/debian/" \
      "$(get_os_info codename)" \
      "main"
  fi
  msg_info "正在更新 evcc LXC"
  $STD apt update
  $STD apt --only-upgrade install -y evcc
  msg_ok "已成功更新!"
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7070${CL}"
