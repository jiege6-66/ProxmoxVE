#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://ombi.io/

APP="Ombi"
var_tags="${var_tags:-media}"
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
  if [[ ! -d /opt/ombi ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "ombi" "Ombi-app/Ombi"; then
    msg_info "正在停止 Service"
    systemctl stop ombi
    msg_ok "已停止 Service"

    msg_info "正在创建 backup"
    [[ -f /opt/ombi/Ombi.db ]] && mv /opt/ombi/Ombi.db /opt
    [[ -f /opt/ombi/OmbiExternal.db ]] && mv /opt/ombi/OmbiExternal.db /opt
    [[ -f /opt/ombi/OmbiSettings.db ]] && mv /opt/ombi/OmbiSettings.db /opt
    msg_ok "Backup created"

    rm -rf /opt/ombi
    fetch_and_deploy_gh_release "ombi" "Ombi-app/Ombi" "prebuild" "latest" "/opt/ombi" "linux-x64.tar.gz"
    [[ -f /opt/Ombi.db ]] && mv /opt/Ombi.db /opt/ombi
    [[ -f /opt/OmbiExternal.db ]] && mv /opt/OmbiExternal.db /opt/ombi
    [[ -f /opt/OmbiSettings.db ]] && mv /opt/OmbiSettings.db /opt/ombi

    msg_info "正在启动 Service"
    systemctl start ombi
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5000${CL}"
