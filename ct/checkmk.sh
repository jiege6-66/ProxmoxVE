#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Michel Roegl-Brunner (michelroegl-brunner)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://checkmk.com/

APP="checkmk"
var_tags="${var_tags:-monitoring}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /opt/checkmk_version.txt ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  RELEASE=$(curl -fsSL https://api.github.com/repos/checkmk/checkmk/tags | grep "name" | awk '{print substr($2, 3, length($2)-4) }' | tr ' ' '\n' | grep -Ev 'rc|b' | sort -V | tail -n 1)
  msg_info "正在更新 ${APP} to v${RELEASE}"
  $STD omd stop monitoring
  $STD omd cp monitoring monitoringbackup
  curl -fsSL "https://download.checkmk.com/checkmk/${RELEASE}/check-mk-raw-${RELEASE}_0.bookworm_amd64.deb" -o "/opt/checkmk.deb"
  $STD apt-get install -y /opt/checkmk.deb
  $STD omd --force -V ${RELEASE}.cre update --conflict=install monitoring
  $STD omd start monitoring
  $STD omd -f rm monitoringbackup
  $STD omd cleanup
  rm -rf /opt/checkmk.deb
  msg_ok "Updated ${APP}"
  msg_ok "已成功更新!"

  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}/monitoring${CL}"
