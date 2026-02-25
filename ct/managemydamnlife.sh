#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/intri-in/manage-my-damn-life-nextjs

APP="Manage My Damn Life"
var_tags="${var_tags:-calendar;tasks}"
var_cpu="${var_cpu:-2}"
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

  if [[ ! -d /opt/mmdl ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  setup_mariadb
  if check_for_gh_release "mmdl" "intri-in/manage-my-damn-life-nextjs"; then
    msg_info "正在停止 service"
    systemctl stop mmdl
    msg_ok "已停止 service"

    msg_info "正在创建 Backup"
    cp /opt/mmdl/.env /opt/mmdl.env
    rm -rf /opt/mmdl
    msg_ok "Backup 已创建"

    fetch_and_deploy_gh_release "mmdl" "intri-in/manage-my-damn-life-nextjs" "tarball"
    NODE_VERSION="22" setup_nodejs

    msg_info "正在配置 ${APP}"
    cd /opt/mmdl
    export NEXT_TELEMETRY_DISABLED=1
    $STD npm install
    $STD npm run migrate
    $STD npm run build
    msg_ok "已配置 ${APP}"

    msg_info "正在启动 service"
    systemctl start mmdl
    msg_ok "已启动 service"
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
