#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Johann3s-H (An!ma)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://forgejo.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装 Forgejo"
$STD apk add --no-cache forgejo
msg_ok "已安装 Forgejo"

msg_info "正在启用 Forgejo Service"
$STD rc-update add forgejo default
msg_ok "已启用 Forgejo Service"

msg_info "正在启动 Forgejo"
$STD service forgejo start
msg_ok "已启动 Forgejo"

motd_ssh
customize
