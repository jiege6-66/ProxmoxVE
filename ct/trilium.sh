#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/TriliumNext/Trilium

APP="Trilium"
var_tags="${var_tags:-notes}"
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
  if [[ ! -d /opt/trilium ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "Trilium" "TriliumNext/Trilium"; then
    if [[ -d /opt/trilium/db ]]; then
      DB_PATH="/opt/trilium/db"
      DB_RESTORE_PATH="/opt/trilium/db"
    elif [[ -d /opt/trilium/assets/db ]]; then
      DB_PATH="/opt/trilium/assets/db"
      DB_RESTORE_PATH="/opt/trilium/assets/db"
    else
      msg_error "Database 未找到 in either /opt/trilium/db or /opt/trilium/assets/db"
      exit
    fi

    msg_info "正在停止 Service"
    systemctl stop trilium
    sleep 1
    msg_ok "已停止 Service"

    msg_info "正在备份 Database"
    mkdir -p /opt/trilium_backup
    cp -r "${DB_PATH}" /opt/trilium_backup/
    rm -rf /opt/trilium
    msg_ok "已备份 Database"

    fetch_and_deploy_gh_release "Trilium" "TriliumNext/Trilium" "prebuild" "latest" "/opt/trilium" "TriliumNotes-Server-*linux-x64.tar.xz"

    msg_info "正在恢复 Database"
    mkdir -p "$(dirname "${DB_RESTORE_PATH}")"
    cp -r /opt/trilium_backup/$(basename "${DB_PATH}") "${DB_RESTORE_PATH}"
    rm -rf /opt/trilium_backup
    msg_ok "已恢复 Database"

    msg_info "正在启动 Service"
    systemctl start trilium
    sleep 1
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
