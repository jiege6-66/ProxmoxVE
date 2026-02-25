#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://plant-it.org/

APP="Plant-it"
var_tags="${var_tags:-plants;garden}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-5}"
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
  if [[ ! -d /opt/plant-it ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  setup_mariadb
  if check_for_gh_release "plant-it" "MDeLuise/plant-it"; then
    msg_info "正在停止 Service"
    systemctl stop plant-it
    msg_info "已停止 Service"

    USE_ORIGINAL_FILENAME="true" fetch_and_deploy_gh_release "plant-it" "MDeLuise/plant-it" "singlefile" "0.10.0" "/opt/plant-it/backend" "server.jar"
    fetch_and_deploy_gh_release "plant-it-front" "MDeLuise/plant-it" "prebuild" "0.10.0" "/opt/plant-it/frontend" "client.tar.gz"
    msg_warn "Application is updated to latest Web version (v0.10.0). There will be no more updates available."
    msg_warn "Please read: https://github.com/MDeLuise/plant-it/releases/tag/1.0.0"

    msg_info "正在启动 Service"
    systemctl start plant-it
    msg_ok "已启动 Service"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
