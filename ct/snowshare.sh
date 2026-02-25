#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: TuroYT
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/TuroYT/snowshare

APP="SnowShare"
var_tags="${var_tags:-file-sharing}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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
  if [[ ! -d /opt/snowshare ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "snowshare" "TuroYT/snowshare"; then
    msg_info "正在停止 Service"
    systemctl stop snowshare
    msg_ok "已停止 Service"

    msg_info "正在备份 uploads"
    [ -d /opt/snowshare/uploads ] && cp -a /opt/snowshare/uploads /opt/.snowshare_uploads_backup
    msg_ok "Uploads backed up"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "snowshare" "TuroYT/snowshare" "tarball"

    msg_info "正在恢复 uploads"
    [ -d /opt/.snowshare_uploads_backup ] && rm -rf /opt/snowshare/uploads && cp -a /opt/.snowshare_uploads_backup /opt/snowshare/uploads
    msg_ok "Uploads restored"

    msg_info "正在更新 Snowshare"
    cd /opt/snowshare
    $STD npm ci
    $STD npx prisma generate
    $STD npm run build
    msg_ok "Updated Snowshare"

    msg_info "正在启动 Service"
    systemctl start snowshare
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
