#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://cronicle.net/

APP="Cronicle"
var_tags="${var_tags:-task-scheduler}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
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
  UPD=$(msg_menu "Cronicle Update Options" \
    "1" "Update ${APP}" \
    "2" "Install ${APP} Worker")

  if [ "$UPD" == "1" ]; then
    if [[ ! -d /opt/cronicle ]]; then
      msg_error "未找到 ${APP} 安装！"
      exit
    fi
    NODE_VERSION="22" setup_nodejs

    msg_info "正在更新 Cronicle"
    $STD /opt/cronicle/bin/control.sh upgrade
    msg_ok "Updated Cronicle"
    exit
  fi
  if [ "$UPD" == "2" ]; then
    NODE_VERSION="22" setup_nodejs
    if check_for_gh_release "cronicle" "jhuckaby/Cronicle"; then
      msg_info "正在安装依赖"
      ensure_dependencies git build-essential ca-certificates
      msg_ok "已安装依赖"

      NODE_VERSION="22" setup_nodejs
      fetch_and_deploy_gh_release "cronicle" "jhuckaby/Cronicle" "tarball"

      msg_info "正在配置 Cronicle Worker"
      cd /opt/cronicle
      $STD npm install
      $STD node bin/build.js dist
      sed -i "s/localhost:3012/${LOCAL_IP}:3012/g" /opt/cronicle/conf/config.json
      $STD /opt/cronicle/bin/control.sh start
      msg_ok "已安装 Cronicle Worker"
      echo -e "\n Add Masters secret key to /opt/cronicle/conf/config.json \n"
      msg_ok "已成功更新!"
      exit
    fi
  fi
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3012${CL}"
