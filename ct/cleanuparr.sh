#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Lucas Zampieri (zampierilucas) | MickLesk (CanbiZ)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Cleanuparr/Cleanuparr

APP="Cleanuparr"
var_tags="${var_tags:-arr}"
var_cpu="${var_cpu:-2}"
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
  if [[ ! -f /opt/cleanuparr/Cleanuparr ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "cleanuparr" "Cleanuparr/Cleanuparr"; then
    msg_info "正在停止 Service"
    systemctl stop cleanuparr
    msg_ok "已停止 Service"

    msg_info "正在备份 config"
    cp -r /opt/cleanuparr/config /opt/cleanuparr_config_backup
    msg_ok "已备份 config"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Cleanuparr" "Cleanuparr/Cleanuparr" "prebuild" "latest" "/opt/cleanuparr" "*linux-amd64.zip"

    msg_info "正在恢复 config"
    [[ -d /opt/cleanuparr/config ]] && rm -rf /opt/cleanuparr/config
    mv /opt/cleanuparr_config_backup /opt/cleanuparr/config
    msg_ok "已恢复 config"

    msg_info "正在启动 Service"
    systemctl start cleanuparr
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:11011${CL}"
