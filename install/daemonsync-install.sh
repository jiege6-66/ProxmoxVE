#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://daemonsync.me/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y g++-multilib
msg_ok "已安装依赖"

msg_info "正在安装 Daemon Sync Server"
curl -fsSL "https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/tools/addon/daemonsync_2.2.0.0059_amd64.deb" -o "daemonsync_2.2.0.0059_amd64.deb"
$STD dpkg -i daemonsync_2.2.0.0059_amd64.deb
rm -rf daemonsync_2.2.0.0059_amd64.deb
msg_ok "已安装 Daemon Sync Server"

motd_ssh
customize
cleanup_lxc
