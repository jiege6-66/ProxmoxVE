#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://invoiceninja.com/

APP="InvoiceNinja"
var_tags="${var_tags:-invoicing;business}"
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

  if [[ ! -d /opt/invoiceninja ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  setup_mariadb
  if check_for_gh_release "invoiceninja" "invoiceninja/invoiceninja"; then
    msg_info "正在停止 Services"
    systemctl stop supervisor nginx php8.4-fpm
    msg_ok "已停止 Services"

    msg_info "正在创建 Backup"
    mkdir -p /tmp/invoiceninja_backup
    cp /opt/invoiceninja/.env /tmp/invoiceninja_backup/
    cp -r /opt/invoiceninja/storage /tmp/invoiceninja_backup/ 2>/dev/null || true
    cp -r /opt/invoiceninja/public/storage /tmp/invoiceninja_backup/public_storage 2>/dev/null || true
    msg_ok "已创建 Backup"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "invoiceninja" "invoiceninja/invoiceninja" "prebuild" "latest" "/opt/invoiceninja" "invoiceninja.tar.gz"

    msg_info "正在恢复 Data"
    cp /tmp/invoiceninja_backup/.env /opt/invoiceninja/
    cp -r /tmp/invoiceninja_backup/storage/* /opt/invoiceninja/storage/ 2>/dev/null || true
    cp -r /tmp/invoiceninja_backup/public_storage/* /opt/invoiceninja/public/storage/ 2>/dev/null || true
    rm -rf /tmp/invoiceninja_backup
    msg_ok "已恢复 Data"

    msg_info "正在运行 Migrations"
    cd /opt/invoiceninja 
    $STD php artisan migrate --force
    $STD php artisan config:clear
    $STD php artisan cache:clear
    $STD php artisan optimize
    chown -R www-data:www-data /opt/invoiceninja
    chmod -R 755 /opt/invoiceninja/storage
    msg_ok "Ran Migrations"

    msg_info "正在启动 Services"
    systemctl start php8.4-fpm nginx supervisor
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080/setup${CL}"
