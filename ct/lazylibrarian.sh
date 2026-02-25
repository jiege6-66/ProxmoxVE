#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck | Co-Author: MountyMapleSyrup (MountyMapleSyrup)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://gitlab.com/LazyLibrarian/LazyLibrarian

APP="LazyLibrarian"
var_tags="${var_tags:-eBook}"
var_cpu="${var_cpu:-2}"
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
    if [[ ! -d /opt/LazyLibrarian/ ]]; then
        msg_error "未找到 ${APP} 安装！"
        exit
    fi
    msg_info "正在停止 LazyLibrarian"
    systemctl stop lazylibrarian
    msg_ok "LazyLibrarian 已停止"

    msg_info "正在更新 $APP LXC"
    $STD git -C /opt/LazyLibrarian pull origin master
    msg_ok "Updated $APP LXC"

    msg_info "正在启动 LazyLibrarian"
    systemctl start lazylibrarian
    msg_ok "已启动 LazyLibrarian"

    msg_ok "已成功更新!"
    exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5299${CL}"
