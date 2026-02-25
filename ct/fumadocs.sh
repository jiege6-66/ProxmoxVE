#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/fuma-nama/fumadoc

APP="Fumadocs"
var_tags="${var_tags:-documentation}"
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

  if [[ ! -d /opt/fumadocs ]]; then
    msg_error "No installation found in /opt/fumadocs!"
    exit
  fi

  if [[ ! -f /opt/fumadocs/.projectname ]]; then
    msg_error "Project name file 未找到: /opt/fumadocs/.projectname!"
    exit
  fi

  NODE_VERSION="22" NODE_MODULE="pnpm@latest" setup_nodejs
  PROJECT_NAME=$(</opt/fumadocs/.projectname)
  PROJECT_DIR="/opt/fumadocs/${PROJECT_NAME}"
  SERVICE_NAME="fumadocs_${PROJECT_NAME}.service"

  if [[ ! -d "$PROJECT_DIR" ]]; then
    msg_error "Project directory does not exist: $PROJECT_DIR"
    exit
  fi
  ensure_dependencies git

  msg_info "正在停止 service $SERVICE_NAME"
  systemctl stop "$SERVICE_NAME"
  msg_ok "已停止 service $SERVICE_NAME"

  msg_info "正在更新 dependencies using pnpm"
  cd "$PROJECT_DIR"
  $STD pnpm up --latest
  $STD pnpm build
  msg_ok "Updated dependencies using pnpm"

  msg_info "正在启动 service $SERVICE_NAME"
  systemctl start "$SERVICE_NAME"
  msg_ok "已启动 service $SERVICE_NAME"
  msg_ok "已成功更新!"
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
