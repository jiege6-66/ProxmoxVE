#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: luismco
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ThePhaseless/Byparr

APP="Byparr"
var_tags="${var_tags:-proxy}"
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
  if [[ ! -d /opt/Byparr ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "Byparr" "ThePhaseless/Byparr"; then
    msg_info "正在停止 Service"
    systemctl stop byparr
    msg_ok "已停止 Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Byparr" "ThePhaseless/Byparr" "tarball" "latest"

    if ! dpkg -l | grep -q ffmpeg; then
      msg_info "正在安装 dependencies"
      $STD apt install -y --no-install-recommends \
        ffmpeg \
        libatk1.0-0 \
        libcairo-gobject2 \
        libcairo2 \
        libdbus-glib-1-2 \
        libfontconfig1 \
        libfreetype6 \
        libgdk-pixbuf-xlib-2.0-0 \
        libglib2.0-0 \
        libgtk-3-0 \
        libpango-1.0-0 \
        libpangocairo-1.0-0 \
        libpangoft2-1.0-0 \
        libx11-6 \
        libx11-xcb1 \
        libxcb-shm0 \
        libxcb1 \
        libxcomposite1 \
        libxcursor1 \
        libxdamage1 \
        libxext6 \
        libxfixes3 \
        libxi6 \
        libxrender1 \
        libxt6 \
        libxtst6 \
        xvfb \
        fonts-noto-color-emoji \
        fonts-unifont \
        xfonts-cyrillic \
        xfonts-scalable \
        fonts-liberation \
        fonts-ipafont-gothic \
        fonts-wqy-zenhei \
        fonts-tlwg-loma-otf
      $STD apt autoremove -y chromium
      msg_ok "已安装 dependencies"
    fi

    msg_info "正在配置 Byparr"
    cd /opt/Byparr
    $STD uv sync --link-mode copy
    $STD uv run camoufox fetch
    msg_ok "已配置 Byparr"

    msg_info "正在启动 Service"
    systemctl start byparr
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8191${CL}"
