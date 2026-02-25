#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.grampsweb.org/

APP="gramps-web"
var_tags="${var_tags:-genealogy;family;collaboration}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
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

  if [[ ! -d /opt/gramps-web-api ]] || [[ ! -d /opt/gramps-web/frontend ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  PYTHON_VERSION="3.12" setup_uv
  NODE_VERSION="22" setup_nodejs

  if check_for_gh_release "gramps-web-api" "gramps-project/gramps-web-api"; then
    msg_info "正在停止 Service"
    systemctl stop gramps-web
    msg_ok "已停止 Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "gramps-web-api" "gramps-project/gramps-web-api" "tarball" "latest" "/opt/gramps-web-api"

    msg_info "正在更新 Gramps Web API"
    $STD uv venv -c -p python3.12 /opt/gramps-web/venv
    source /opt/gramps-web/venv/bin/activate
    $STD uv pip install --no-cache-dir --upgrade pip setuptools wheel
    $STD uv pip install --no-cache-dir gunicorn
    $STD uv pip install --no-cache-dir /opt/gramps-web-api
    msg_ok "Updated Gramps Web API"

    msg_info "Applying Database Migration"
    cd /opt/gramps-web-api
    GRAMPS_API_CONFIG=/opt/gramps-web/config/config.cfg \
      ALEMBIC_CONFIG=/opt/gramps-web-api/alembic.ini \
      GRAMPSHOME=/opt/gramps-web/data/gramps \
      GRAMPS_DATABASE_PATH=/opt/gramps-web/data/gramps/grampsdb \
      $STD /opt/gramps-web/venv/bin/python3 -m gramps_webapi user migrate
    msg_ok "Applied Database Migration"

    msg_info "正在启动 Service"
    systemctl start gramps-web
    msg_ok "已启动 Service"
  fi

  if check_for_gh_release "gramps-web" "gramps-project/gramps-web"; then
    msg_info "正在停止 Service"
    systemctl stop gramps-web
    msg_ok "已停止 Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "gramps-web" "gramps-project/gramps-web" "tarball" "latest" "/opt/gramps-web/frontend"

    msg_info "正在更新 Gramps Web Frontend"
    cd /opt/gramps-web/frontend
    export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
    $STD corepack enable
    $STD npm install
    $STD npm run build
    msg_ok "Updated Gramps Web Frontend"

    msg_info "正在启动 Service"
    systemctl start gramps-web
    msg_ok "已启动 Service"
  fi
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5000${CL}"
