#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/TwiN/gatus

APP="gatus"
var_tags="${var_tags:-monitoring}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-4}"
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

  if [[ ! -d /opt/gatus ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "gatus" "TwiN/gatus"; then
    msg_info "正在停止 Service"
    systemctl stop gatus
    msg_ok "已停止 Service"

    mv /opt/gatus/config/config.yaml /opt
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "gatus" "TwiN/gatus" "tarball"

    msg_info "正在更新 Gatus"
    cd /opt/gatus
    $STD go mod tidy
    CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o gatus .
    setcap CAP_NET_RAW+ep gatus
    mv /opt/config.yaml config
    msg_ok "Updated Gatus"

    msg_info "正在启动 Service"
    systemctl start gatus
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
