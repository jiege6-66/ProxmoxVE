#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Kristian Skov
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://www.urbackup.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y debconf-utils
msg_ok "已安装依赖"

setup_deb822_repo \
  "urbackup" \
  "https://download.opensuse.org/repositories/home:uroni/Debian_13/Release.key" \
  "http://download.opensuse.org/repositories/home:/uroni/Debian_13/" \
  "./" \
  ""

msg_info "正在设置 UrBackup Server"
mkdir -p /opt/urbackup/backups
echo "urbackup-server urbackup/backuppath string /opt/urbackup/backups" | debconf-set-selections
$STD apt install -y urbackup-server
msg_ok "设置 UrBackup Server"

motd_ssh
customize
cleanup_lxc
