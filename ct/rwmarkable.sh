#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/fccview/rwMarkable

APP="rwMarkable"
var_tags="${var_tags:-tasks;notes}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-3072}"
var_disk="${var_disk:-6}"
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

  if [[ ! -d /opt/rwmarkable ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  msg_info "正在停止 service"
  systemctl -q disable --now rwmarkable
  msg_ok "已停止 Service"

  NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs
  CLEAN_INSTALL=1 fetch_and_deploy_gh_release "jotty" "fccview/jotty" "tarball" "latest" "/opt/jotty"

  msg_info "正在更新 app"
  cd /opt/jotty
  $STD yarn --frozen-lockfile
  $STD yarn next telemetry disable
  $STD yarn build
  msg_ok "Updated app"

  msg_info "正在迁移 configuration & data"
  cp /opt/rwmarkable/.env /opt/jotty/.env
  mkdir -p /opt/jotty/data
  cp -r /opt/rwmarkable/data/* /opt/jotty/data
  cp -r /opt/rwmarkable/config/* /opt/jotty/config
  msg_ok "已迁移 configuration & data"

  msg_info "Patching systemd service file"
  sed -i 's/rw[M|m]arkable/jotty/g' /etc/systemd/system/rwmarkable.service
  mv /etc/systemd/system/rwmarkable.service /etc/systemd/system/jotty.service
  systemctl daemon-reload
  msg_ok "Patched systemd service file"

  msg_info "Patching update script"
  sed -i 's/rwmarkable/jotty/g' /usr/bin/update
  msg_ok "Patched update script"

  msg_info "正在启动 jotty service"
  systemctl -q enable --now jotty
  msg_ok "已启动 jotty service"
  msg_ok "已迁移 Successfully!"
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
