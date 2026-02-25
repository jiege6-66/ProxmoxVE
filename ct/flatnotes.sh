#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: luismco
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/dullage/flatnotes

APP="Flatnotes"
var_tags="${var_tags:-notes}"
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
  if [[ ! -d /opt/flatnotes ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "flatnotes" "dullage/flatnotes"; then
    msg_info "正在停止 Service"
    systemctl stop flatnotes
    msg_ok "已停止 Service"

    msg_info "正在备份 Configuration and Data"
    cp /opt/flatnotes/.env /opt/flatnotes.env
    cp -r /opt/flatnotes/data /opt/flatnotes_data_backup
    msg_ok "已备份 Configuration and Data"

    fetch_and_deploy_gh_release "flatnotes" "dullage/flatnotes"

    msg_info "正在更新 Flatnotes"
    cd /opt/flatnotes/client
    $STD npm install
    $STD npm run build
    cd /opt/flatnotes
    rm -f uv.lock
    $STD /usr/local/bin/uvx migrate-to-uv
    $STD /usr/local/bin/uv sync
    msg_ok "Updated Flatnotes"

    msg_info "正在恢复 Configuration and Data"
    cp /opt/flatnotes.env /opt/flatnotes/.env
    cp -r /opt/flatnotes_data_backup/. /opt/flatnotes/data
    rm -f /opt/flatnotes.env
    rm -r /opt/flatnotes_data_backup
    msg_ok "已恢复 Configuration and Data"

    msg_info "正在启动 Service"
    systemctl start flatnotes
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"

