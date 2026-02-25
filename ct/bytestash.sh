#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/jordan-dalby/ByteStash

APP="ByteStash"
var_tags="${var_tags:-code}"
var_disk="${var_disk:-4}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
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

  if [[ ! -d /opt/bytestash ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "bytestash" "jordan-dalby/ByteStash"; then
    read -rp "${TAB3}Did you make a backup via application WebUI? (y/n): " backuped
    if [[ "$backuped" =~ ^[Yy]$ ]]; then
      msg_info "正在停止 Services"
      systemctl stop bytestash-backend bytestash-frontend
      msg_ok "Services 已停止"

      CLEAN_INSTALL=1 fetch_and_deploy_gh_release "bytestash" "jordan-dalby/ByteStash" "tarball"

      msg_info "正在配置 ByteStash"
      cd /opt/bytestash/server
      $STD npm install
      cd /opt/bytestash/client
      $STD npm install
      msg_ok "Updated ByteStash"

      msg_info "正在启动 Services"
      systemctl start bytestash-backend bytestash-frontend
      msg_ok "已启动 Services"
    else
      msg_error "PLEASE MAKE A BACKUP FIRST!"
      exit
    fi
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
