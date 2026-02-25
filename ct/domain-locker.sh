#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Lissy93/domain-locker

APP="Domain-Locker"
var_tags="${var_tags:-Monitoring}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-10240}"
var_disk="${var_disk:-8}"
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
    if [[ ! -d /opt/domain-locker ]]; then
        msg_error "未找到 ${APP} 安装！"
        exit
    fi

    if check_for_gh_release "domain-locker" "Lissy93/domain-locker"; then
        msg_info "正在停止 Service"
        systemctl stop domain-locker
        msg_info "Service stopped"

        PG_VERSION="17" setup_postgresql
        NODE_VERSION="22" setup_nodejs
        CLEAN_INSTALL=1 fetch_and_deploy_gh_release "domain-locker" "Lissy93/domain-locker" "tarball"

        msg_info "正在安装 Modules (patience)"
        cd /opt/domain-locker
        $STD npm install
        msg_ok "已安装 Modules"

        msg_info "正在构建 Domain-Locker (a lot of patience)"
        set -a
        source /opt/domain-locker.env
        set +a
        $STD npm run build
        msg_info "已构建 Domain-Locker"

        msg_info "正在重启 Services"
        systemctl start domain-locker
        msg_ok "已重启 Services"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
