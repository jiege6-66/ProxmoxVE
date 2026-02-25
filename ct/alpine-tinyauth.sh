#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021) | Co-Author: Stavros (steveiliop56)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/steveiliop56/tinyauth

APP="Alpine-Tinyauth"
var_tags="${var_tags:-alpine;auth}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-256}"
var_disk="${var_disk:-2}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.23}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  if [[ ! -d /opt/tinyauth ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  msg_info "正在更新 packages"
  $STD apk -U upgrade
  msg_ok "Updated packages"

  RELEASE=$(curl -s https://api.github.com/repos/steveiliop56/tinyauth/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [ "${RELEASE}" != "$(cat ~/.tinyauth 2>/dev/null)" ] || [ ! -f ~/.tinyauth ]; then
    msg_info "正在停止 Service"
    $STD service tinyauth stop
    msg_ok "Service 已停止"

    msg_info "正在更新 Tinyauth"
    rm -f /opt/tinyauth/tinyauth
    curl -fsSL "https://github.com/steveiliop56/tinyauth/releases/download/v${RELEASE}/tinyauth-amd64" -o /opt/tinyauth/tinyauth
    chmod +x /opt/tinyauth/tinyauth
    echo "${RELEASE}" >~/.tinyauth
    msg_ok "Updated Tinyauth"

    msg_info "正在重启 Tinyauth"
    $STD service tinyauth start
    msg_ok "已重启 Tinyauth"
    msg_ok "已成功更新!"
  else
    msg_ok "无需更新。 ${APP} is already at ${RELEASE}"
  fi
  exit 0
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
