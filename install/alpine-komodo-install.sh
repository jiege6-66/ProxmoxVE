#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://komo.do/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apk add --no-cache ca-certificates openssl
msg_ok "已安装依赖"

msg_info "设置 Docker Repository"
$STD apk add --no-cache docker docker-cli docker-compose openrc
msg_ok "设置 Docker Repository"

msg_info "正在启用 Docker Service"
$STD rc-update add docker boot
$STD service docker start
msg_ok "已启用 Docker Service"

echo "${TAB3}Choose the database for Komodo installation:"
echo "${TAB3}1) MongoDB (recommended)"
echo "${TAB3}2) FerretDB"
read -rp "${TAB3}Enter your choice (default: 1): " DB_CHOICE
DB_CHOICE=${DB_CHOICE:-1}

case $DB_CHOICE in
1)
  DB_COMPOSE_FILE="mongo.compose.yaml"
  ;;
2)
  DB_COMPOSE_FILE="ferretdb.compose.yaml"
  ;;
*)
  echo "Invalid choice. Defaulting to MongoDB."
  DB_COMPOSE_FILE="mongo.compose.yaml"
  ;;
esac

mkdir -p /opt/komodo
cd /opt/komodo
curl -fsSL "https://raw.githubusercontent.com/moghtech/komodo/main/compose/$DB_COMPOSE_FILE" -o "$(basename "$DB_COMPOSE_FILE")"

msg_info "设置 Komodo Environment"
curl -fsSL "https://raw.githubusercontent.com/moghtech/komodo/main/compose/compose.env" -o "/opt/komodo/compose.env"
DB_PASSWORD=$(openssl rand -base64 16 | tr -d '/+=')
PASSKEY=$(openssl rand -base64 24 | tr -d '/+=')
WEBHOOK_SECRET=$(openssl rand -base64 24 | tr -d '/+=')
JWT_SECRET=$(openssl rand -base64 24 | tr -d '/+=')

sed -i "s/^KOMODO_DB_USERNAME=.*/KOMODO_DB_USERNAME=komodo_admin/" /opt/komodo/compose.env
sed -i "s/^KOMODO_DB_PASSWORD=.*/KOMODO_DB_PASSWORD=${DB_PASSWORD}/" /opt/komodo/compose.env
sed -i "s/^KOMODO_PASSKEY=.*/KOMODO_PASSKEY=${PASSKEY}/" /opt/komodo/compose.env
sed -i "s/^KOMODO_WEBHOOK_SECRET=.*/KOMODO_WEBHOOK_SECRET=${WEBHOOK_SECRET}/" /opt/komodo/compose.env
sed -i "s/^KOMODO_JWT_SECRET=.*/KOMODO_JWT_SECRET=${JWT_SECRET}/" /opt/komodo/compose.env
msg_ok "设置 Komodo Environment"

msg_info "Initialize Komodo"
$STD docker compose -p komodo -f "/opt/komodo/$DB_COMPOSE_FILE" --env-file /opt/komodo/compose.env up -d
msg_ok "已初始化 Komodo"

motd_ssh
customize

msg_info "正在清理"
$STD apk cache clean
msg_ok "已清理"
