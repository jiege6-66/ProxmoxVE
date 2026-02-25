#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://gitlab.com/crafty-controller/crafty-4

APP="Crafty-Controller"
var_tags="${var_tags:-gaming}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-16}"
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
  if [[ ! -d /opt/crafty-controller ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  RELEASE=$(curl -fsSL "https://gitlab.com/api/v4/projects/20430749/releases" | grep -o '"tag_name":"v[^"]*"' | head -n 1 | sed 's/"tag_name":"v//;s/"//')
  if [[ ! -f /opt/crafty-controller_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/crafty-controller_version.txt)" ]]; then

    msg_info "正在停止 Crafty-Controller"
    systemctl stop crafty-controller
    msg_ok "已停止 Crafty-Controller"

    msg_info "正在创建 Backup of config"
    cp -a /opt/crafty-controller/crafty/crafty-4/app/config/. /opt/crafty-controller/backup
    rm /opt/crafty-controller/backup/version.json
    rm /opt/crafty-controller/backup/credits.json
    rm /opt/crafty-controller/backup/logging.json
    rm /opt/crafty-controller/backup/default.json.example
    rm /opt/crafty-controller/backup/motd_format.json
    msg_ok "Backup 已创建"

    msg_info "正在更新 Crafty-Controller to v${RELEASE}"
    curl -fsSL "https://gitlab.com/crafty-controller/crafty-4/-/archive/v${RELEASE}/crafty-4-v${RELEASE}.zip" -o $(basename "https://gitlab.com/crafty-controller/crafty-4/-/archive/v${RELEASE}/crafty-4-v${RELEASE}.zip")
    $STD unzip crafty-4-v"${RELEASE}".zip
    cp -a crafty-4-v"${RELEASE}"/. /opt/crafty-controller/crafty/crafty-4/
    rm -rf crafty-4-v"${RELEASE}"
    cd /opt/crafty-controller/crafty/crafty-4
    sudo -u crafty bash -c '
        source /opt/crafty-controller/crafty/.venv/bin/activate
        pip3 install --no-cache-dir -r requirements.txt
      ' &>/dev/null
    echo "${RELEASE}" >"/opt/crafty-controller_version.txt"
    msg_ok "Updated Crafty-Controller to v${RELEASE}"

    msg_info "正在恢复 Backup of config"
    cp -a /opt/crafty-controller/backup/. /opt/crafty-controller/crafty/crafty-4/app/config
    rm -rf /opt/crafty-controller/backup
    chown -R crafty:crafty /opt/crafty-controller/
    msg_ok "Backup 已恢复"

    msg_info "正在启动 Crafty-Controller"
    systemctl start crafty-controller
    msg_ok "已启动 Crafty-Controller"

    msg_ok "已成功更新!"
  else
    msg_ok "无需更新。 ${APP} is already at v${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}:8443${CL}"
