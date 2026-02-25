#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Nícolas Pastorello (opastorello)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://www.paymenter.org

APP="Paymenter"
var_tags="${var_tags:-hosting;ecommerce;marketplace;}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
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
  if [[ ! -d /opt/paymenter ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  setup_mariadb

  CURRENT_PHP=$(php -v 2>/dev/null | awk '/^PHP/{print $2}' | cut -d. -f1,2)
  if [[ "$CURRENT_PHP" != "8.3" ]]; then
    PHP_VERSION="8.3" PHP_FPM="YES" setup_php
    setup_composer
    sed -i 's|php8\.2-fpm\.sock|php8.3-fpm.sock|g' /etc/nginx/sites-available/paymenter.conf
    $STD systemctl reload nginx
  fi

  if check_for_gh_release "paymenter" "paymenter/paymenter"; then
    msg_info "正在更新 ${APP}"
    cd /opt/paymenter
    $STD php artisan app:upgrade --no-interaction
    echo "${CHECK_UPDATE_RELEASE}" >~/.paymenter
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:80${CL}"
