#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/kyantech/Palmr

APP="Palmr"
var_tags="${var_tags:-files}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-6144}"
var_disk="${var_disk:-6}"
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
  if [[ ! -d /opt/palmr_data ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "palmr" "kyantech/Palmr"; then
    msg_info "正在停止 Services"
    systemctl stop palmr-frontend palmr-backend
    msg_ok "已停止 Services"

    cp /opt/palmr/apps/server/.env /opt/palmr.env
    rm -rf /opt/palmr
    fetch_and_deploy_gh_release "Palmr" "kyantech/Palmr" "tarball" "latest" "/opt/palmr"

    PNPM="$(jq -r '.packageManager' /opt/palmr/package.json)"
    NODE_VERSION="24" NODE_MODULE="$PNPM" setup_nodejs

    msg_info "正在更新 ${APP}"
    cd /opt/palmr/apps/server
    mv /opt/palmr.env /opt/palmr/apps/server/.env
    $STD pnpm install
    $STD npx prisma generate
    $STD npx prisma migrate deploy
    $STD npx prisma db push
    $STD pnpm build

    cd /opt/palmr/apps/web
    export NODE_ENV=production
    export NEXT_TELEMETRY_DISABLED=1
    mv ./.env.example ./.env
    $STD pnpm install
    $STD pnpm build
    chown -R palmr:palmr /opt/palmr_data /opt/palmr
    msg_ok "Updated ${APP}"

    msg_info "正在启动 Services"
    systemctl start palmr-backend palmr-frontend
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
