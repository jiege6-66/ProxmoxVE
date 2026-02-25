#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://www.bunkerweb.io/

APP="BunkerWeb"
var_tags="${var_tags:-webserver}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-8192}"
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
  if [[ ! -d /etc/bunkerweb ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "bunkerweb" "bunkerity/bunkerweb"; then
    msg_info "正在更新 BunkerWeb"
    RELEASE=$(get_latest_github_release "bunkerity/bunkerweb")
    cat <<EOF >/etc/apt/preferences.d/bunkerweb
Package: bunkerweb
Pin: version ${RELEASE}
Pin-Priority: 1001
EOF
    $STD apt update
    $STD apt-mark unhold bunkerweb nginx
    $STD apt install -y --allow-downgrades bunkerweb="${RELEASE}"
    msg_ok "Updated BunkerWeb"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}/setup${CL}"
