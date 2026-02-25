#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://sabre.io/baikal/

APP="Baikal"
var_tags="${var_tags:-Dav}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
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

  if [[ ! -d /opt/baikal ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "baikal" "sabre-io/Baikal"; then
    msg_info "正在停止 Service"
    systemctl stop apache2
    msg_ok "已停止 Service"

    msg_info "正在备份 data"
    mv /opt/baikal /opt/baikal-backup
    msg_ok "已备份 data"

    PHP_APACHE="YES" PHP_VERSION="8.3" setup_php
    setup_composer
    fetch_and_deploy_gh_release "baikal" "sabre-io/Baikal" "tarball"

    msg_info "正在配置 Baikal"
    cp -r /opt/baikal-backup/config/baikal.yaml /opt/baikal/config/
    cp -r /opt/baikal-backup/Specific/ /opt/baikal/
    chown -R www-data:www-data /opt/baikal/
    chmod -R 755 /opt/baikal/
    cd /opt/baikal
    $STD composer install
    rm -rf /opt/baikal-backup
    msg_ok "已配置 Baikal"

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
