#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://openarchiver.com/

APP="Open-Archiver"
var_tags="${var_tags:-os}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-3072}"
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
  if [[ ! -d /opt/openarchiver ]]; then
    msg_error "No Open Archiver 安装已找到！"
    exit
  fi

  setup_meilisearch

  if check_for_gh_release "openarchiver" "LogicLabs-OU/OpenArchiver"; then
    msg_info "正在停止 Services"
    systemctl stop openarchiver
    msg_ok "已停止 Services"

    cp /opt/openarchiver/.env /opt/openarchiver.env
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "openarchiver" "LogicLabs-OU/OpenArchiver" "tarball"
    mv /opt/openarchiver.env /opt/openarchiver/.env

    msg_info "正在更新 Open Archiver"
    cd /opt/openarchiver
    $STD pnpm install --shamefully-hoist --frozen-lockfile --prod=false
    $STD pnpm run build:oss
    $STD pnpm db:migrate
    msg_ok "Updated Open Archiver"

    if grep -q '^ExecStart=/usr/bin/pnpm docker-start$' /etc/systemd/system/openarchiver.service; then
      sed -i 's|^ExecStart=/usr/bin/pnpm docker-start$|ExecStart=/usr/bin/pnpm docker-start:oss|' /etc/systemd/system/openarchiver.service
      systemctl daemon-reload
    fi

    msg_info "正在启动 Services"
    systemctl start openarchiver
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
