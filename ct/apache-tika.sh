#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Andy Grunwald (andygrunwald)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/apache/tika/

APP="Apache-Tika"
var_tags="${var_tags:-document}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
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
  if [[ ! -f /etc/systemd/system/apache-tika.service ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  RELEASE="$(curl -fsSL https://dlcdn.apache.org/tika/ | grep -oP '(?<=href=")[0-9]+\.[0-9]+\.[0-9]+(?=/")' | sort -V | tail -n1)"
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "正在停止 Service"
    systemctl stop apache-tika
    msg_ok "已停止 Service"

    msg_info "正在更新 ${APP} to v${RELEASE}"
    cd /opt/apache-tika
    curl -fsSL -o tika-server-standard-${RELEASE}.jar "https://dlcdn.apache.org/tika/${RELEASE}/tika-server-standard-${RELEASE}.jar"
    mv --force tika-server-standard.jar tika-server-standard-prev-version.jar
    mv tika-server-standard-${RELEASE}.jar tika-server-standard.jar
    rm -rf /opt/apache-tika/tika-server-standard-prev-version.jar
    echo "${RELEASE}" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP} to v${RELEASE}"

    msg_info "正在启动 Service"
    systemctl start apache-tika
    msg_ok "已启动 Service"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9998${CL}"
