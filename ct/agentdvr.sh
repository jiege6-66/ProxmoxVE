#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.ispyconnect.com/

APP="AgentDVR"
var_tags="${var_tags:-dvr}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_unprivileged="${var_unprivileged:-0}"
var_gpu="${var_gpu:-yes}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /opt/agentdvr ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  RELEASE=$(curl -fsSL "https://www.ispyconnect.com/api/Agent/DownloadLocation4?platform=Linux64&fromVersion=0" | grep -o 'https://.*\.zip')
  if [[ "${RELEASE}" != "$(cat ~/.agentdvr 2>/dev/null)" ]] || [[ ! -f ~/.agentdvr ]]; then
    msg_info "正在停止 service"
    systemctl stop AgentDVR
    msg_ok "Service stopped"

    msg_info "正在更新 AgentDVR"
    cd /opt/agentdvr/agent
    curl -fsSL "$RELEASE" -o $(basename "$RELEASE")
    $STD unzip -o Agent_Linux64*.zip
    chmod +x ./Agent
    echo $RELEASE >~/.agentdvr
    rm -rf Agent_Linux64*.zip
    msg_ok "Updated AgentDVR"

    msg_info "正在启动 service"
    systemctl start AgentDVR
    msg_ok "Service started"
    msg_ok "已成功更新!"
  else
    msg_ok "无需更新。 ${APP} is already at ${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8090${CL}"
