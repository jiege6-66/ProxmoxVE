#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/odoo/odoo

APP="Odoo"
var_tags="${var_tags:-erp}"
var_disk="${var_disk:-6}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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

  if [[ ! -f /etc/odoo/odoo.conf ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  ensure_dependencies python3-lxml
  if ! [[ $(dpkg -s python3-lxml-html-clean 2>/dev/null) ]]; then
    curl -fsSL "http://archive.ubuntu.com/ubuntu/pool/universe/l/lxml-html-clean/python3-lxml-html-clean_0.1.1-1_all.deb" -o /opt/python3-lxml-html-clean.deb
    $STD dpkg -i /opt/python3-lxml-html-clean.deb
    rm -f /opt/python3-lxml-html-clean.deb
  fi

  RELEASE=$(curl -fsSL https://nightly.odoo.com/ | grep -oE 'href="[0-9]+\.[0-9]+/nightly"' | head -n1 | cut -d'"' -f2 | cut -d/ -f1)
  LATEST_VERSION=$(curl -fsSL "https://nightly.odoo.com/${RELEASE}/nightly/deb/" |
    grep -oP "odoo_${RELEASE}\.\d+_all\.deb" |
    sed -E "s/odoo_(${RELEASE}\.[0-9]+)_all\.deb/\1/" |
    sort -V |
    tail -n1)

  if [[ "${LATEST_VERSION}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
    msg_info "正在停止 ${APP} service"
    systemctl stop odoo
    msg_ok "已停止 Service"

    msg_info "正在更新 ${APP} to ${LATEST_VERSION}"
    curl -fsSL https://nightly.odoo.com/${RELEASE}/nightly/deb/odoo_${RELEASE}.latest_all.deb -o /opt/odoo.deb
    $STD apt install -y /opt/odoo.deb
    rm -f /opt/odoo.deb
    echo "$LATEST_VERSION" >/opt/${APP}_version.txt
    msg_ok "Updated ${APP} to ${LATEST_VERSION}"

    msg_info "正在启动 Service"
    systemctl start odoo
    msg_ok "已启动 Service"
    msg_ok "已成功更新!"
  else
    msg_ok "无需更新。 ${APP} is already at ${LATEST_VERSION}"
  fi
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8069${CL}"
