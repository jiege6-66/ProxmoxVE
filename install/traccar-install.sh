#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.traccar.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "traccar" "traccar/traccar" "prebuild" "latest" "/opt/traccar" "traccar-linux-64*.zip"

msg_info "正在配置 Traccar"
cd /opt/traccar
$STD ./traccar.run
[ -f README.txt ] || [ -f traccar.run ] && rm -f README.txt traccar.run
msg_ok "已配置 Traccar"

msg_info "正在启动 service"
systemctl enable -q --now traccar
msg_ok "Service started"

motd_ssh
customize
cleanup_lxc
