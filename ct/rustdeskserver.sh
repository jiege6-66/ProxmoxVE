#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rustdesk/rustdesk-server

APP="RustDesk Server"
var_tags="${var_tags:-remote-desktop}"
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

  if [[ ! -x /usr/bin/hbbr ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/rustdesk/rustdesk-server/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
  APIRELEASE=$(curl -fsSL https://api.github.com/repos/lejianwen/rustdesk-api/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ "${RELEASE}" != "$(cat ~/.rustdesk-hbbr)" ]] || [[ "${APIRELEASE}" != "$(cat ~/.rustdesk-api)" ]] || [[ ! -f ~/.rustdesk-hbbr ]] || [[ ! -f ~/.rustdesk-api ]]; then
    msg_info "正在停止 Service"
    systemctl stop rustdesk-hbbr
    systemctl stop rustdesk-hbbs
    if [[ -f /lib/systemd/system/rustdesk-api.service ]]; then
      systemctl stop rustdesk-api
    fi
    msg_info "已停止 Service"

    fetch_and_deploy_gh_release "rustdesk-hbbr" "rustdesk/rustdesk-server" "binary" "latest" "/opt/rustdesk" "rustdesk-server-hbbr*amd64.deb"
    fetch_and_deploy_gh_release "rustdesk-hbbs" "rustdesk/rustdesk-server" "binary" "latest" "/opt/rustdesk" "rustdesk-server-hbbs*amd64.deb"
    fetch_and_deploy_gh_release "rustdesk-utils" "rustdesk/rustdesk-server" "binary" "latest" "/opt/rustdesk" "rustdesk-server-utils*amd64.deb"
    fetch_and_deploy_gh_release "rustdesk-api" "lejianwen/rustdesk-api" "binary" "latest" "/opt/rustdesk" "rustdesk-api-server*amd64.deb"

    msg_info "正在启动 services"
    systemctl start -q rustdesk-* --all
    msg_ok "Services started"

    msg_ok "已成功更新!"
  else
    msg_ok "无需更新。 ${APP} is already at v${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}${IP}:21114${CL}"
