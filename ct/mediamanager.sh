#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/maxdorninger/MediaManager

APP="MediaManager"
var_tags="${var_tags:-arr}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-3072}"
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
  if [[ ! -d /opt/mediamanager ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  setup_uv

  if check_for_gh_release "mediamanager" "maxdorninger/MediaManager"; then
    msg_info "正在停止 Service"
    systemctl stop mediamanager
    msg_ok "已停止 Service"

    fetch_and_deploy_gh_release "MediaManager" "maxdorninger/MediaManager" "tarball" "latest" "/opt/mediamanager"
    msg_info "正在更新 MediaManager"
    MM_DIR="/opt/mm"
    export CONFIG_DIR="${MM_DIR}/config"
    export FRONTEND_FILES_DIR="${MM_DIR}/web/build"
    export PUBLIC_VERSION=""
    export PUBLIC_API_URL=""
    export BASE_PATH="/web"
    cd /opt/mediamanager/web 
    $STD npm install --no-fund --no-audit
    $STD npm run build
    rm -rf "$FRONTEND_FILES_DIR"/build
    cp -r build "$FRONTEND_FILES_DIR"
    export BASE_PATH=""
    export VIRTUAL_ENV="/opt/${MM_DIR}/venv"
    cd /opt/mediamanager 
    rm -rf "$MM_DIR"/{media_manager,alembic*}
    cp -r {media_manager,alembic*} "$MM_DIR"
    $STD /usr/local/bin/uv sync --locked --active -n -p cpython3.13 --managed-python
    if ! grep -q "LOG_FILE" "$MM_DIR"/start.sh; then
      sed -i "\|build\"$|a\export LOG_FILE=\"$CONFIG_DIR/media_manager.log\"" "$MM_DIR"/start.sh
    fi

    msg_ok "Updated MediaManager"

    msg_info "正在启动 Service"
    systemctl start mediamanager
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
