#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://prometheus.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装 Prometheus"
$STD apk add --no-cache prometheus
msg_ok "已安装 Prometheus"

msg_info "正在启用 Prometheus Service"
$STD rc-update add prometheus default
msg_ok "已启用 Prometheus Service"

msg_info "正在启动 Prometheus"
$STD service prometheus start
msg_ok "已启动 Prometheus"

motd_ssh
customize
