#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/plankanban/planka

APP="PLANKA"
var_tags="${var_tags:-Todo;kanban}"
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

  if [[ ! -f /etc/systemd/system/planka.service ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "planka" "plankanban/planka"; then
    msg_info "正在停止 Service"
    systemctl stop planka
    msg_ok "已停止 Service"

    msg_info "正在备份 data"
    BK="/opt/planka-backup"
    mkdir -p "$BK"/{favicons,user-avatars,background-images,attachments}
    [ -f /opt/planka/.env ] && mv /opt/planka/.env "$BK"/
    # Support both old (pre-v2) and new (v2) directory layouts
    if [ -d /opt/planka/data/protected ]; then
      [ -d /opt/planka/data/protected/favicons ] && cp -a /opt/planka/data/protected/favicons/. "$BK/favicons/"
      [ -d /opt/planka/data/protected/user-avatars ] && cp -a /opt/planka/data/protected/user-avatars/. "$BK/user-avatars/"
      [ -d /opt/planka/data/protected/background-images ] && cp -a /opt/planka/data/protected/background-images/. "$BK/background-images/"
      [ -d /opt/planka/data/private/attachments ] && cp -a /opt/planka/data/private/attachments/. "$BK/attachments/"
    else
      [ -d /opt/planka/public/favicons ] && cp -a /opt/planka/public/favicons/. "$BK/favicons/"
      [ -d /opt/planka/public/user-avatars ] && cp -a /opt/planka/public/user-avatars/. "$BK/user-avatars/"
      [ -d /opt/planka/public/background-images ] && cp -a /opt/planka/public/background-images/. "$BK/background-images/"
      [ -d /opt/planka/private/attachments ] && cp -a /opt/planka/private/attachments/. "$BK/attachments/"
    fi
    rm -rf /opt/planka
    msg_ok "已备份 data"

    fetch_and_deploy_gh_release "planka" "plankanban/planka" "prebuild" "latest" "/opt/planka" "planka-prebuild.zip"

    msg_info "Update Frontend"
    cd /opt/planka
    $STD npm install
    msg_ok "Updated Frontend"

    msg_info "正在恢复 data"
    [ -f "$BK/.env" ] && mv "$BK/.env" /opt/planka/.env
    # Planka v2 uses unified data directory structure
    mkdir -p /opt/planka/data/protected/{favicons,user-avatars,background-images} /opt/planka/data/private/attachments
    [ -d "$BK/favicons" ] && cp -a "$BK/favicons/." /opt/planka/data/protected/favicons/
    [ -d "$BK/user-avatars" ] && cp -a "$BK/user-avatars/." /opt/planka/data/protected/user-avatars/
    [ -d "$BK/background-images" ] && cp -a "$BK/background-images/." /opt/planka/data/protected/background-images/
    [ -d "$BK/attachments" ] && cp -a "$BK/attachments/." /opt/planka/data/private/attachments/
    rm -rf "$BK"
    msg_ok "已恢复 data"

    msg_info "Migrate Database"
    cd /opt/planka
    $STD npm run db:upgrade
    $STD npm run db:migrate
    msg_ok "已迁移 Database"

    msg_info "正在启动 Service"
    systemctl start planka
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:1337${CL}"
