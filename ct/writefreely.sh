#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: StellaeAlis
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/writefreely/writefreely

APP="WriteFreely"
var_tags="${var_tags:-writing}"
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

  if [[ ! -d /opt/writefreely ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "writefreely" "writefreely/writefreely"; then
    msg_info "正在停止 Services"
    systemctl stop writefreely
    msg_ok "已停止 Services"

    msg_info "正在创建 Backup"
    mkdir -p /tmp/writefreely_backup
    cp /opt/writefreely/keys /tmp/writefreely_backup/ 2>/dev/null
    cp /opt/writefreely/config.ini /tmp/writefreely_backup/ 2>/dev/null
    msg_ok "已创建 Backup"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "writefreely" "writefreely/writefreely" "prebuild" "latest" "/opt/writefreely" "writefreely_*_linux_amd64.tar.gz"

    msg_info "正在恢复 Data"
    cp /tmp/writefreely_backup/config.ini /opt/writefreely/ 2>/dev/null
    cp /tmp/writefreely_backup/keys/* /opt/writefreely/keys/ 2>/dev/null
    rm -rf /tmp/writefreely_backup
    msg_ok "已恢复 Data"

    msg_info "正在运行 Post-Update Tasks"
    cd /opt/writefreely
    $STD ./writefreely db migrate
    ln -s /opt/writefreely/writefreely /usr/local/bin/writefreely
    msg_ok "Ran Post-Update Tasks"

    msg_info "正在启动 Services"
    systemctl start writefreely
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
