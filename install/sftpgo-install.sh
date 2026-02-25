#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://sftpgo.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y sqlite3
msg_ok "已安装依赖"

setup_deb822_repo \
  "sftpgo" \
  "https://ftp.osuosl.org/pub/sftpgo/apt/gpg.key" \
  "https://ftp.osuosl.org/pub/sftpgo/apt" \
  "trixie"

msg_info "正在安装 SFTPGo"
$STD apt install -y sftpgo
msg_ok "已安装 SFTPGo"

motd_ssh
customize
cleanup_lxc
