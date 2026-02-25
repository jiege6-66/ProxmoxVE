#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://uptime.kuma.pet/

APP="Uptime Kuma"
var_tags="${var_tags:-analytics;monitoring}"
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
  if [[ ! -d /opt/uptime-kuma ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  NODE_VERSION="22" setup_nodejs

  ensure_dependencies chromium
  if [[ ! -L /opt/uptime-kuma/chromium ]]; then
    ln -s /usr/bin/chromium /opt/uptime-kuma/chromium
  fi

  if check_for_gh_release "uptime-kuma" "louislam/uptime-kuma"; then
    msg_info "正在停止 Service"
    systemctl stop uptime-kuma
    msg_ok "已停止 Service"

    fetch_and_deploy_gh_release "uptime-kuma" "louislam/uptime-kuma" "tarball"

    msg_info "正在更新 Uptime Kuma"
    cd /opt/uptime-kuma
    $STD npm install --omit dev
    $STD npm run download-dist
    msg_ok "Updated Uptime Kuma"

    msg_info "正在启动 Service"
    systemctl start uptime-kuma
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3001${CL}"
