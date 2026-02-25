#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://garagehq.deuxfleurs.fr/

APP="Alpine-Garage"
var_tags="${var_tags:-alpine;object-storage}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-5}"
var_os="${var_os:-alpine}"
var_version="${var_version:-3.23}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  if [[ ! -f /usr/local/bin/garage ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  GITEA_RELEASE=$(curl -fsSL https://api.github.com/repos/deuxfleurs-org/garage/tags | jq -r '.[0].name')
  if [[ "${GITEA_RELEASE}" != "$(cat ~/.garage 2>/dev/null)" ]] || [[ ! -f ~/.garage ]]; then
    msg_info "正在停止 Service"
    rc-service garage stop || true
    msg_ok "已停止 Service"

    msg_info "Backing Up Data"
    cp /usr/local/bin/garage /usr/local/bin/garage.old 2>/dev/null || true
    cp /etc/garage.toml /etc/garage.toml.bak 2>/dev/null || true
    msg_ok "Backed Up Data"

    msg_info "正在更新 Garage"
    curl -fsSL "https://garagehq.deuxfleurs.fr/_releases/${GITEA_RELEASE}/x86_64-unknown-linux-musl/garage" -o /usr/local/bin/garage
    chmod +x /usr/local/bin/garage
    echo "${GITEA_RELEASE}" >~/.garage
    msg_ok "Updated Garage"

    msg_info "正在启动 Service"
    rc-service garage start || rc-service garage restart
    msg_ok "已启动 Service"
    msg_ok "已成功更新!"
  else
    msg_ok "无需更新。 Garage is already at ${GITEA_RELEASE}"
  fi
  exit 0
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
