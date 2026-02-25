#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Tom Frenzel (tomfrenzel)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/CodeWithCJ/SparkyFitness

APP="SparkyFitness"
var_tags="${var_tags:-health;fitness}"
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

  if [[ ! -d /opt/sparkyfitness ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  NODE_VERSION="25" setup_nodejs

  if check_for_gh_release "sparkyfitness" "CodeWithCJ/SparkyFitness"; then
    msg_info "正在停止 Services"
    systemctl stop sparkyfitness-server nginx
    msg_ok "已停止 Services"

    msg_info "正在备份 data"
    mkdir -p /opt/sparkyfitness_backup
    if [[ -d /opt/sparkyfitness/SparkyFitnessServer/uploads ]]; then
      cp -r /opt/sparkyfitness/SparkyFitnessServer/uploads /opt/sparkyfitness_backup/
    fi
    if [[ -d /opt/sparkyfitness/SparkyFitnessServer/backup ]]; then
      cp -r /opt/sparkyfitness/SparkyFitnessServer/backup /opt/sparkyfitness_backup/
    fi
    msg_ok "已备份 data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "sparkyfitness" "CodeWithCJ/SparkyFitness" "tarball"

    msg_info "正在更新 Sparky Fitness Backend"
    cd /opt/sparkyfitness/SparkyFitnessServer
    $STD npm install
    msg_ok "Updated Sparky Fitness Backend"

    msg_info "正在更新 Sparky Fitness Frontend (Patience)"
    cd /opt/sparkyfitness/SparkyFitnessFrontend
    $STD npm install
    $STD npm run build
    cp -a /opt/sparkyfitness/SparkyFitnessFrontend/dist/. /var/www/sparkyfitness/
    msg_ok "Updated Sparky Fitness Frontend"

    msg_info "正在恢复 data"
    cp -r /opt/sparkyfitness_backup/. /opt/sparkyfitness/SparkyFitnessServer/
    rm -rf /opt/sparkyfitness_backup
    msg_ok "已恢复 data"

    msg_info "正在启动 Services"
    $STD systemctl start sparkyfitness-server nginx
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
