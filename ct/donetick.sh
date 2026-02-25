#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: fstof
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/donetick/donetick

APP="Donetick"
var_tags="${var_tags:-productivity;tasks}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
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

  if [[ ! -d /opt/donetick ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "donetick" "donetick/donetick"; then
    msg_info "正在停止 Service"
    systemctl stop donetick
    msg_ok "已停止 Service"

    msg_info "Backing Up Configurations"
    mv /opt/donetick/config/selfhosted.yaml /opt/donetick/donetick.db /opt
    msg_ok "Backed Up Configurations"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "donetick" "donetick/donetick" "prebuild" "latest" "/opt/donetick" "donetick_Linux_x86_64.tar.gz"

    msg_info "正在恢复 Configurations"
    mv /opt/selfhosted.yaml /opt/donetick/config
    grep -q 'http://localhost"$' /opt/donetick/config/selfhosted.yaml || sed -i '/https:\/\/localhost"$/a\    - "http://localhost"' /opt/donetick/config/selfhosted.yaml
    grep -q 'capacitor://localhost' /opt/donetick/config/selfhosted.yaml || sed -i '/http:\/\/localhost"$/a\    - "capacitor://localhost"' /opt/donetick/config/selfhosted.yaml
    mv /opt/donetick.db /opt/donetick
    msg_ok "已恢复 Configurations"

    msg_info "正在启动 Service"
    systemctl start donetick
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:2021${CL}"
