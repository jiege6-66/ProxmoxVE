#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://nodered.org/

APP="Node-Red"
var_tags="${var_tags:-automation}"
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
  if [[ ! -d /root/.node-red ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  UPD=$(msg_menu "Node-Red Update Options" \
    "1" "Update ${APP}" \
    "2" "Install Themes")
  if [ "$UPD" == "1" ]; then
    NODE_VERSION="22" setup_nodejs

    msg_info "正在停止 Service"
    systemctl stop nodered
    msg_ok "已停止 Service"

    msg_info "正在更新 Node-Red"
    $STD npm install -g --unsafe-perm node-red
    msg_ok "Updated Node-Red"

    msg_info "正在启动 Service"
    systemctl start nodered
    msg_ok "已启动 Service"
    msg_ok "已成功更新!"
    exit
  fi
  if [ "$UPD" == "2" ]; then
    THEME=$(msg_menu "Node-Red Themes" \
      "midnight-red" "Midnight Red (default)" \
      "aurora" "Aurora" \
      "cobalt2" "Cobalt2" \
      "dark" "Dark" \
      "dracula" "Dracula" \
      "espresso-libre" "Espresso Libre" \
      "github-dark" "GitHub Dark" \
      "github-dark-default" "GitHub Dark Default" \
      "github-dark-dimmed" "GitHub Dark Dimmed" \
      "monoindustrial" "Monoindustrial" \
      "monokai" "Monokai" \
      "monokai-dimmed" "Monokai Dimmed" \
      "noctis" "Noctis" \
      "oceanic-next" "Oceanic Next" \
      "oled" "OLED" \
      "one-dark-pro" "One Dark Pro" \
      "one-dark-pro-darker" "One Dark Pro Darker" \
      "solarized-dark" "Solarized Dark" \
      "solarized-light" "Solarized Light" \
      "tokyo-night" "Tokyo Night" \
      "tokyo-night-light" "Tokyo Night Light" \
      "tokyo-night-storm" "Tokyo Night Storm" \
      "totallyinformation" "TotallyInformation" \
      "zenburn" "Zenburn")
    header_info
    msg_info "正在安装 ${THEME} Theme"
    cd /root/.node-red
    sed -i 's|// theme: ".*",|theme: "",|g' /root/.node-red/settings.js
    $STD npm install @node-red-contrib-themes/theme-collection
    sed -i "{s/theme: ".*"/theme: '${THEME}',/g}" /root/.node-red/settings.js
    systemctl restart nodered
    msg_ok "已安装 ${THEME} Theme"
    exit
  fi
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:1880${CL}"
