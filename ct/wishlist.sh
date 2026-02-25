#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Dunky13
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/cmintey/wishlist

APP="Wishlist"
var_tags="${var_tags:-sharing}"
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
  if [[ ! -d /opt/wishlist ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "wishlist" "cmintey/wishlist"; then
    NODE_VERSION="24" NODE_MODULE="pnpm" setup_nodejs

    msg_info "正在停止 Service"
    systemctl stop wishlist
    msg_ok "已停止 Service"

    msg_info "正在创建 Backup"
    mkdir -p /opt/wishlist-backup
    cp /opt/wishlist/.env /opt/wishlist-backup/.env
    cp -a /opt/wishlist/uploads /opt/wishlist-backup
    cp -a /opt/wishlist/data /opt/wishlist-backup
    msg_ok "已创建 Backup"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "wishlist" "cmintey/wishlist" "tarball"
    LATEST_APP_VERSION=$(get_latest_github_release "cmintey/wishlist")

    msg_info "正在更新 Wishlist"
    cd /opt/wishlist
    $STD pnpm install
    $STD pnpm svelte-kit sync
    $STD pnpm prisma generate
    sed -i 's|/usr/src/app/|/opt/wishlist/|g' $(grep -rl '/usr/src/app/' /opt/wishlist)
    export VERSION="v${LATEST_APP_VERSION}"
    export SHA="v${LATEST_APP_VERSION}"
    $STD pnpm run build
    $STD pnpm prune --prod
    chmod +x /opt/wishlist/entrypoint.sh

    msg_info "正在恢复 Backup"
    cp /opt/wishlist-backup/.env /opt/wishlist/.env
    cp -a /opt/wishlist-backup/uploads /opt/wishlist
    cp -a /opt/wishlist-backup/data /opt/wishlist
    rm -rf /opt/wishlist-backup
    msg_ok "已恢复 Backup"
    
    msg_ok "Updated Wishlist"
    msg_info "正在启动 Service"
    systemctl start wishlist
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3280${CL}"
