#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://nginxui.com

APP="Nginx-UI"
var_tags="${var_tags:-webserver;nginx;proxy}"
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

  if [[ ! -f /usr/local/bin/nginx-ui ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "nginx-ui" "0xJacky/nginx-ui"; then
    msg_info "正在停止 Service"
    systemctl stop nginx-ui
    msg_ok "已停止 Service"

    msg_info "正在备份 Configuration"
    cp /usr/local/etc/nginx-ui/app.ini /tmp/nginx-ui-app.ini.bak
    msg_ok "已备份 Configuration"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "nginx-ui" "0xJacky/nginx-ui" "prebuild" "latest" "/opt/nginx-ui" "nginx-ui-linux-64.tar.gz"

    msg_info "正在更新 Binary"
    cp /opt/nginx-ui/nginx-ui /usr/local/bin/nginx-ui
    chmod +x /usr/local/bin/nginx-ui
    rm -rf /opt/nginx-ui
    msg_ok "Updated Binary"

    msg_info "正在恢复 Configuration"
    mv /tmp/nginx-ui-app.ini.bak /usr/local/etc/nginx-ui/app.ini
    msg_ok "已恢复 Configuration"

    msg_info "正在启动 Service"
    systemctl start nginx-ui
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9000${CL}"
