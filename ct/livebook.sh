#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: dkuku
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/livebook-dev/livebook

APP="Livebook"
var_tags="${var_tags:-development}"
var_disk="${var_disk:-4}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /opt/livebook/.mix/escripts/livebook ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "livebook" "livebook-dev/livebook"; then
    msg_info "正在停止 Service"
    systemctl stop livebook
    msg_info "已停止 Service"

    msg_info "正在更新 Container"
    $STD apt update
    $STD apt upgrade -y
    msg_ok "Updated Container"

    msg_info "正在更新 Livebook"
    source /opt/livebook/.env
    cd /opt/livebook
    $STD mix escript.install hex livebook --force

    chown -R livebook:livebook /opt/livebook /data

    msg_info "正在启动 Service"
    systemctl start livebook
    msg_info "已启动 Service"

    msg_ok "已成功更新!"
  fi
  exit
}

start
build_container
description

echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
