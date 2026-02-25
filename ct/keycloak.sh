#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster) | Co-Author: remz1337
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://www.keycloak.org/

APP="Keycloak"
var_tags="${var_tags:-access-management}"
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
  if [[ ! -d /opt/keycloak ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "keycloak_app" "keycloak/keycloak"; then
    msg_info "正在停止 Service"
    systemctl stop keycloak
    msg_ok "已停止 Service"

    msg_info "正在更新 packages"
    $STD apt-get update
    $STD apt-get -y upgrade
    msg_ok "Updated packages"

    msg_info "Backup old Keycloak"
    cd /opt
    mv keycloak keycloak.old
    msg_ok "Backup done"

    fetch_and_deploy_gh_release "keycloak_app" "keycloak/keycloak" "prebuild" "latest" "/opt/keycloak" "keycloak-*.tar.gz"

    msg_info "正在更新 Keycloak"
    cd /opt
    cp -a keycloak.old/conf/. keycloak/conf/
    cp -a keycloak.old/providers/. keycloak/providers/ 2>/dev/null || true
    cp -a keycloak.old/themes/. keycloak/themes/ 2>/dev/null || true
    rm -rf keycloak.old
    msg_ok "Updated Keycloak"

    msg_info "正在重启 Service"
    systemctl restart keycloak
    msg_ok "已重启 Service"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080/admin${CL}"
