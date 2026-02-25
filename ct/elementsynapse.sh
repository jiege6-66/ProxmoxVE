#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: tremor021
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/element-hq/synapse

APP="Element Synapse"
var_tags="${var_tags:-server}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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
  if [[ ! -d /etc/matrix-synapse ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs

  msg_info "正在更新 LXC"
  $STD apt update
  $STD apt -y upgrade
  msg_ok "Updated LXC"

  if check_for_gh_release "synapse-admin" "etkecc/synapse-admin"; then
    msg_info "正在停止 Service"
    systemctl stop synapse-admin
    msg_ok "已停止 Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "synapse-admin" "etkecc/synapse-admin" "tarball" "latest" "/opt/synapse-admin"

    msg_info "正在构建 Synapse-Admin"
    cd /opt/synapse-admin
    $STD yarn global add serve
    $STD yarn install --ignore-engines
    $STD yarn build
    mv ./dist ../ && rm -rf * && mv ../dist ./
    msg_ok "已构建 Synapse-Admin"

    msg_info "正在启动 Service"
    systemctl start synapse-admin
    msg_ok "已启动 Service"
    msg_ok "Updated Synapse-Admin to ${CHECK_UPDATE_RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8008${CL}"
