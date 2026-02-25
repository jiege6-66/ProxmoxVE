#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://koel.dev/

APP="Koel"
var_tags="${var_tags:-music;streaming}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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

  if [[ ! -d /opt/koel ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "koel" "koel/koel"; then
    msg_info "正在停止 Services"
    systemctl stop nginx php8.4-fpm
    msg_ok "已停止 Services"

    msg_info "正在创建 Backup"
    mkdir -p /tmp/koel_backup
    cp /opt/koel/.env /tmp/koel_backup/
    cp -r /opt/koel/storage /tmp/koel_backup/ 2>/dev/null || true
    cp -r /opt/koel/public/img /tmp/koel_backup/ 2>/dev/null || true
    msg_ok "已创建 Backup"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "koel" "koel/koel" "prebuild" "latest" "/opt/koel" "koel-*.tar.gz"

    msg_info "正在恢复 Data"
    cp /tmp/koel_backup/.env /opt/koel/
    cp -r /tmp/koel_backup/storage/* /opt/koel/storage/ 2>/dev/null || true
    cp -r /tmp/koel_backup/img/* /opt/koel/public/img/ 2>/dev/null || true
    rm -rf /tmp/koel_backup
    msg_ok "已恢复 Data"

    msg_info "正在运行 Migrations"
    cd /opt/koel 
    export COMPOSER_ALLOW_SUPERUSER=1
    $STD composer install --no-interaction --no-dev --optimize-autoloader
    $STD php artisan migrate --force
    $STD php artisan config:clear
    $STD php artisan cache:clear
    $STD php artisan view:clear
    $STD php artisan koel:init --no-assets --no-interaction
    chown -R www-data:www-data /opt/koel
    chmod -R 775 /opt/koel/storage
    msg_ok "Ran Migrations"

    msg_info "正在启动 Services"
    systemctl start php8.4-fpm nginx
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
