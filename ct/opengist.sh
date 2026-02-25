#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Jonathan (jd-apprentice)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://opengist.io/

APP="Opengist"
var_tags="${var_tags:-development}"
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
  if [[ ! -d /opt/opengist ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "opengist" "thomiceli/opengist"; then
    msg_info "正在停止 Service"
    systemctl stop opengist
    msg_ok "已停止 Service"

    msg_info "正在创建 backup"
    mv /opt/opengist /opt/opengist-backup
    msg_ok "Backup created"

    fetch_and_deploy_gh_release "opengist" "thomiceli/opengist" "prebuild" "latest" "/opt/opengist" "opengist*linux-amd64.tar.gz"

    msg_info "正在恢复 Configuration"
    mv /opt/opengist-backup/config.yml /opt/opengist/config.yml
    msg_ok "Configuration 已恢复"

    msg_info "正在启动 Service"
    systemctl start opengist
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6157${CL}"
