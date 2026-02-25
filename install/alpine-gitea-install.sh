#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://gitea.io/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装 Gitea"
$STD apk add --no-cache gitea
msg_ok "已安装 Gitea"

msg_info "正在启用 Gitea Service"
$STD rc-update add gitea default
msg_ok "已启用 Gitea Service"

msg_info "正在启动 Gitea"
$STD service gitea start
msg_ok "已启动 Gitea"

motd_ssh
customize
