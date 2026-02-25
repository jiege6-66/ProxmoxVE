#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/BookStackApp/BookStack

APP="Bookstack"
var_tags="${var_tags:-organizer}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
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

  if [[ ! -d /opt/bookstack ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  setup_mariadb
  if check_for_gh_release "bookstack" "BookStackApp/BookStack"; then
    msg_info "正在停止 Apache2"
    systemctl stop apache2
    msg_ok "Services 已停止"

    msg_info "正在备份 data"
    mv /opt/bookstack /opt/bookstack-backup
    msg_ok "Backup finished"

    fetch_and_deploy_gh_release "bookstack" "BookStackApp/BookStack" "tarball"
    PHP_VERSION="8.3" PHP_APACHE="YES" PHP_FPM="YES" PHP_MODULE="ldap,tidy,mysqli" setup_php
    setup_composer

    msg_info "正在恢复 backup"
    cp /opt/bookstack-backup/.env /opt/bookstack/.env
    [[ -d /opt/bookstack-backup/public/uploads ]] && cp -a /opt/bookstack-backup/public/uploads/. /opt/bookstack/public/uploads/
    [[ -d /opt/bookstack-backup/storage/uploads ]] && cp -a /opt/bookstack-backup/storage/uploads/. /opt/bookstack/storage/uploads/
    [[ -d /opt/bookstack-backup/themes ]] && cp -a /opt/bookstack-backup/themes/. /opt/bookstack/themes/
    msg_ok "Backup restored"

    msg_info "正在配置 BookStack"
    cd /opt/bookstack
    export COMPOSER_ALLOW_SUPERUSER=1
    $STD /usr/local/bin/composer install --no-dev
    $STD php artisan migrate --force
    chown www-data:www-data -R /opt/bookstack /opt/bookstack/bootstrap/cache /opt/bookstack/public/uploads /opt/bookstack/storage
    chmod -R 755 /opt/bookstack /opt/bookstack/bootstrap/cache /opt/bookstack/public/uploads /opt/bookstack/storage
    chmod -R 775 /opt/bookstack/storage /opt/bookstack/bootstrap/cache /opt/bookstack/public/uploads
    chmod -R 640 /opt/bookstack/.env
    rm -rf /opt/bookstack-backup
    msg_ok "已配置 BookStack"

    msg_info "正在启动 Apache2"
    systemctl start apache2
    msg_ok "已启动 Apache2"
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
