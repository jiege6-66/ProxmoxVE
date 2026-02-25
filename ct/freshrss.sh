#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/FreshRSS/FreshRSS

APP="FreshRSS"
var_tags="${var_tags:-RSS}"
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
  if [[ ! -d /opt/freshrss ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if [ ! -x /opt/freshrss/cli/sensitive-log.sh ]; then
    msg_info "Fixing wrong permissions"
    chmod +x /opt/freshrss/cli/sensitive-log.sh
    systemctl restart apache2
    msg_ok "Fixed wrong permissions"
  fi

  if check_for_gh_release "freshrss" "FreshRSS/FreshRSS"; then
    msg_info "正在停止 Apache2"
    systemctl stop apache2
    msg_ok "已停止 Apache2"

    msg_info "正在备份 FreshRSS"
    mv /opt/freshrss /opt/freshrss-backup
    msg_ok "Backup 已创建"

    fetch_and_deploy_gh_release "freshrss" "FreshRSS/FreshRSS" "tarball"

    msg_info "正在恢复 data and configuration"
    if [[ -d /opt/freshrss-backup/data ]]; then
      cp -a /opt/freshrss-backup/data/. /opt/freshrss/data/
    fi
    if [[ -d /opt/freshrss-backup/extensions ]]; then
      cp -a /opt/freshrss-backup/extensions/. /opt/freshrss/extensions/
    fi
    msg_ok "Data 已恢复"

    msg_info "Setting permissions"
    chown -R www-data:www-data /opt/freshrss
    chmod -R g+rX /opt/freshrss
    chmod -R g+w /opt/freshrss/data/
    msg_ok "Permissions Set"

    msg_info "正在启动 Apache2"
    systemctl start apache2
    msg_ok "已启动 Apache2"

    msg_info "正在清理 backup"
    rm -rf /opt/freshrss-backup
    msg_ok "已清理 backup"
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
