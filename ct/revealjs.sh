#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/hakimel/reveal.js

APP="RevealJS"
var_tags="${var_tags:-presentation}"
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
  if [[ ! -d "/opt/revealjs" ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "revealjs" "hakimel/reveal.js"; then
    msg_info "正在停止 Service"
    systemctl stop revealjs
    msg_info "已停止 Service"

    cp /opt/revealjs/index.html /opt
    fetch_and_deploy_gh_release "revealjs" "hakimel/reveal.js" "tarball"

    msg_info "正在更新 RevealJS"
    cd /opt/revealjs
    $STD npm install
    cp -f /opt/index.html /opt/revealjs
    sed -i '25s/localhost/0.0.0.0/g' /opt/revealjs/gulpfile.js
    rm -f /opt/index.html
    msg_ok "Updated RevealJS"

    msg_info "正在启动 Service"
    systemctl start revealjs
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
