#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://tautulli.com/

APP="Tautulli"
var_tags="${var_tags:-media}"
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
  if [[ ! -d /opt/Tautulli/ ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "Tautulli" "Tautulli/Tautulli"; then
    PYTHON_VERSION="3.13" setup_uv

    msg_info "正在停止 Service"
    systemctl stop tautulli
    msg_ok "已停止 Service"

    msg_info "正在备份 config and database"
    cp /opt/Tautulli/config.ini /opt/tautulli_config.ini.backup
    cp /opt/Tautulli/tautulli.db /opt/tautulli.db.backup
    msg_ok "已备份 config and database"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Tautulli" "Tautulli/Tautulli" "tarball"

    msg_info "正在更新 Tautulli"
    cd /opt/Tautulli
    TAUTULLI_VERSION=$(get_latest_github_release "Tautulli/Tautulli" "false")
    echo "${TAUTULLI_VERSION}" >/opt/Tautulli/version.txt
    echo "master" >/opt/Tautulli/branch.txt
    $STD uv venv -c
    $STD source /opt/Tautulli/.venv/bin/activate
    $STD uv pip install -r requirements.txt
    $STD uv pip install pyopenssl
    msg_ok "Updated Tautulli"

    msg_info "正在恢复 config and database"
    cp /opt/tautulli_config.ini.backup /opt/Tautulli/config.ini
    cp /opt/tautulli.db.backup /opt/Tautulli/tautulli.db
    rm -f /opt/{tautulli_config.ini.backup,tautulli.db.backup}
    msg_ok "已恢复 config and database"

    msg_info "正在启动 Service"
    systemctl start tautulli
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8181${CL}"
