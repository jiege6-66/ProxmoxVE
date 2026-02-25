#!/usr/bin/env bash
source <(curl -s https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ) | DevelopmentCats | AlphaLawless
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://romm.app

APP="RomM"
var_tags="${var_tags:-emulation}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-20}"
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

    if [[ ! -d /opt/romm ]]; then
        msg_error "未找到 ${APP} 安装！"
        exit
    fi

    if check_for_gh_release "romm" "rommapp/romm"; then
        msg_info "正在停止 Services"
        systemctl stop romm-backend romm-worker romm-scheduler romm-watcher
        msg_ok "已停止 Services"

        msg_info "正在备份 configuration"
        cp /opt/romm/.env /opt/romm/.env.backup
        msg_ok "已备份 configuration"

        fetch_and_deploy_gh_release "romm" "rommapp/romm" "tarball" "latest" "/opt/romm"

        msg_info "正在更新 ROMM"
        cp /opt/romm/.env.backup /opt/romm/.env
        cd /opt/romm
        $STD uv sync --all-extras
        cd /opt/romm/backend
        $STD uv run alembic upgrade head
        cd /opt/romm/frontend
        $STD npm install
        $STD npm run build
        # Merge static assets into dist folder
        cp -rf /opt/romm/frontend/assets/* /opt/romm/frontend/dist/assets/
        mkdir -p /opt/romm/frontend/dist/assets/romm
        ln -sfn /var/lib/romm/resources /opt/romm/frontend/dist/assets/romm/resources
        ln -sfn /var/lib/romm/assets /opt/romm/frontend/dist/assets/romm/assets
        msg_ok "Updated ROMM"

        msg_info "正在启动 Services"
        systemctl start romm-backend romm-worker romm-scheduler romm-watcher
        msg_ok "已启动 Services"
        msg_ok "已成功更新"
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
