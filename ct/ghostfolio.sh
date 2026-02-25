#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: lucasfell
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ghostfol.io/

APP="Ghostfolio"
var_tags="${var_tags:-finance;investment}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
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

  if [[ ! -f /opt/ghostfolio/dist/apps/api/main.js ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "ghostfolio" "ghostfolio/ghostfolio"; then
    msg_info "正在停止 Service"
    systemctl stop ghostfolio
    msg_ok "已停止 Service"

    msg_info "正在创建 Backup"
    tar -czf "/opt/ghostfolio_backup_$(date +%F).tar.gz" \
      -C /opt \
      --exclude="ghostfolio/node_modules" \
      --exclude="ghostfolio/dist" \
      ghostfolio
    mv /opt/ghostfolio/.env /opt/env.backup
    msg_ok "Backup 已创建"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "ghostfolio" "ghostfolio/ghostfolio" "tarball" "latest" "/opt/ghostfolio"

    msg_info "正在更新 Ghostfolio"
    mv /opt/env.backup /opt/ghostfolio/.env
    cd /opt/ghostfolio
    $STD npm ci
    $STD npm run build:production
    $STD npx prisma migrate deploy
    msg_ok "Updated Ghostfolio"

    msg_info "正在启动 Service"
    systemctl start ghostfolio
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3333${CL}"
