#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/aceberg/WatchYourLAN

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y \
  arp-scan \
  ieee-data \
  libwww-perl
msg_ok "已安装依赖"

fetch_and_deploy_gh_release "watchyourlan" "aceberg/WatchYourLAN" "binary"

msg_info "正在配置 WatchYourLAN"
mkdir /data
cat <<EOF >/data/config.yaml
arp_timeout: "500"
auth: false
auth_expire: 7d
auth_password: ""
auth_user: ""
color: dark
dbpath: /data/db.sqlite
guiip: 0.0.0.0
guiport: "8840"
history_days: "30"
iface: eth0
ignoreip: "no"
loglevel: verbose
shoutrrr_url: ""
theme: solar
timeout: 60
EOF
msg_ok "已配置 WatchYourLAN"

msg_info "正在创建 Service"
sed -i 's|/etc/watchyourlan/config.yaml|/data/config.yaml|' /lib/systemd/system/watchyourlan.service
systemctl enable -q --now watchyourlan
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
