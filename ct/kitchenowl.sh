#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: snazzybean
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/TomBursch/kitchenowl

APP="KitchenOwl"
var_tags="${var_tags:-food;recipes}"
var_cpu="${var_cpu:-1}"
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

  if [[ ! -d /opt/kitchenowl ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "kitchenowl" "TomBursch/kitchenowl"; then
    msg_info "正在停止 Service"
    systemctl stop kitchenowl
    msg_ok "已停止 Service"

    msg_info "正在创建 Backup"
    mkdir -p /opt/kitchenowl_backup
    cp -r /opt/kitchenowl/data /opt/kitchenowl_backup/
    cp -f /opt/kitchenowl/kitchenowl.env /opt/kitchenowl_backup/
    msg_ok "已创建 Backup"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "kitchenowl" "TomBursch/kitchenowl" "tarball" "latest" "/opt/kitchenowl"
    rm -rf /opt/kitchenowl/web
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "kitchenowl-web" "TomBursch/kitchenowl" "prebuild" "latest" "/opt/kitchenowl/web" "kitchenowl_Web.tar.gz"

    msg_info "正在恢复 data"
    sed -i 's/default=True/default=False/' /opt/kitchenowl/backend/wsgi.py
    cp -r /opt/kitchenowl_backup/data /opt/kitchenowl/
    cp -f /opt/kitchenowl_backup/kitchenowl.env /opt/kitchenowl/
    rm -rf /opt/kitchenowl_backup
    msg_ok "已恢复 data"

    msg_info "正在更新 KitchenOwl"
    cd /opt/kitchenowl/backend
    $STD uv sync --frozen
    cd /opt/kitchenowl/backend
    set -a
    source /opt/kitchenowl/kitchenowl.env
    set +a
    $STD uv run flask db upgrade
    msg_ok "Updated KitchenOwl"

    msg_info "正在启动 Service"
    systemctl start kitchenowl
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:80${CL}"
