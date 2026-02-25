#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/cryptpad/cryptpad

APP="CryptPad"
var_tags="${var_tags:-docs;office}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
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

  if [[ ! -d "/opt/cryptpad" ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "cryptpad" "cryptpad/cryptpad"; then
    msg_info "正在停止 Service"
    systemctl stop cryptpad
    msg_info "已停止 Service"

    msg_info "正在备份 configuration"
    [ -f /opt/cryptpad/config/config.js ] && mv /opt/cryptpad/config/config.js /opt/
    msg_ok "已备份 configuration"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "cryptpad" "cryptpad/cryptpad" "tarball"

    msg_info "正在恢复 configuration"
    mv /opt/config.js /opt/cryptpad/config/
    msg_ok "Configuration restored"

    msg_info "正在更新 CryptaPad"
    cd /opt/cryptpad
    $STD npm ci
    $STD npm run install:components
    if [ -f "/opt/cryptpad/install-onlyoffice.sh" ]; then
      $STD bash /opt/cryptpad/install-onlyoffice.sh --accept-license
    fi
    $STD npm run build
    msg_ok "Updated CryptaPad"

    msg_info "正在启动 Service"
    systemctl start cryptpad
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
