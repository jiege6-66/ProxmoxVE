#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://mafl.hywax.space/

APP="Mafl"
var_tags="${var_tags:-dashboard}"
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
  if [[ ! -d /opt/mafl ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "mafl" "hywax/mafl"; then
    msg_info "正在停止 Mafl service"
    systemctl stop mafl
    msg_ok "Service stopped"

    msg_info "正在备份 data"
    mkdir -p /opt/mafl-backup/data
    mv /opt/mafl/data /opt/mafl-backup/data
    rm -rf /opt/mafl
    msg_ok "Backup complete"

    fetch_and_deploy_gh_release "mafl" "hywax/mafl" "tarball"

    msg_info "正在更新 Mafl"
    cd /opt/mafl
    $STD yarn install
    $STD yarn build
    mv /opt/mafl-backup/data /opt/mafl/data
    msg_ok "Mafl updated"

    msg_info "正在启动 Service"
    systemctl start mafl
    msg_ok "Service started"
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
