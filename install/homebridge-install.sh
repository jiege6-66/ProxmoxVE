#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://homebridge.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y avahi-daemon
msg_ok "已安装依赖"

msg_info "正在设置 Homebridge Repository"
setup_deb822_repo \
  "homebridge" \
  "https://repo.homebridge.io/KEY.gpg" \
  "https://repo.homebridge.io" \
  "stable"
msg_ok "Set up Homebridge Repository"

msg_info "正在安装 Homebridge"
$STD apt install -y homebridge
msg_ok "已安装 Homebridge"

motd_ssh
customize
cleanup_lxc
