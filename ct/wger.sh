#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/wger-project/wger

APP="wger"
var_tags="${var_tags:-management;fitness}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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

  if [[ ! -d /opt/wger ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "wger" "wger-project/wger"; then
    msg_info "正在停止 Service"
    systemctl stop redis-server nginx celery celery-beat wger
    msg_ok "已停止 Service"

    msg_info "正在备份 Data"
    cp -r /opt/wger/media /opt/wger_media_backup
    cp /opt/wger/.env /opt/wger_env_backup
    msg_ok "已备份 Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "wger" "wger-project/wger" "tarball"

    msg_info "正在恢复 Data"
    cp -r /opt/wger_media_backup/. /opt/wger/media
    cp /opt/wger_env_backup /opt/wger/.env
    rm -rf /opt/wger_media_backup /opt/wger_env_backup

    msg_ok "已恢复 Data"

    msg_info "正在更新 wger"
    cd /opt/wger
    set -a && source /opt/wger/.env && set +a
    export DJANGO_SETTINGS_MODULE=settings.main
    $STD uv pip install .
    $STD uv run python manage.py migrate
    $STD uv run python manage.py collectstatic --no-input
    msg_ok "Updated wger"

    msg_info "正在启动 Services"
    systemctl start redis-server nginx celery celery-beat wger
    msg_ok "已启动 Services"
    msg_ok "更新成功"
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
