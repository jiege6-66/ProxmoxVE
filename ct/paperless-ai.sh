#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/clusterzx/paperless-ai

APP="Paperless-AI"
var_tags="${var_tags:-ai;document}"
var_cpu="${var_cpu:-4}"
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
  if [[ ! -d /opt/paperless-ai ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "paperless-ai" "clusterzx/paperless-ai"; then
    msg_info "正在停止 Service"
    systemctl stop paperless-ai paperless-rag
    msg_ok "已停止 Service"

    msg_info "正在备份 data"
    cp -r /opt/paperless-ai/data /opt/paperless-ai-data-backup
    msg_ok "已备份 data"

    fetch_and_deploy_gh_release "paperless-ai" "clusterzx/paperless-ai" "tarball"

    msg_info "正在恢复 data"
    cp -r /opt/paperless-ai-data-backup/* /opt/paperless-ai/data/
    rm -rf /opt/paperless-ai-data-backup
    msg_ok "已恢复 data"

    msg_info "正在更新 Paperless-AI"
    cd /opt/paperless-ai
    if [[ ! -d /opt/paperless-ai/venv ]]; then
      msg_info "Recreating Python venv"
      $STD python3 -m venv /opt/paperless-ai/venv
    fi
    source /opt/paperless-ai/venv/bin/activate
    $STD pip install --upgrade pip
    $STD pip install --no-cache-dir -r requirements.txt
    mkdir -p data/chromadb
    $STD npm ci --only=production
    msg_ok "Updated Paperless-AI"

    msg_info "正在启动 Service"
    systemctl start paperless-rag
    sleep 3
    systemctl start paperless-ai
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
