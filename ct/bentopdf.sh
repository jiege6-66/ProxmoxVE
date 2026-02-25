#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/alam00000/bentopdf

APP="BentoPDF"
var_tags="${var_tags:-pdf-editor}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-4096}"
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
  if [[ ! -d /opt/bentopdf ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  NODE_VERSION="24" setup_nodejs

  if check_for_gh_release "bentopdf" "alam00000/bentopdf"; then
    msg_info "正在停止 Service"
    systemctl stop bentopdf
    msg_ok "已停止 Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "bentopdf" "alam00000/bentopdf" "tarball" "latest" "/opt/bentopdf"

    msg_info "正在更新 BentoPDF"
    cd /opt/bentopdf
    $STD npm ci --no-audit --no-fund
    export SIMPLE_MODE=true
    $STD npm run build -- --mode production
    msg_ok "Updated BentoPDF"

    msg_info "正在启动 Service"
    systemctl start bentopdf
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
