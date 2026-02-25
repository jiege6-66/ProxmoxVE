#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apk add ca-certificates
$STD update-ca-certificates
msg_ok "已安装依赖"

msg_info "正在安装 Traefik"
$STD apk add traefik --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community
msg_ok "已安装 Traefik"

read -p "${TAB3}Enable Traefik WebUI (Port 8080)? [y/N]: " enable_webui
if [[ "$enable_webui" =~ ^[Yy]$ ]]; then
  msg_info "正在配置 Traefik WebUI"
  sed -i 's/localhost//g' /etc/traefik/traefik.yaml
  msg_ok "已配置 Traefik WebUI"
fi

msg_info "正在启用 and starting Traefik service"
$STD rc-update add traefik default
sed -i '/^command=.*/i directory="/etc/traefik"' /etc/init.d/traefik
$STD rc-service traefik start
msg_ok "Traefik service started"

motd_ssh
customize
