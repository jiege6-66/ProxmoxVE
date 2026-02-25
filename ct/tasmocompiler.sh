#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/benzino77/tasmocompiler

APP="TasmoCompiler"
var_tags="${var_tags:-compiler}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
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
  if [[ ! -d /opt/tasmocompiler ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/benzino77/tasmocompiler/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "正在停止 Service"
    systemctl stop tasmocompiler
    msg_ok "已停止 Service"

    msg_info "正在更新 TasmoCompiler"
    cd /opt
    rm -rf /opt/tasmocompiler
    RELEASE=$(curl -fsSL https://api.github.com/repos/benzino77/tasmocompiler/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
    curl -fsSL "https://github.com/benzino77/tasmocompiler/archive/refs/tags/v${RELEASE}.tar.gz" -o $(basename "https://github.com/benzino77/tasmocompiler/archive/refs/tags/v${RELEASE}.tar.gz")
    tar xzf v${RELEASE}.tar.gz
    mv tasmocompiler-${RELEASE}/ /opt/tasmocompiler/
    cd /opt/tasmocompiler
    $STD yarn install
    export NODE_OPTIONS=--openssl-legacy-provider
    $STD npm i
    $STD yarn build
    rm -r "/opt/v${RELEASE}.tar.gz"
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated TasmoCompiler"

    msg_info "正在启动 Service"
    systemctl start tasmocompiler
    msg_ok "已启动 Service"
    msg_ok "已成功更新!"
  else
    msg_ok "无需更新。 ${APP} is already at v${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
