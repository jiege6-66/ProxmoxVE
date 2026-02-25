#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Nícolas Pastorello (opastorello)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://privatebin.info/

APP="PrivateBin"
var_tags="${var_tags:-paste;secure}"
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
  if [[ ! -d /opt/privatebin ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "privatebin" "PrivateBin/PrivateBin"; then
    msg_info "正在创建 backup"
    cp -f /opt/privatebin/cfg/conf.php /tmp/privatebin_conf.bak
    msg_ok "Backup created"

    rm -rf /opt/privatebin/*
    fetch_and_deploy_gh_release "privatebin" "PrivateBin/PrivateBin" "tarball"

    msg_info "正在配置 ${APP}"
    mkdir -p /opt/privatebin/data
    mv /tmp/privatebin_conf.bak /opt/privatebin/cfg/conf.php
    chown -R www-data:www-data /opt/privatebin
    chmod -R 0755 /opt/privatebin/data
    systemctl reload nginx php8.2-fpm
    msg_ok "已配置 ${APP}"
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
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}${CL}"
