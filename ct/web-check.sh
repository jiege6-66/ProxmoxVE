#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Lissy93/web-check

APP="web-check"
var_tags="${var_tags:-network;analysis}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-12}"
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
  if [[ ! -d /opt/web-check ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "web-check" "CrazyWolf13/web-check"; then
    msg_info "正在停止 Service"
    systemctl stop web-check
    msg_ok "已停止 Service"

    msg_info "正在创建 backup"
    mv /opt/web-check/.env /opt
    msg_ok "已创建 backup"

    NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "web-check" "CrazyWolf13/web-check" "tarball"

    msg_info "正在恢复 backup"
    mv /opt/.env /opt/web-check
    msg_ok "已恢复 backup"

    msg_info "正在构建 Web-Check"
    cd /opt/web-check 
    $STD yarn install --frozen-lockfile --network-timeout 100000
    $STD yarn build --production
    $STD npm cache clean --force
    msg_ok "已构建 Web-Check"

    msg_info "正在启动 Service"
    systemctl start web-check
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
