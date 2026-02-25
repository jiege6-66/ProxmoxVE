#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://zwave-js.github.io/zwave-js-ui/#/

APP="Zwave-JS-UI"
var_tags="${var_tags:-smarthome;zwave}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-0}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/zwave-js-ui ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "zwave-js-ui" "zwave-js/zwave-js-ui"; then
    msg_info "正在停止 Service"
    systemctl stop zwave-js-ui
    msg_ok "已停止 Service"

    rm -rf /opt/zwave-js-ui/*
    fetch_and_deploy_gh_release "zwave-js-ui" "zwave-js/zwave-js-ui" "prebuild" "latest" "/opt/zwave-js-ui" "zwave-js-ui*-linux.zip"

    msg_info "正在启动 Service"
    systemctl start zwave-js-ui
    msg_ok "已启动 Service"

    msg_info "Cleanup"
    rm -rf /opt/zwave-js-ui/store
    msg_ok "已清理"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8091${CL}"
