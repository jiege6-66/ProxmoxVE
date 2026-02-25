#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://heimdall.site/

APP="Heimdall-Dashboard"
var_tags="${var_tags:-dashboard}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
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
  if [[ ! -d /opt/Heimdall ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "Heimdall" "linuxserver/Heimdall"; then
    msg_info "正在停止 Service"
    systemctl stop heimdall
    sleep 1
    msg_ok "已停止 Service"

    msg_info "正在备份 Data"
    cp -R /opt/Heimdall/database database-backup
    cp -R /opt/Heimdall/public public-backup
    sleep 1
    msg_ok "已备份 Data"

    setup_composer
    fetch_and_deploy_gh_release "Heimdall" "linuxserver/Heimdall" "tarball"

    msg_info "正在更新 Heimdall-Dashboard"
    cd /opt/Heimdall
    export COMPOSER_ALLOW_SUPERUSER=1
    $STD composer dump-autoload
    msg_ok "Updated Heimdall-Dashboard"

    msg_info "正在恢复 Data"
    cd ~
    cp -R database-backup/* /opt/Heimdall/database
    cp -R public-backup/* /opt/Heimdall/public
    sleep 1
    msg_ok "已恢复 Data"

    msg_info "正在清理 Up"
    rm -rf {public-backup,database-backup}
    sleep 1
    msg_ok "已清理 Up"

    msg_info "正在启动 Service"
    systemctl start heimdall.service
    sleep 2
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7990${CL}"
