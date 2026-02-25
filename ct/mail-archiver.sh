#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/s1t5/mail-archiver

APP="Mail-Archiver"
var_tags="${var_tags:-mail-archiver}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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
  if [[ ! -d /opt/mail-archiver ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "mail-archiver" "s1t5/mail-archiver"; then
    msg_info "正在停止 Mail-Archiver"
    systemctl stop mail-archiver
    msg_ok "已停止 Mail-Archiver"

    msg_info "正在创建 Backup"
    cp /opt/mail-archiver/appsettings.json /opt/mail-archiver/.env /opt/
    [[ -d /opt/mail-archiver/DataProtection-Keys ]] && cp -r /opt/mail-archiver/DataProtection-Keys /opt
    msg_ok "已创建 Backup"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "mail-archiver" "s1t5/mail-archiver" "tarball"

    msg_info "正在更新 Mail-Archiver"
    mv /opt/mail-archiver /opt/mail-archiver-build
    cd /opt/mail-archiver-build
    $STD dotnet restore
    $STD dotnet publish -c Release -o /opt/mail-archiver
    rm -rf /opt/mail-archiver-build
    msg_ok "Updated Mail-Archiver"

    msg_info "正在恢复 Backup"
    cp /opt/appsettings.json /opt/.env /opt/mail-archiver
    [[ -d /opt/DataProtection-Keys ]] && cp -r /opt/DataProtection-Keys /opt/mail-archiver/
    msg_ok "已恢复 Backup"

    msg_info "正在启动 Mail-Archiver"
    systemctl start mail-archiver
    msg_ok "已启动 Mail-Archiver"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5000${CL}"
