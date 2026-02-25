#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.drawio.com/

APP="DrawIO"
var_tags="${var_tags:-diagrams}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-2048}"
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
  if [[ ! -f /var/lib/tomcat11/webapps/draw.war ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "drawio" "jgraph/drawio"; then
    msg_info "正在停止 service"
    systemctl stop tomcat11
    msg_ok "Service stopped"

    msg_info "正在更新 Debian LXC"
    $STD apt update
    $STD apt upgrade -y
    msg_ok "Updated Debian LXC"

    USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "drawio" "jgraph/drawio" "singlefile" "latest" "/var/lib/tomcat11/webapps" "draw.war"

    msg_info "正在启动 service"
    systemctl start tomcat11
    msg_ok "Service started"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080/draw${CL}"
