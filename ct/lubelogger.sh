#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: kristocopani
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://lubelogger.com/

APP="LubeLogger"
var_tags="${var_tags:-vehicle;car}"
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
  if [[ ! -f /etc/systemd/system/lubelogger.service ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "lubelogger" "hargata/lubelog"; then
    msg_info "正在停止 Service"
    systemctl stop lubelogger
    msg_ok "已停止 Service"

    msg_info "正在备份 data"
    mkdir -p /tmp/lubeloggerData/data
    cp /opt/lubelogger/appsettings.json /tmp/lubeloggerData/appsettings.json
    cp -r /opt/lubelogger/data/ /tmp/lubeloggerData/

    # Lubelogger has moved multiples folders to the 'data' folder, and we need to move them before the update to keep the user data
    # Github Discussion: https://github.com/hargata/lubelog/discussions/787
    [[ -e /opt/lubelogger/config ]] && cp -r /opt/lubelogger/config /tmp/lubeloggerData/data/
    [[ -e /opt/lubelogger/wwwroot/translations ]] && cp -r /opt/lubelogger/wwwroot/translations /tmp/lubeloggerData/data/
    [[ -e /opt/lubelogger/wwwroot/documents ]] && cp -r /opt/lubelogger/wwwroot/documents /tmp/lubeloggerData/data/
    [[ -e /opt/lubelogger/wwwroot/images ]] && cp -r /opt/lubelogger/wwwroot/images /tmp/lubeloggerData/data/
    [[ -e /opt/lubelogger/wwwroot/temp ]] && cp -r /opt/lubelogger/wwwroot/temp /tmp/lubeloggerData/data/
    [[ -e /opt/lubelogger/log ]] && cp -r /opt/lubelogger/log /tmp/lubeloggerData/
    rm -rf /opt/lubelogger
    msg_ok "已备份 data"

    fetch_and_deploy_gh_release "lubelogger" "hargata/lubelog" "prebuild" "latest" "/opt/lubelogger" "LubeLogger*linux_x64.zip"

    msg_info "正在配置 LubeLogger"
    chmod 700 /opt/lubelogger/CarCareTracker
    cp -rf /tmp/lubeloggerData/* /opt/lubelogger/
    rm -rf /tmp/lubeloggerData
    msg_ok "已配置 LubeLogger"

    msg_info "正在启动 Service"
    systemctl start lubelogger
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
