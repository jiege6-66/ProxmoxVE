#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://komo.do

APP="Komodo"
var_tags="${var_tags:-docker}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
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

  [[ -d /opt/komodo ]] || {
    msg_error "未找到 ${APP} 安装！"
    exit 1
  }

  msg_info "正在更新 Komodo"
  COMPOSE_FILE=$(find /opt/komodo -maxdepth 1 -type f -name '*.compose.yaml' ! -name 'compose.env' | head -n1)
  if [[ -z "$COMPOSE_FILE" ]]; then
    msg_error "No valid compose file found in /opt/komodo!"
    exit 1
  fi
  COMPOSE_BASENAME=$(basename "$COMPOSE_FILE")

  if [[ "$COMPOSE_BASENAME" == "sqlite.compose.yaml" || "$COMPOSE_BASENAME" == "postgres.compose.yaml" ]]; then
    msg_error "❌ 已检测到 outdated Komodo setup using SQLite or PostgreSQL (FerretDB v1)."
    echo -e "${YW}This configuration is no longer supported since Komodo v1.18.0.${CL}"
    echo -e "${YW}Please follow the migration guide:${CL}"
    echo -e "${BGN}https://github.com/jiege6-66/ProxmoxVE/discussions/5689${CL}\n"
    exit 1
  fi

  BACKUP_FILE="/opt/komodo/${COMPOSE_BASENAME}.bak_$(date +%Y%m%d_%H%M%S)"
  cp "$COMPOSE_FILE" "$BACKUP_FILE" || {
    msg_error "无法 create backup of ${COMPOSE_BASENAME}!"
    exit 1
  }
  GITHUB_URL="https://raw.githubusercontent.com/moghtech/komodo/main/compose/${COMPOSE_BASENAME}"
  if ! curl -fsSL "$GITHUB_URL" -o "$COMPOSE_FILE"; then
    msg_error "无法 download ${COMPOSE_BASENAME} from GitHub!"
    mv "$BACKUP_FILE" "$COMPOSE_FILE"
    exit 1
  fi
  if ! grep -qxF 'COMPOSE_KOMODO_BACKUPS_PATH=/etc/komodo/backups' /opt/komodo/compose.env; then
    sed -i '/^COMPOSE_KOMODO_IMAGE_TAG=latest$/a COMPOSE_KOMODO_BACKUPS_PATH=/etc/komodo/backups' /opt/komodo/compose.env
  fi
  $STD docker compose -p komodo -f "$COMPOSE_FILE" --env-file /opt/komodo/compose.env pull
  $STD docker compose -p komodo -f "$COMPOSE_FILE" --env-file /opt/komodo/compose.env up -d
  msg_ok "Updated Komodo"
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9120${CL}"
