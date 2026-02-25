#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: wendyliga
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/DonutWare/Fladder

APP="Fladder"
var_tags="${var_tags:-media}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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

  if [[ ! -d /opt/fladder ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "Fladder" "DonutWare/Fladder"; then
    msg_info "正在停止 Service"
    systemctl stop nginx
    msg_ok "已停止 Service"

    if [[ -f /opt/fladder/assets/config/config.json ]]; then
      msg_info "正在备份 configuration"
      cp /opt/fladder/assets/config/config.json /tmp/fladder_config.json.bak
      msg_ok "Configuration backed up"
    fi

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Fladder" "DonutWare/Fladder" "prebuild" "latest" "/opt/fladder" "Fladder-Web-*.zip"

    if [[ -f /tmp/fladder_config.json.bak ]]; then
      msg_info "正在恢复 configuration"
      mkdir -p /opt/fladder/assets/config
      cp /tmp/fladder_config.json.bak /opt/fladder/assets/config/config.json
      rm -f /tmp/fladder_config.json.bak
      msg_ok "Configuration restored"
    fi

    msg_info "正在启动 Service"
    systemctl start nginx
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
echo -e "${INFO}${YW} Access it using the following IP:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
