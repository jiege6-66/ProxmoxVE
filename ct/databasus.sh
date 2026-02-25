#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/databasus/databasus

APP="Databasus"
var_tags="${var_tags:-backup;postgresql;database}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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

  if [[ ! -f /opt/databasus/databasus ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "databasus" "databasus/databasus"; then
    msg_info "正在停止 Databasus"
    $STD systemctl stop databasus
    msg_ok "已停止 Databasus"

    msg_info "正在备份 Configuration"
    cp /opt/databasus/.env /opt/databasus.env.bak
    msg_ok "已备份 Configuration"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "databasus" "databasus/databasus" "tarball" "latest" "/opt/databasus"

    msg_info "正在更新 Databasus"
    cd /opt/databasus/frontend
    $STD npm ci
    $STD npm run build
    cd /opt/databasus/backend
    $STD go mod download
    $STD /root/go/bin/swag init -g cmd/main.go -o swagger
    $STD env CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o databasus ./cmd/main.go
    mv /opt/databasus/backend/databasus /opt/databasus/databasus
    cp -r /opt/databasus/frontend/dist/* /opt/databasus/ui/build/
    cp -r /opt/databasus/backend/migrations /opt/databasus/
    chown -R postgres:postgres /opt/databasus
    msg_ok "Updated Databasus"

    msg_info "正在恢复 Configuration"
    cp /opt/databasus.env.bak /opt/databasus/.env
    rm -f /opt/databasus.env.bak
    chown postgres:postgres /opt/databasus/.env
    msg_ok "已恢复 Configuration"

    msg_info "正在启动 Databasus"
    $STD systemctl start databasus
    msg_ok "已启动 Databasus"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
