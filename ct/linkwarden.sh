#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://linkwarden.app/

APP="Linkwarden"
var_tags="${var_tags:-bookmark}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-12}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/linkwarden ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "linkwarden" "linkwarden/linkwarden"; then
    NODE_VERSION="22" NODE_MODULE="yarn@latest" setup_nodejs
    msg_info "正在停止 Service"
    systemctl stop linkwarden
    msg_ok "已停止 Service"

    RUST_CRATES="monolith" setup_rust

    msg_info "正在备份 data"
    mv /opt/linkwarden/.env /opt/.env
    [ -d /opt/linkwarden/data ] && mv /opt/linkwarden/data /opt/data.bak
    rm -rf /opt/linkwarden
    msg_ok "已备份 data"

    fetch_and_deploy_gh_release "linkwarden" "linkwarden/linkwarden" "tarball"

    msg_info "正在更新 Linkwarden"
    cd /opt/linkwarden
    yarn_ver="4.12.0"
    if [[ -f package.json ]]; then
      pkg_manager=$(jq -r '.packageManager // empty' package.json 2>/dev/null || true)
      if [[ -n "$pkg_manager" && "$pkg_manager" == yarn@* ]]; then
        yarn_spec="${pkg_manager#yarn@}"
        yarn_ver="${yarn_spec%%+*}"
      fi
    fi
    if command -v corepack >/dev/null 2>&1; then
      $STD corepack enable
      $STD corepack prepare "yarn@${yarn_ver}" --activate || true
    fi
    $STD yarn
    $STD npx playwright install-deps
    $STD npx playwright install
    mv /opt/.env /opt/linkwarden/.env
    $STD yarn prisma:generate
    $STD yarn web:build
    $STD yarn prisma:deploy
    [ -d /opt/data.bak ] && mv /opt/data.bak /opt/linkwarden/data
    rm -rf ~/.cargo/registry ~/.cargo/git ~/.cargo/.package-cache
    rm -rf /root/.cache/yarn
    rm -rf /opt/linkwarden/.next/cache
    msg_ok "Updated Linkwarden"

    msg_info "正在启动 Service"
    systemctl start linkwarden
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
