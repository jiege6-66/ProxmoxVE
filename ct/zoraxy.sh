#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://zoraxy.aroz.org/

APP="Zoraxy"
var_tags="${var_tags:-network}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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
  if [[ ! -d /opt/zoraxy/ ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "zoraxy" "tobychui/zoraxy"; then
    msg_info "正在停止服务"
    systemctl stop zoraxy
    msg_ok "服务已停止"

    rm -rf /opt/zoraxy/zoraxy
    fetch_and_deploy_gh_release "zoraxy" "tobychui/zoraxy" "singlefile" "latest" "/opt/zoraxy" "zoraxy_linux_amd64"

    msg_info "正在启动服务"
    systemctl start zoraxy
    msg_ok "服务已启动"
    msg_ok "更新成功！"
  fi
  exit
}

start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
