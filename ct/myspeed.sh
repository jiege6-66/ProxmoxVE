#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster) | Co-Author: MickLesk (Canbiz)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://myspeed.dev/

APP="MySpeed"
var_tags="${var_tags:-tracking}"
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
  if [[ ! -d /opt/myspeed ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "myspeed" "gnmyt/myspeed"; then
    msg_info "正在停止 Service"
    systemctl stop myspeed
    msg_ok "已停止 Service"

    msg_info "正在创建 backup"
    cd /opt
    rm -rf myspeed_bak
    mv myspeed myspeed_bak
    msg_ok "Backup created"

    fetch_and_deploy_gh_release "myspeed" "gnmyt/myspeed" "prebuild" "latest" "/opt/myspeed" "MySpeed-*.zip"

    msg_info "正在更新 ${APP}"
    cd /opt/myspeed
    $STD npm install
    if [[ -d /opt/myspeed_bak/data ]]; then
      mkdir -p /opt/myspeed/data/
      cp -r /opt/myspeed_bak/data/* /opt/myspeed/data/
    fi
    msg_ok "Updated ${APP}"

    msg_info "正在启动 Service"
    systemctl start myspeed
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5216${CL}"
