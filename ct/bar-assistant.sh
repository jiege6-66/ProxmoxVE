#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: bvdberg01 | CanbiZ
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/karlomikus/bar-assistant
# Source: https://github.com/karlomikus/vue-salt-rim
# Source: https://www.meilisearch.com/

APP="Bar-Assistant"
var_tags="${var_tags:-cocktails;drinks}"
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
  if [[ ! -d /opt/bar-assistant ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "bar-assistant" "karlomikus/bar-assistant"; then
    msg_info "正在停止 nginx"
    systemctl stop nginx
    msg_ok "已停止 nginx"

    PHP_VERSION="8.4" PHP_FPM="YES" PHP_MODULE="pdo-sqlite" setup_php

    msg_info "正在备份 Bar Assistant"
    mv /opt/bar-assistant /opt/bar-assistant-backup
    msg_ok "已备份 Bar Assistant"

    fetch_and_deploy_gh_release "bar-assistant" "karlomikus/bar-assistant" "tarball" "latest" "/opt/bar-assistant"
    setup_composer

    msg_info "正在更新 Bar-Assistant"
    cp -r /opt/bar-assistant-backup/.env /opt/bar-assistant/.env
    cp -r /opt/bar-assistant-backup/storage/bar-assistant /opt/bar-assistant/storage/bar-assistant
    cd /opt/bar-assistant
    $STD composer install --no-interaction
    $STD php artisan migrate --force
    $STD php artisan storage:link
    $STD php artisan bar:setup-meilisearch
    $STD php artisan scout:sync-index-settings
    $STD php artisan config:cache
    $STD php artisan route:cache
    $STD php artisan event:cache
    chown -R www-data:www-data /opt/bar-assistant
    rm -rf /opt/bar-assistant-backup
    msg_ok "Updated Bar-Assistant"

    msg_info "正在启动 nginx"
    systemctl start nginx
    msg_ok "已启动 nginx"
  fi

  if check_for_gh_release "vue-salt-rim" "karlomikus/vue-salt-rim"; then
    msg_info "正在备份 Vue Salt Rim"
    mv /opt/vue-salt-rim /opt/vue-salt-rim-backup
    msg_ok "已备份 Vue Salt Rim"

    msg_info "正在停止 nginx"
    systemctl stop nginx
    msg_ok "已停止 nginx"

    fetch_and_deploy_gh_release "vue-salt-rim" "karlomikus/vue-salt-rim" "tarball" "latest" "/opt/vue-salt-rim"

    msg_info "正在更新 Vue Salt Rim"
    cp /opt/vue-salt-rim-backup/public/config.js /opt/vue-salt-rim/public/config.js
    cd /opt/vue-salt-rim
    $STD npm install
    $STD npm run build
    rm -rf /opt/vue-salt-rim-backup
    msg_ok "Updated Vue Salt Rim"

    msg_info "正在启动 nginx"
    systemctl start nginx
    msg_ok "已启动 nginx"
  fi

  setup_meilisearch

  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
