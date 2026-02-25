#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Joseph Stubberfield (stubbers)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/librespeed/speedtest-rust

APP="Librespeed-Rust"
var_tags="${var_tags:-network}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
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
  if [[ ! -d /var/lib/librespeed-rs ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "librespeed-rust" "librespeed/speedtest-rust"; then
    msg_info "正在停止 Services"
    systemctl stop speedtest_rs
    msg_ok "Services 已停止"

    fetch_and_deploy_gh_release "librespeed-rust" "librespeed/speedtest-rust" "binary" "latest" "/opt/librespeed-rust" "librespeed-rs-x86_64-unknown-linux-gnu.deb"

    msg_info "正在启动 Service"
    systemctl start speedtest_rs
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
