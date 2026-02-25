#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: kristocopani
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://onedev.io/

APP="OneDev"
var_tags="${var_tags:-git}"
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

  if [[ ! -f /etc/systemd/system/onedev.service ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "onedev" "theonedev/onedev"; then
    JAVA_VERSION="21" setup_java

    msg_info "正在停止 Service"
    systemctl stop onedev
    msg_ok "已停止 Service"

    msg_info "正在更新 OneDev"
    cd /opt
    curl -fsSL "https://code.onedev.io/onedev/server/~site/onedev-latest.tar.gz" -o onedev-latest.tar.gz
    tar -xzf onedev-latest.tar.gz
    $STD /opt/onedev-latest/bin/upgrade.sh /opt/onedev
    rm -rf /opt/onedev-latest
    rm -rf /opt/onedev-latest.tar.gz
    echo "${CHECK_UPDATE_RELEASE}" >~/.onedev
    msg_ok "Updated OneDev"

    msg_info "正在启动 Service"
    systemctl start onedev
    msg_ok "已启动 Service"
    msg_ok "已成功更新!"
    exit
  fi
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6610${CL}"
