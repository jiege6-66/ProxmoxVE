#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Crazywolf13
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/guillevc/yubal

APP="Yubal"
var_tags="${var_tags:-music;media}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-15}"
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

  if [[ ! -d /opt/yubal ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  ensure_dependencies git

  if check_for_gh_release "yubal" "guillevc/yubal"; then
    msg_info "正在停止 Services"
    systemctl stop yubal
    msg_ok "已停止 Services"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "yubal" "guillevc/yubal" "tarball" "latest" "/opt/yubal"

    msg_info "正在构建 Frontend"
    cd /opt/yubal/web
    $STD bun install --frozen-lockfile
    VERSION=$(get_latest_github_release "guillevc/yubal")
    VITE_VERSION=$VERSION VITE_COMMIT_SHA=$VERSION VITE_IS_RELEASE=true $STD bun run build
    msg_ok "已构建 Frontend"

    msg_info "正在安装 Python 依赖"
    cd /opt/yubal
    $STD uv sync --no-dev --frozen
    msg_ok "已安装 Python 依赖"

    msg_info "正在启动 Services"
    systemctl start yubal
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
