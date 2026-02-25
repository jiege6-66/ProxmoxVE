#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: DragoQC
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://discopanel.app/

APP="DiscoPanel"
var_tags="${var_tags:-gaming}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-15}"
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

  if [[ ! -d "/opt/discopanel" ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  setup_docker

  if check_for_gh_release "discopanel" "nickheyer/discopanel"; then
    msg_info "正在停止 Service"
    systemctl stop discopanel
    msg_ok "已停止 Service"

    msg_info "正在创建 Backup"
    mkdir -p /opt/discopanel_backup_temp
    cp -r /opt/discopanel/data/discopanel.db \
      /opt/discopanel/data/.recovery_key \
      /opt/discopanel_backup_temp/
    if [[ -d /opt/discopanel/data/servers ]]; then
      cp -r /opt/discopanel/data/servers /opt/discopanel_backup_temp/
    fi
    msg_ok "已创建 Backup"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "discopanel" "nickheyer/discopanel" "tarball" "latest" "/opt/discopanel"

    msg_info "正在设置 DiscoPanel"
    cd /opt/discopanel 
    $STD make gen
    cd /opt/discopanel/web/discopanel 
    $STD npm install
    $STD npm run build
    msg_ok "已构建 Web Interface"

    setup_go

    msg_info "正在构建 DiscoPanel"
    cd /opt/discopanel 
    $STD go build -o discopanel cmd/discopanel/main.go
    msg_ok "已构建 DiscoPanel"

    msg_info "正在恢复 Data"
    mkdir -p /opt/discopanel/data
    cp -a /opt/discopanel_backup_temp/. /opt/discopanel/data/
    rm -rf /opt/discopanel_backup_temp
    msg_ok "已恢复 Data"

    msg_info "正在启动 Service"
    systemctl start discopanel
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
