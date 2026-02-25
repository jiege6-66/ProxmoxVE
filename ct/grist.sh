#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: cfurrow | Co-Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/gristlabs/grist-core

APP="Grist"
var_tags="${var_tags:-database;spreadsheet}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-3072}"
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

  if [[ ! -d /opt/grist ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  ensure_dependencies git

  if check_for_gh_release "grist" "gristlabs/grist-core"; then
    msg_info "正在停止 Service"
    systemctl stop grist
    msg_ok "已停止 Service"

    msg_info "正在创建 backup"
    rm -rf /opt/grist_bak
    mv /opt/grist /opt/grist_bak
    msg_ok "Backup created"

    fetch_and_deploy_gh_release "grist" "gristlabs/grist-core" "tarball"

    msg_info "正在更新 Grist"
    mkdir -p /opt/grist/docs
    cp -n /opt/grist_bak/.env /opt/grist/.env
    cp -r /opt/grist_bak/docs/* /opt/grist/docs/
    cp /opt/grist_bak/grist-sessions.db /opt/grist/grist-sessions.db
    cp /opt/grist_bak/landing.db /opt/grist/landing.db
    cd /opt/grist
    $STD yarn install
    $STD yarn run install:ee
    $STD yarn run build:prod
    $STD yarn run install:python
    msg_ok "Updated Grist"

    msg_info "正在启动 Service"
    systemctl start grist
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
echo -e "${TAB}${GATEWAY}${BGN}Grist: http://${IP}:8484${CL}"
