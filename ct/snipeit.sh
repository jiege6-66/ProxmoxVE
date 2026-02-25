#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://snipeitapp.com/

APP="SnipeIT"
var_tags="${var_tags:-asset-management;foss}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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
  if [[ ! -d /opt/snipe-it ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  setup_mariadb
  if ! grep -q "client_max_body_size[[:space:]]\+100M;" /etc/nginx/conf.d/snipeit.conf; then
    sed -i '/index index.php;/i \        client_max_body_size 100M;' /etc/nginx/conf.d/snipeit.conf
  fi

  if check_for_gh_release "snipe-it" "grokability/snipe-it"; then
    msg_info "正在停止 Services"
    systemctl stop nginx
    msg_ok "Services 已停止"

    msg_info "正在创建 Backup"
    mv /opt/snipe-it /opt/snipe-it-backup
    msg_ok "已创建 Backup"

    fetch_and_deploy_gh_release "snipe-it" "grokability/snipe-it" "tarball"
    [[ "$(php -v 2>/dev/null)" == PHP\ 8.2* ]] && PHP_VERSION="8.3" PHP_FPM="YES" PHP_MODULE="ldap,soap,xsl" setup_php
    sed -i 's/php8.2/php8.3/g' /etc/nginx/conf.d/snipeit.conf
    setup_composer

    msg_info "正在更新 Snipe-IT"
    $STD apt update
    $STD apt -y upgrade
    cp /opt/snipe-it-backup/.env /opt/snipe-it/.env
    cp -r /opt/snipe-it-backup/public/uploads/. /opt/snipe-it/public/uploads/
    cp -r /opt/snipe-it-backup/storage/private_uploads/. /opt/snipe-it/storage/private_uploads/
    cd /opt/snipe-it/
    export COMPOSER_ALLOW_SUPERUSER=1
    $STD composer install --no-dev --optimize-autoloader --no-interaction
    $STD composer dump-autoload
    $STD php artisan migrate --force
    $STD php artisan config:clear
    $STD php artisan route:clear
    $STD php artisan cache:clear
    $STD php artisan view:clear
    chown -R www-data: /opt/snipe-it
    chmod -R 755 /opt/snipe-it
    rm -rf /opt/snipe-it-backup
    msg_ok "Updated Snipe-IT"

    msg_info "正在启动 Service"
    systemctl start nginx
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
