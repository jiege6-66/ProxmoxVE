#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://tududi.com

APP="Tududi"
var_tags="${var_tags:-todo-app}"
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
  if [[ ! -d /opt/tududi ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  NODE_VERSION="22" setup_nodejs

  if check_for_gh_release "tududi" "chrisvel/tududi"; then
    msg_info "正在停止 Service"
    systemctl stop tududi
    msg_ok "已停止 Service"

    msg_info "正在备份 env file"
    if [[ -f /opt/tududi/backend/.env ]]; then
      cp /opt/tududi/backend/.env /opt/tududi.env
    else
      cp /opt/tududi/.env /opt/tududi.env
    fi
    msg_ok "已备份 env file"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "tududi" "chrisvel/tududi" "tarball" "latest" "/opt/tududi"

    msg_info "正在更新 Tududi"
    cd /opt/tududi
    $STD npm install
    export NODE_ENV=production
    $STD npm run frontend:build
    mv ./dist ./backend
    mv /opt/tududi.env /opt/tududi/backend/.env
    DB="$(sed -n '/^DB_FILE/s/[^=]*=//p' /opt/tududi/backend/.env)"
    export DB_FILE="$DB"
    sed -i -e 's|/tududi$|/tududi/backend|' \
      -e 's|npm run start|bash /opt/tududi/backend/cmd/start.sh|' \
      /etc/systemd/system/tududi.service
    systemctl daemon-reload
    msg_ok "Updated Tududi"

    msg_info "正在启动 Service"
    systemctl start tududi
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3002${CL}"
