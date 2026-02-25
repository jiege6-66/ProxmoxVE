#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://healthchecks.io/

APP="healthchecks"
var_tags="${var_tags:-monitoring}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-5}"
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

  if [[ ! -d /opt/healthchecks ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "healthchecks" "healthchecks/healthchecks"; then
    msg_info "正在停止 Services"
    systemctl stop healthchecks
    msg_ok "已停止 Services"

    msg_info "正在备份 existing installation"
    BACKUP="/opt/healthchecks-backup-$(date +%F-%H%M)"
    cp -a /opt/healthchecks "$BACKUP"
    msg_ok "Backup created at $BACKUP"

    fetch_and_deploy_gh_release "healthchecks" "healthchecks/healthchecks" "tarball"

    cd /opt/healthchecks
    if [[ -d venv ]]; then
      rm -rf venv
    fi
    msg_info "Recreating Python venv"
    $STD python3 -m venv venv
    $STD source venv/bin/activate
    $STD pip install --upgrade pip wheel
    msg_ok "已创建 venv"

    msg_info "正在安装 requirements"
    $STD pip install gunicorn -r requirements.txt
    msg_ok "已安装 requirements"

    msg_info "正在运行 Django migrations"
    $STD python manage.py migrate --noinput
    $STD python manage.py collectstatic --noinput
    $STD python manage.py compress
    msg_ok "Completed Django migrations and static build"

    msg_info "正在启动 Services"
    systemctl start healthchecks
    systemctl reload caddy
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
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}${CL}"
