#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://listmonk.app/

APP="listmonk"
var_tags="${var_tags:-newsletter}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
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
  if [[ ! -f /etc/systemd/system/listmonk.service ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "listmonk" "knadh/listmonk"; then
    msg_info "正在停止 Service"
    systemctl stop listmonk
    msg_ok "已停止 Service"

    msg_info "正在备份 data"
    mv /opt/listmonk/ /opt/listmonk-backup
    msg_ok "已备份 data"

    fetch_and_deploy_gh_release "listmonk" "knadh/listmonk" "prebuild" "latest" "/opt/listmonk" "listmonk*linux_amd64.tar.gz"

    msg_info "正在配置 listmonk"
    mv /opt/listmonk-backup/config.toml /opt/listmonk/config.toml
    mv /opt/listmonk-backup/uploads /opt/listmonk/uploads
    $STD /opt/listmonk/listmonk --upgrade --yes --config /opt/listmonk/config.toml
    rm -rf /opt/listmonk-backup/
    msg_ok "已配置 listmonk"

    msg_info "正在启动 Service"
    systemctl start listmonk
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9000${CL}"
