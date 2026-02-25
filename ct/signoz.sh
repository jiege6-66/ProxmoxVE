#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://signoz.io/

APP="SigNoz"
var_tags="${var_tags:-notes}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
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
  if [[ ! -d /opt/signoz ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "signoz" "SigNoz/signoz"; then
    msg_info "正在停止 Services"
    systemctl stop signoz
    systemctl stop signoz-otel-collector
    msg_ok "已停止 Services"

    fetch_and_deploy_gh_release "signoz" "SigNoz/signoz" "prebuild" "latest" "/opt/signoz" "signoz-community_linux_amd64.tar.gz"
    fetch_and_deploy_gh_release "signoz-otel-collector" "SigNoz/signoz-otel-collector" "prebuild" "latest" "/opt/signoz-otel-collector" "signoz-otel-collector_linux_amd64.tar.gz"
    fetch_and_deploy_gh_release "signoz-schema-migrator" "SigNoz/signoz-otel-collector" "prebuild" "latest" "/opt/signoz-schema-migrator" "signoz-schema-migrator_linux_amd64.tar.gz"

    msg_info "正在更新 SigNoz"
    cd /opt/signoz-schema-migrator/bin 
    $STD ./signoz-schema-migrator sync --dsn="tcp://localhost:9000?password=" --replication=true --up=
    $STD ./signoz-schema-migrator async --dsn="tcp://localhost:9000?password=" --replication=true --up=
    msg_ok "Updated SigNoz"

    msg_info "正在启动 Services"
    systemctl start signoz-otel-collector
    systemctl start signoz
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
