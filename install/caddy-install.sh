#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster) | Co-Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://caddyserver.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y \
  debian-keyring \
  debian-archive-keyring \
  apt-transport-https
msg_ok "已安装依赖"

msg_info "正在安装 Caddy"
setup_deb822_repo \
  "caddy" \
  "https://dl.cloudsmith.io/public/caddy/stable/gpg.key" \
  "https://dl.cloudsmith.io/public/caddy/stable/deb/debian" \
  "any-version"
$STD apt install -y caddy
msg_ok "已安装 Caddy"

read -r -p "${TAB3}Would you like to install xCaddy Addon? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  setup_go
  fetch_and_deploy_gh_release "xcaddy" "caddyserver/xcaddy" "binary"

  msg_info "设置 xCaddy"
  $STD apt install -y git
  $STD xcaddy build
  msg_ok "设置 xCaddy"
fi

motd_ssh
customize
cleanup_lxc
