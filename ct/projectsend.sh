#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.projectsend.org/

APP="ProjectSend"
var_tags="${var_tags:-media}"
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
  if [[ ! -d /opt/projectsend ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  setup_mariadb

  if check_for_gh_release "projectsend" "projectsend/projectsend"; then
    msg_info "正在停止 Service"
    systemctl stop apache2
    msg_ok "已停止 Service"

    php_ver=$(php -v | head -n 1 | awk '{print $2}')
    if [[ ! $php_ver == "8.4"* ]]; then
      PHP_VERSION="8.4" PHP_APACHE="YES" setup_php
    fi

    mv /opt/projectsend/includes/sys.config.php /opt/sys.config.php
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "projectsend" "projectsend/projectsend" "prebuild" "latest" "/opt/projectsend" "projectsend-r*.zip"
    mv /opt/sys.config.php /opt/projectsend/includes/sys.config.php
    chown -R www-data:www-data /opt/projectsend
    chmod -R 775 /opt/projectsend

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
