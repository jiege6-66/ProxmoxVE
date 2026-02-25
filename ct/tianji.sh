#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tianji.msgbyte.com/

APP="Tianji"
var_tags="${var_tags:-monitoring}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-12}"
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
  if [[ ! -d /opt/tianji ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  setup_uv
  if check_for_gh_release "tianji" "msgbyte/tianji"; then
    NODE_VERSION="22" NODE_MODULE="pnpm@$(curl -s https://raw.githubusercontent.com/msgbyte/tianji/master/package.json | jq -r '.packageManager | split("@")[1]')" setup_nodejs

    msg_info "正在停止 Service"
    systemctl stop tianji
    msg_ok "已停止 Service"

    msg_info "正在备份 data"
    cp /opt/tianji/src/server/.env /opt/.env
    mv /opt/tianji /opt/tianji_bak
    msg_ok "已备份 data"

    fetch_and_deploy_gh_release "tianji" "msgbyte/tianji" "tarball"

    msg_info "正在更新 Tianji"
    cd /opt/tianji
    export NODE_OPTIONS="--max_old_space_size=4096"
    $STD pnpm install --filter @tianji/client... --config.dedupe-peer-dependents=false --frozen-lockfile
    $STD pnpm build:static
    $STD pnpm install --filter @tianji/server... --config.dedupe-peer-dependents=false
    mkdir -p ./src/server/public
    cp -r ./geo ./src/server/public
    $STD pnpm build:server
    mv /opt/.env /opt/tianji/src/server/.env
    cd src/server
    $STD pnpm db:migrate:apply
    rm -rf /opt/tianji_bak
    rm -rf /opt/tianji/src/client
    rm -rf /opt/tianji/website
    rm -rf /opt/tianji/reporter
    msg_ok "Updated Tianji"

    msg_info "正在更新 AppRise"
    $STD uv pip install apprise cryptography --system
    msg_ok "Updated AppRise"

    msg_info "正在启动 Service"
    systemctl start tianji
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:12345${CL}"
