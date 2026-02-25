#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://wallabag.org/

APP="Wallabag"
var_tags="${var_tags:-productivity;read-it-later}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
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

  if [[ ! -d /opt/wallabag ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  setup_mariadb
  if check_for_gh_release "wallabag" "wallabag/wallabag"; then
    msg_info "正在停止 Services"
    systemctl stop nginx php8.3-fpm
    msg_ok "已停止 Services"

    msg_info "正在创建 Backup"
    cp /opt/wallabag/app/config/parameters.yml /tmp/wallabag_parameters.yml.bak
    msg_ok "已创建 Backup"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "wallabag" "wallabag/wallabag" "prebuild" "latest" "/opt/wallabag" "wallabag-*.tar.gz"

    msg_info "正在恢复 Configuration"
    cp /tmp/wallabag_parameters.yml.bak /opt/wallabag/app/config/parameters.yml
    rm -f /tmp/wallabag_parameters.yml.bak
    msg_ok "已恢复 Configuration"

    msg_info "正在运行 Migrations"
    cd /opt/wallabag
    $STD php bin/console cache:clear --env=prod
    $STD php bin/console doctrine:migrations:migrate --env=prod --no-interaction
    chown -R www-data:www-data /opt/wallabag
    chmod -R 755 /opt/wallabag/{var,web/assets}
    msg_ok "Ran Migrations"

    msg_info "正在启动 Services"
    systemctl start php8.3-fpm nginx
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
