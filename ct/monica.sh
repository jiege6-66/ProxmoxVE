#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://www.monicahq.com/

APP="Monica"
var_tags="${var_tags:-network}"
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
  if [[ ! -d /opt/monica ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  setup_mariadb
  NODE_VERSION="22" NODE_MODULE="yarn@latest" setup_nodejs

  # Fix for previous versions not having cronjob
  if ! grep -Fq 'php /opt/monica/artisan schedule:run' /etc/crontab; then
    echo '* * * * * root php /opt/monica/artisan schedule:run >> /dev/null 2>&1' >>/etc/crontab
  fi

  if check_for_gh_release "monica" "monicahq/monica"; then
    msg_info "正在停止 Service"
    systemctl stop apache2
    msg_ok "已停止 Service"

    msg_info "正在创建 backup"
    mv /opt/monica/ /opt/monica-backup
    msg_ok "Backup created"

    fetch_and_deploy_gh_release "monica" "monicahq/monica" "prebuild" "latest" "/opt/monica" "monica-v*.tar.bz2"

    msg_info "正在配置 monica"
    cd /opt/monica/
    cp -r /opt/monica-backup/.env /opt/monica
    cp -r /opt/monica-backup/storage/* /opt/monica/storage/
    $STD composer install --no-interaction --no-dev
    $STD yarn config set ignore-engines true
    $STD yarn install
    $STD yarn run production
    $STD php artisan monica:update --force
    chown -R www-data:www-data /opt/monica
    chmod -R 775 /opt/monica/storage
    rm -r /opt/monica-backup
    msg_ok "已配置 monica"

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
