#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://wealthfolio.app/

APP="Wealthfolio"
var_tags="${var_tags:-finance;portfolio}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
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

  if [[ ! -d /opt/wealthfolio ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "wealthfolio" "afadil/wealthfolio"; then
    msg_info "正在停止 Service"
    systemctl stop wealthfolio
    msg_ok "已停止 Service"

    msg_info "正在备份 Data"
    cp -r /opt/wealthfolio_data /opt/wealthfolio_data_backup
    cp /opt/wealthfolio/.env /opt/wealthfolio_env_backup
    msg_ok "已备份 Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "wealthfolio" "afadil/wealthfolio" "tarball"

    msg_info "正在构建 Frontend (patience)"
    cd /opt/wealthfolio
    $STD pnpm install --frozen-lockfile
    $STD pnpm tsc
    $STD pnpm vite build
    msg_ok "已构建 Frontend"

    msg_info "正在构建 Backend (patience)"
    cd /opt/wealthfolio/src-server
    source ~/.cargo/env
    $STD cargo build --release --manifest-path Cargo.toml
    cp /opt/wealthfolio/src-server/target/release/wealthfolio-server /usr/local/bin/wealthfolio-server
    chmod +x /usr/local/bin/wealthfolio-server
    msg_ok "已构建 Backend"

    msg_info "正在恢复 Data"
    cp -r /opt/wealthfolio_data_backup/. /opt/wealthfolio_data
    cp /opt/wealthfolio_env_backup /opt/wealthfolio/.env
    rm -rf /opt/wealthfolio_data_backup /opt/wealthfolio_env_backup
    msg_ok "已恢复 Data"

    msg_info "正在清理 Up"
    rm -rf /opt/wealthfolio/src-server/target
    rm -rf /root/.cargo/registry
    rm -rf /opt/wealthfolio/node_modules
    msg_ok "已清理 Up"

    msg_info "正在启动 Service"
    systemctl start wealthfolio
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
