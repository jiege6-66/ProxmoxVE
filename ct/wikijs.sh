#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://js.wiki/

APP="Wikijs"
var_tags="${var_tags:-wiki}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
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
  if [[ ! -d /opt/wikijs ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  NODE_VERSION="22" NODE_MODULE="yarn,node-gyp" setup_nodejs

  if check_for_gh_release "wikijs" "requarks/wiki"; then
    msg_info "正在验证 whether ${APP}' new release is v3.x+ and current install uses SQLite."
    SQLITE_INSTALL=$([ -f /opt/wikijs/db.sqlite ] && echo "true" || echo "false")
    if [[ "${SQLITE_INSTALL}" == "true" && "${CHECK_UPDATE_RELEASE}" =~ ^3.* ]]; then
      echo "SQLite is not supported in v3.x+, currently there is no update path availble."
      exit
    fi
    msg_ok "There is an update path available for ${APP}"

    msg_info "正在停止 Service"
    systemctl stop wikijs
    msg_ok "已停止 Service"

    msg_info "正在备份 Data"
    mkdir /opt/wikijs-backup
    $SQLITE_INSTALL && cp /opt/wikijs/db.sqlite /opt/wikijs-backup
    cp -R /opt/wikijs/{config.yml,/data} /opt/wikijs-backup
    msg_ok "已备份 Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "wikijs" "requarks/wiki" "prebuild" "latest" "/opt/wikijs" "wiki-js.tar.gz"

    msg_info "正在恢复 Data"
    cp -R /opt/wikijs-backup/* /opt/wikijs
    $SQLITE_INSTALL && $STD npm rebuild sqlite3
    rm -rf /opt/wikijs-backup
    msg_ok "已恢复 Data"

    msg_info "正在启动 Service"
    systemctl start wikijs
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
