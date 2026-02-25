#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://syncthing.net/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "设置 Syncthing"
$STD apk add --no-cache syncthing
rc-service syncthing start
sleep 3
rc-service syncthing stop
sed -i "{s/127.0.0.1:8384/0.0.0.0:8384/g}" /var/lib/syncthing/.local/state/syncthing/config.xml
msg_ok "设置 Syncthing"

msg_info "正在启用 Syncthing Service"
$STD rc-update add syncthing default
msg_ok "已启用 Syncthing Service"

msg_info "正在启动 Syncthing"
$STD rc-service syncthing start
msg_ok "已启动 Syncthing"

motd_ssh
customize
