#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/danielbrendel/hortusfox-web

APP="HortusFox"
var_tags="${var_tags:-plants}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-5}"
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
  if [[ ! -d /opt/hortusfox ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  setup_mariadb
  if check_for_gh_release "hortusfox" "danielbrendel/hortusfox-web"; then
    msg_info "正在停止 Service"
    systemctl stop apache2
    msg_ok "已停止 Service"

    msg_info "正在备份 current HortusFox installation"
    cd /opt
    mv /opt/hortusfox/ /opt/hortusfox-backup
    msg_ok "已备份 current HortusFox installation"

    fetch_and_deploy_gh_release "hortusfox" "danielbrendel/hortusfox-web" "tarball"

    msg_info "正在更新 HortusFox"
    cd /opt/hortusfox
    mv /opt/hortusfox-backup/.env /opt/hortusfox/.env
    $STD composer install --no-dev --optimize-autoloader
    $STD php asatru migrate --no-interaction
    $STD php asatru plants:attributes
    $STD php asatru calendar:classes
    chown -R www-data:www-data /opt/hortusfox
    rm -r /opt/hortusfox-backup
    msg_ok "Updated HortusFox"

    msg_info "正在启动 Service"
    systemctl start apache2
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
