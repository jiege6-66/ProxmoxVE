#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ampache/ampache

APP="Ampache"
var_tags="${var_tags:-music}"
var_disk="${var_disk:-5}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-2048}"
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

  if [[ ! -d /opt/ampache ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "Ampache" "ampache/ampache"; then
    msg_info "正在停止 Service"
    systemctl stop apache2
    msg_ok "已停止 Service"

    msg_info "正在创建 Backup"
    cp /opt/ampache/config/ampache.cfg.php /tmp/ampache.cfg.php.backup
    cp /opt/ampache/public/rest/.htaccess /tmp/ampache_rest.htaccess.backup
    cp /opt/ampache/public/play/.htaccess /tmp/ampache_play.htaccess.backup
    rm -rf /opt/ampache_backup
    mv /opt/ampache /opt/ampache_backup
    msg_ok "已创建 Backup"

    fetch_and_deploy_gh_release "Ampache" "ampache/ampache" "prebuild" "latest" "/opt/ampache" "ampache-*_all_php8.4.zip"

    msg_info "正在恢复 Backup"
    cp /tmp/ampache.cfg.php.backup /opt/ampache/config/ampache.cfg.php
    cp /tmp/ampache_rest.htaccess.backup /opt/ampache/public/rest/.htaccess
    cp /tmp/ampache_play.htaccess.backup /opt/ampache/public/play/.htaccess
    chmod 664 /opt/ampache/public/rest/.htaccess /opt/ampache/public/play/.htaccess
    chown -R www-data:www-data /opt/ampache
    rm -f /tmp/ampache*.backup
    msg_ok "已恢复 Configuration"

    msg_info "正在启动 Service"
    systemctl start apache2
    msg_ok "已启动 Service"
    msg_ok "已成功更新!"
    msg_custom "⚠️" "${YW}" "Complete database update by visiting: http://${LOCAL_IP}/update.php"
  fi
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}/install.php${CL}"
