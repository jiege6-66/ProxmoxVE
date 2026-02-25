#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: JasonGreenC
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/thecfu/scraparr

APP="Scraparr"
var_tags="${var_tags:-arr;monitoring}"
var_cpu="${var_cpu:-2}"
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

  if [[ ! -d /opt/scraparr/ ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "scraparr" "thecfu/scraparr"; then
    msg_info "正在停止 Services"
    systemctl stop scraparr
    msg_ok "Services 已停止"

    PYTHON_VERSION="3.12" setup_uv
    fetch_and_deploy_gh_release "scrappar" "thecfu/scraparr" "tarball" "latest" "/opt/scraparr"

    msg_info "正在更新 Scraparr"
    cd /opt/scraparr
    $STD uv venv --clear /opt/scraparr/.venv
    $STD /opt/scraparr/.venv/bin/python -m ensurepip --upgrade
    $STD /opt/scraparr/.venv/bin/python -m pip install --upgrade pip
    $STD /opt/scraparr/.venv/bin/python -m pip install -r /opt/scraparr/src/scraparr/requirements.txt
    chmod -R 755 /opt/scraparr
    msg_ok "Updated Scraparr"

    msg_info "正在启动 Services"
    systemctl start scraparr
    msg_ok "Services 已启动"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:7100${CL}"
