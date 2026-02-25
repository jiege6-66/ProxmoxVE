#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://www.traccar.org/

APP="Traccar"
var_tags="${var_tags:-gps;tracker}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
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
  if [[ ! -d /opt/traccar ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "traccar" "traccar/traccar"; then
    msg_info "正在停止 Service"
    systemctl stop traccar
    msg_ok "已停止 Service"

    msg_info "正在创建 backup"
    mv /opt/traccar/conf/traccar.xml /opt
    [[ -d /opt/traccar/data ]] && mv /opt/traccar/data /opt
    [[ -d /opt/traccar/media ]] && mv /opt/traccar/media /opt
    msg_ok "Backup created"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "traccar" "traccar/traccar" "prebuild" "latest" "/opt/traccar" "traccar-linux-64*.zip"

    msg_info "Perform Update"
    cd /opt/traccar
    $STD ./traccar.run
    msg_ok "App-更新完成"

    msg_info "正在恢复 data"
    mv /opt/traccar.xml /opt/traccar/conf
    [[ -d /opt/data ]] && mv /opt/data /opt/traccar
    [[ -d /opt/media ]] && mv /opt/media /opt/traccar
    [ -f README.txt ] || [ -f traccar.run ] && rm -f README.txt traccar.run
    msg_ok "Data restored"

    msg_info "正在启动 Service"
    systemctl start traccar
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8082${CL}"
