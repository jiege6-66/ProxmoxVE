#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://www.kimai.org/

APP="Kimai"
var_tags="${var_tags:-time-tracking}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-7}"
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
  ensure_dependencies lsb-release
  if [[ ! -d /opt/kimai ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  setup_mariadb

  PHP_VERSION="8.4" PHP_APACHE="YES" setup_php
  setup_composer

  if check_for_gh_release "kimai" "kimai/kimai"; then
    BACKUP_DIR="/opt/kimai_backup"

    msg_info "正在停止 Apache2"
    systemctl stop apache2
    msg_ok "已停止 Apache2"

    msg_info "正在备份 Kimai configuration and var directory"
    mkdir -p "$BACKUP_DIR"
    [ -d /opt/kimai/var ] && cp -r /opt/kimai/var "$BACKUP_DIR/"
    [ -f /opt/kimai/.env ] && cp /opt/kimai/.env "$BACKUP_DIR/"
    [ -f /opt/kimai/config/packages/local.yaml ] && cp /opt/kimai/config/packages/local.yaml "$BACKUP_DIR/"
    msg_ok "Backup completed"

    fetch_and_deploy_gh_release "kimai" "kimai/kimai" "tarball"

    msg_info "正在更新 Kimai"
    [ -d "$BACKUP_DIR/var" ] && cp -r "$BACKUP_DIR/var" /opt/kimai/
    [ -f "$BACKUP_DIR/.env" ] && cp "$BACKUP_DIR/.env" /opt/kimai/
    [ -f "$BACKUP_DIR/local.yaml" ] && cp "$BACKUP_DIR/local.yaml" /opt/kimai/config/packages/
    rm -rf "$BACKUP_DIR"
    cd /opt/kimai 
    sed -i '/^admin_lte:/,/^[^[:space:]]/d' config/packages/local.yaml
    $STD composer install --no-dev --optimize-autoloader
    $STD bin/console kimai:update
    msg_ok "Updated Kimai"

    msg_info "正在启动 Apache2"
    systemctl start apache2
    msg_ok "已启动 Apache2"

    msg_info "设置 Permissions"
    chown -R :www-data /opt/*
    chmod -R g+r /opt/*
    chmod -R g+rw /opt/*
    chown -R www-data:www-data /opt/*
    chmod -R 777 /opt/*
    rm -rf "$BACKUP_DIR"
    msg_ok "设置 Permissions"
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
