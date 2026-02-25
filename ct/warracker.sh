#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: BvdBerg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/sassanix/Warracker/

APP="Warracker"
var_tags="${var_tags:-warranty}"
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
    if [[ ! -d /opt/warracker ]]; then
        msg_error "未找到 ${APP} 安装！"
        exit
    fi

    if check_for_gh_release "warracker" "sassanix/Warracker"; then
        msg_info "正在停止 Services"
        systemctl stop warrackermigration
        systemctl stop warracker
        systemctl stop nginx
        msg_ok "已停止 Services"

        fetch_and_deploy_gh_release "warracker" "sassanix/Warracker" "tarball" "latest" "/opt/warracker"

        msg_info "正在更新 Warracker"
        cd /opt/warracker/backend
        $STD uv venv --clear .venv
        $STD source .venv/bin/activate
        $STD uv pip install -r requirements.txt
        msg_ok "Updated Warracker"

        msg_info "正在启动 Services"
        systemctl start warracker
        systemctl start nginx
        msg_ok "已启动 Services"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
