#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster) | Co-Author: remz1337
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/FlareSolverr/FlareSolverr

APP="FlareSolverr"
var_tags="${var_tags:-proxy}"
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

  if [[ ! -f /etc/systemd/system/flaresolverr.service ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if [[ $(grep -E '^VERSION_ID=' /etc/os-release) == *"12"* ]]; then
    msg_error "Wrong Debian version detected!"
    msg_error "You must upgrade your LXC to Debian Trixie before updating."
    exit
  fi
  if check_for_gh_release "flaresolverr" "FlareSolverr/FlareSolverr"; then
    msg_info "正在停止 service"
    systemctl stop flaresolverr
    msg_ok "已停止 service"

    rm -rf /opt/flaresolverr
    fetch_and_deploy_gh_release "flaresolverr" "FlareSolverr/FlareSolverr" "prebuild" "latest" "/opt/flaresolverr" "flaresolverr_linux_x64.tar.gz"

    msg_info "正在启动 service"
    systemctl start flaresolverr
    msg_ok "已启动 service"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8191${CL}"
