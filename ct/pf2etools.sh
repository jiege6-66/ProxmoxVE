#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: TheRealVira
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://pf2etools.com/

APP="Pf2eTools"
var_tags="${var_tags:-wiki}"
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

  if [[ ! -d "/opt/${APP}" ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "pf2etools" "Pf2eToolsOrg/Pf2eTools"; then
    msg_info "正在更新 System"
    $STD apt update
    $STD apt -y upgrade
    msg_ok "Updated System"

    rm -rf /opt/Pf2eTools
    fetch_and_deploy_gh_release "pf2etools" "Pf2eToolsOrg/Pf2eTools" "tarball" "latest" "/opt/Pf2eTools"

    msg_info "正在更新 ${APP}"
    cd /opt/Pf2eTools
    $STD npm install
    $STD npm run build
    chown -R www-data: "/opt/${APP}"
    chmod -R 755 "/opt/${APP}"
    msg_ok "Updated ${APP}"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
