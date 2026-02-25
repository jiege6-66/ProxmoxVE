#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck | Co-Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.rabbitmq.com/

APP="RabbitMQ"
var_tags="${var_tags:-mqtt}"
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
  if [[ ! -d /etc/rabbitmq ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if grep -q "dl.cloudsmith.io" /etc/apt/sources.list.d/rabbitmq.list; then
    rm -f /etc/apt/sources.list.d/rabbitmq.list
    setup_deb822_repo \
      "rabbitmq" \
      "https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA" \
      "https://deb1.rabbitmq.com/rabbitmq-server/debian/trixie" \
      "trixie"
  fi

  msg_info "正在停止 Service"
  systemctl stop rabbitmq-server
  msg_ok "已停止 Service"

  msg_info "正在更新..."
  $STD apt install --only-upgrade rabbitmq-server
  msg_ok "已成功更新!"

  msg_info "正在启动 Service"
  systemctl start rabbitmq-server
  msg_ok "已启动 Service"
  msg_ok "已成功更新!"
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:15672${CL}"
