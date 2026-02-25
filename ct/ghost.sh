#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: fabrice1236
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://ghost.org/

APP="Ghost"
var_tags="${var_tags:-cms;blog}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-5}"
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

  setup_mariadb
  NODE_VERSION="22" setup_nodejs
  ensure_dependencies git

  msg_info "正在更新 Ghost"
  if command -v ghost &>/dev/null; then
    current_version=$(ghost version | grep 'Ghost-CLI version' | awk '{print $3}')
    latest_version=$(npm show ghost-cli version)
    if [ "$current_version" != "$latest_version" ]; then
      msg_info "正在更新 ${APP} from version v${current_version} to v${latest_version}"
      $STD npm install -g ghost-cli@latest
      msg_ok "已成功更新!"
    else
      msg_ok "${APP} is already at v${current_version}"
    fi
  else
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:2368${CL}"
