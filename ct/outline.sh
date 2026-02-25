#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/outline/outline

APP="Outline"
var_tags="${var_tags:-documentation}"
var_disk="${var_disk:-8}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
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
  if [[ ! -d /opt/outline ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  NODE_VERSION="22" setup_nodejs

  if check_for_gh_release "outline" "outline/outline"; then
    msg_info "正在停止 Services"
    systemctl stop outline
    msg_ok "Services 已停止"

    msg_info "正在创建 backup"
    cp /opt/outline/.env /opt
    msg_ok "Backup created"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "outline" "outline/outline" "tarball"

    msg_info "正在更新 Outline"
    cd /opt/outline
    mv /opt/.env /opt/outline
    export NODE_ENV=development
    export NODE_OPTIONS="--max-old-space-size=3584"
    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
    $STD corepack enable
    $STD yarn install --immutable
    export NODE_ENV=production
    $STD yarn build
    msg_ok "Updated Outline"

    msg_info "正在启动 Services"
    systemctl start outline
    msg_ok "已启动 Services"
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
