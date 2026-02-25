#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/navidrome/navidrome

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖 (Patience)"
$STD apt install -y ffmpeg
msg_ok "已安装依赖"

fetch_and_deploy_gh_release "navidrome" "navidrome/navidrome" "binary"

msg_info "正在启动 Navidrome"
systemctl enable -q --now navidrome
msg_ok "已启动 Navidrome"

read -p "${TAB3}Do you want to install filebrowser addon? (y/n) " -n 1 -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/filebrowser.sh)"
fi

motd_ssh
customize
cleanup_lxc
