#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://ntfy.sh/

APP="ntfy"
var_tags="${var_tags:-notification}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
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
  if [[ ! -d /etc/ntfy ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if [ -f /etc/apt/keyrings/archive.heckel.io.gpg ]; then
    msg_info "Correcting old Ntfy Repository"
    rm -f /etc/apt/keyrings/archive.heckel.io.gpg
    rm -f /etc/apt/sources.list.d/archive.heckel.io.list
    rm -f /etc/apt/sources.list.d/archive.heckel.io.list.bak
    rm -f /etc/apt/sources.list.d/archive.heckel.io.sources
    setup_deb822_repo \
      "ntfy" \
      "https://archive.ntfy.sh/apt/keyring.gpg" \
      "https://archive.ntfy.sh/apt/" \
      "stable"
    msg_ok "Corrected old Ntfy Repository"
  fi

  msg_info "正在更新 ntfy"
  $STD apt update
  $STD apt upgrade -y
  msg_ok "Updated ntfy"
  msg_ok "已成功更新!"
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
