#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: HydroshieldMKII
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/HydroshieldMKII/Guardian

APP="Guardian"
var_tags="${var_tags:-media;monitoring}"
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

  if [[ ! -d "/opt/guardian" ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "guardian" "HydroshieldMKII/Guardian"; then
    msg_info "正在停止 Services"
    systemctl stop guardian-backend guardian-frontend
    msg_ok "已停止 Services"

    if [[ -f "/opt/guardian/backend/plex-guard.db" ]]; then
      msg_info "正在备份 Database"
      cp "/opt/guardian/backend/plex-guard.db" "/tmp/plex-guard.db.backup"
      msg_ok "已备份 Database"
    fi

    [[ -f "/opt/guardian/.env" ]] && cp "/opt/guardian/.env" "/opt"
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "guardian" "HydroshieldMKII/Guardian" "tarball" "latest" "/opt/guardian"
    [[ -f "/opt/.env" ]] && mv "/opt/.env" "/opt/guardian"

    if [[ -f "/tmp/plex-guard.db.backup" ]]; then
      msg_info "正在恢复 Database"
      cp "/tmp/plex-guard.db.backup" "/opt/guardian/backend/plex-guard.db"
      rm "/tmp/plex-guard.db.backup"
      msg_ok "已恢复 Database"
    fi

    msg_info "正在更新 Guardian"
    cd /opt/guardian/backend
    $STD npm ci
    $STD npm run build

    cd /opt/guardian/frontend
    $STD npm ci
    export DEPLOYMENT_MODE=standalone
    $STD npm run build
    msg_ok "Updated Guardian"

    msg_info "正在启动 Services"
    systemctl start guardian-backend guardian-frontend
    msg_ok "已启动 Services"
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
