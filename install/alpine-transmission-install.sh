#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://transmissionbt.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装 Transmission"
$STD apk add --no-cache transmission-cli transmission-daemon
$STD rc-service transmission-daemon start
sleep 5
$STD rc-service transmission-daemon stop
sed -i '{s/"rpc-whitelist-enabled": true/"rpc-whitelist-enabled": false/g; s/"rpc-host-whitelist-enabled": true,/"rpc-host-whitelist-enabled": false,/g}' /var/lib/transmission/config/settings.json
msg_ok "已安装 Transmission"

msg_info "正在启用 Transmission Service"
$STD rc-update add transmission-daemon default
msg_ok "已启用 Transmission Service"

msg_info "正在启动 Transmission"
$STD rc-service transmission-daemon start
msg_ok "已启动 Transmission"

motd_ssh
customize
