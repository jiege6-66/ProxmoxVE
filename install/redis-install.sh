#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://redis.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y apt-transport-https
msg_ok "已安装依赖"

msg_info "正在设置 Redis Repository"
setup_deb822_repo \
  "redis" \
  "https://packages.redis.io/gpg" \
  "https://packages.redis.io/deb" \
  "trixie"
msg_ok "设置 Redis Repository"

msg_info "正在设置 Redis"
$STD apt install -y redis
sed -i 's/^bind .*/bind 0.0.0.0/' /etc/redis/redis.conf
systemctl enable -q --now redis-server
msg_ok "设置 Redis"

motd_ssh
customize
cleanup_lxc
