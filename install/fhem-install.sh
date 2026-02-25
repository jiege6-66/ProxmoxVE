#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://fhem.de/

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

setup_deb822_repo \
  "fhem" \
  "https://debian.fhem.de/archive.key" \
  "https://debian.fhem.de/nightly/" \
  "/" \
  " "

msg_info "正在设置 FHEM"
$STD apt install -y fhem
msg_ok "设置 FHEM"

motd_ssh
customize
cleanup_lxc
