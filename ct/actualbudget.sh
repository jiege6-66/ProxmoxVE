#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://actualbudget.org/

APP="Actual Budget"
var_tags="${var_tags:-finance}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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

  if [[ ! -f ~/.actualbudget && ! -f /opt/actualbudget_version.txt ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  NODE_VERSION="22" setup_nodejs
  RELEASE=$(get_latest_github_release "actualbudget/actual")
  if [[ -f /opt/actualbudget-data/config.json ]]; then
    if check_for_gh_release "actualbudget" "actualbudget/actual"; then
      msg_info "正在停止 Service"
      systemctl stop actualbudget
      msg_ok "已停止 Service"

      msg_info "正在更新 Actual Budget to ${RELEASE}"
      $STD npm update -g @actual-app/sync-server
      echo "${RELEASE}" >~/.actualbudget
      msg_ok "Updated Actual Budget to ${RELEASE}"

      msg_info "正在启动 Service"
      systemctl start actualbudget
      msg_ok "已启动 Service"
      msg_ok "已成功更新!"
    fi
  else
    msg_info "Old Installation Found, you need to migrate your data and recreate to a new container"
    msg_info "Please follow the instructions on the Actual Budget website to migrate your data"
    msg_info "https://actualbudget.org/docs/backup-restore/backup"
    exit
  fi
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:5006${CL}"
