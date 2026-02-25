#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://zipline.diced.sh/

APP="Zipline"
var_tags="${var_tags:-file;sharing}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-5}"
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
  if [[ ! -d /opt/zipline ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  NODE_VERSION="22" NODE_MODULE="pnpm" setup_nodejs

  if check_for_gh_release "zipline" "diced/zipline"; then
    msg_info "正在停止 Service"
    systemctl stop zipline
    msg_ok "Service 已停止"

    mkdir -p /opt/zipline-uploads
    if [ -d /opt/zipline/uploads ] && [ "$(ls -A /opt/zipline/uploads)" ]; then
      cp -R /opt/zipline/uploads/* /opt/zipline-uploads/
    fi
    cp /opt/zipline/.env /opt/
    rm -R /opt/zipline
    fetch_and_deploy_gh_release "zipline" "diced/zipline" "tarball"

    msg_info "正在更新 ${APP}"
    cd /opt/zipline
    mv /opt/.env /opt/zipline/.env
    $STD pnpm install
    $STD pnpm build
    msg_ok "Updated ${APP}"

    msg_info "正在启动 Service"
    systemctl start zipline
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
