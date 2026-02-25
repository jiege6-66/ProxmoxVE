#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/rogerfar/rdt-client

APP="RDTClient"
var_tags="${var_tags:-torrent}"
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
  if [[ ! -d /opt/rdtc/ ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "rdt-client" "rogerfar/rdt-client"; then
    msg_info "正在停止 Service"
    systemctl stop rdtc
    msg_ok "已停止 Service"

    msg_info "正在创建 backup"
    mkdir -p /opt/rdtc-backup
    cp -R /opt/rdtc/appsettings.json /opt/rdtc-backup/
    msg_ok "Backup created"

    fetch_and_deploy_gh_release "rdt-client" "rogerfar/rdt-client" "prebuild" "latest" "/opt/rdtc" "RealDebridClient.zip"
    cp -R /opt/rdtc-backup/appsettings.json /opt/rdtc/
    if dpkg-query -W dotnet-sdk-8.0 >/dev/null 2>&1; then
      $STD apt remove --purge -y dotnet-sdk-8.0
      ensure_dependencies aspnetcore-runtime-9.0
    fi
    rm -rf /opt/rdtc-backup

    msg_info "正在启动 Service"
    systemctl start rdtc
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6500${CL}"
