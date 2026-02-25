#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/LibreTranslate/LibreTranslate

APP="LibreTranslate"
var_tags="${var_tags:-Arr}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-20}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
var_gpu="${var_gpu:-yes}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/libretranslate ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  PYTHON_VERSION="3.12" setup_uv

  if check_for_gh_release "libretranslate" "LibreTranslate/LibreTranslate"; then
    msg_info "正在停止 Service"
    systemctl stop libretranslate
    msg_ok "已停止 Service"

    msg_info "正在更新 LibreTranslate"
    cd /opt/libretranslate
    source .venv/bin/activate
    $STD uv pip install -U libretranslate
    msg_ok "Updated LibreTranslate"

    msg_info "正在启动 Service"
    systemctl start libretranslate
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5000${CL}"
