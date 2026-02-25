#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/influxdata/telegraf

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在设置 Telegraf repository"
setup_deb822_repo \
  "telegraf" \
  "https://repos.influxdata.com/influxdata-archive.key" \
  "https://repos.influxdata.com/debian" \
  "stable"
msg_ok "设置 Telegraf Repository"

msg_info "正在设置 Telegraf"
$STD apt install -y telegraf
msg_ok "设置 Telegraf"

motd_ssh
customize
cleanup_lxc
