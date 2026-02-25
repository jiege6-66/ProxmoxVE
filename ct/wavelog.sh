#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Don Locke (DonLocke)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://www.wavelog.org/

APP="Wavelog"
var_tags="${var_tags:-radio-logging}"
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
  if [[ ! -d /opt/wavelog ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  setup_mariadb
  if check_for_gh_release "wavelog" "wavelog/wavelog"; then
    msg_info "正在停止 Services"
    systemctl stop apache2
    msg_ok "Services 已停止"

    msg_info "正在创建 backup"
    cp /opt/wavelog/application/config/config.php /opt/config.php
    cp /opt/wavelog/application/config/database.php /opt/database.php
    cp -r /opt/wavelog/userdata /opt/userdata
    if [[ -f /opt/wavelog/assets/js/sections/custom.js ]]; then
      cp /opt/wavelog/assets/js/sections/custom.js /opt/custom.js
    fi
    msg_ok "Backup created"

    rm -rf /opt/wavelog
    fetch_and_deploy_gh_release "wavelog" "wavelog/wavelog" "tarball"

    msg_info "正在更新 Wavelog"
    rm -rf /opt/wavelog/install
    mv /opt/config.php /opt/wavelog/application/config/config.php
    mv /opt/database.php /opt/wavelog/application/config/database.php
    cp -r /opt/userdata/* /opt/wavelog/userdata
    rm -rf /opt/userdata
    if [[ -f /opt/custom.js ]]; then
      mv /opt/custom.js /opt/wavelog/assets/js/sections/custom.js
    fi
    chown -R www-data:www-data /opt/wavelog/
    find /opt/wavelog/ -type d -exec chmod 755 {} \;
    find /opt/wavelog/ -type f -exec chmod 664 {} \;
    msg_ok "Updated Wavelog"

    msg_info "正在启动 Services"
    systemctl start apache2
    msg_ok "已启动 Services"
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
