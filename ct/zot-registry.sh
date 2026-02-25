#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://zotregistry.dev/

APP="Zot-Registry"
var_tags="${var_tags:-registry;oci}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-4096}"
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
  if [[ ! -f /usr/bin/zot ]]; then
    msg_error "No ${APP} installation found!"
    exit
  fi

  if check_for_gh_release "zot" "project-zot/zot"; then
    msg_info "正在停止 Zot service"
    systemctl stop zot
    msg_ok "已停止 Zot service"

    rm -f /usr/bin/zot
    fetch_and_deploy_gh_release "zot" "project-zot/zot" "singlefile" "latest" "/usr/bin" "zot-linux-amd64"

    msg_info "正在配置 Zot Registry"
    chown root:root /usr/bin/zot
    msg_ok "已配置 Zot Registry"

    msg_info "正在启动 service"
    systemctl start zot
    msg_ok "Service started"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
