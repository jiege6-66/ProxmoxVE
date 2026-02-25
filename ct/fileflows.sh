#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: kkroboth
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://fileflows.com/

APP="FileFlows"
var_tags="${var_tags:-media;automation}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_gpu="${var_gpu:-yes}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/fileflows ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  
  update_available=$(curl -fsSL -X 'GET' "http://localhost:19200/api/status/update-available" -H 'accept: application/json' | jq .UpdateAvailable)
  if [[ "${update_available}" == "true" ]]; then
    msg_info "正在停止 Service"
    systemctl stop fileflows
    msg_info "已停止 Service"

    msg_info "正在创建 Backup"
    ls /opt/*.tar.gz &>/dev/null && rm -f /opt/*.tar.gz
    backup_filename="/opt/${APP}_backup_$(date +%F).tar.gz"
    tar -czf "$backup_filename" -C /opt/fileflows Data
    msg_ok "Backup 已创建"

    fetch_and_deploy_from_url "https://fileflows.com/downloads/zip" "/opt/fileflows"

    msg_info "正在启动 Service"
    systemctl start fileflows
    msg_ok "已启动 Service"
    msg_ok "已成功更新!"
  else
    msg_ok "无需更新。 ${APP} is already at latest version"
  fi

  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:19200${CL}"
