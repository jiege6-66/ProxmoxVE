#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.commafeed.com/#/welcome

APP="CommaFeed"
var_tags="${var_tags:-rss-reader}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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

  if [[ ! -d /opt/commafeed ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  JAVA_VERSION="25" setup_java
  if check_for_gh_release "commafeed" "Athou/commafeed"; then
    msg_info "正在停止 Service"
    systemctl stop commafeed
    msg_ok "已停止 Service"

    ensure_dependencies rsync

    if [ -d /opt/commafeed/data ] && [ "$(ls -A /opt/commafeed/data)" ]; then
      msg_info "正在备份 existing data"
      mv /opt/commafeed/data /opt/data.bak
      msg_ok "已备份 existing data"
    fi

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "commafeed" "Athou/commafeed" "prebuild" "latest" "/opt/commafeed" "commafeed-*-h2-jvm.zip"

    if [ -d /opt/data.bak ] && [ "$(ls -A /opt/data.bak)" ]; then
      msg_info "正在恢复 data"
      mv /opt/data.bak /opt/commafeed/data
      msg_ok "已恢复 data"
    fi

    msg_info "正在启动 Service"
    systemctl start commafeed
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8082${CL}"
