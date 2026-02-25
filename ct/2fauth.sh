#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: jkrgr0
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.2fauth.app/

APP="2FAuth"
var_tags="${var_tags:-2fa;authenticator}"
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

  if [[ ! -d "/opt/2fauth" ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  setup_mariadb
  if check_for_gh_release "2fauth" "Bubka/2FAuth"; then
    $STD apt update
    $STD apt -y upgrade

    msg_info "正在创建 Backup"
    mv "/opt/2fauth" "/opt/2fauth-backup"
    if ! dpkg -l | grep -q 'php8.4'; then
      cp /etc/nginx/conf.d/2fauth.conf /etc/nginx/conf.d/2fauth.conf.bak
    fi
    msg_ok "Backup 已创建"

    if ! dpkg -l | grep -q 'php8.4'; then
      PHP_VERSION="8.4" PHP_FPM="YES" setup_php
      sed -i 's/php8\.[0-9]/php8.4/g' /etc/nginx/conf.d/2fauth.conf
    fi
    fetch_and_deploy_gh_release "2fauth" "Bubka/2FAuth" "tarball"
    setup_composer
    mv "/opt/2fauth-backup/.env" "/opt/2fauth/.env"
    mv "/opt/2fauth-backup/storage" "/opt/2fauth/storage"
    cd "/opt/2fauth" || return
    chown -R www-data: "/opt/2fauth"
    chmod -R 755 "/opt/2fauth"
    export COMPOSER_ALLOW_SUPERUSER=1
    $STD composer install --no-dev --prefer-dist
    php artisan 2fauth:install
    $STD systemctl restart nginx
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
