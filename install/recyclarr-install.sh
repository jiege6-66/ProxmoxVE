#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MrYadro
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://recyclarr.dev/wiki/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y git
msg_ok "已安装依赖"

fetch_and_deploy_gh_release "recyclarr" "recyclarr/recyclarr" "prebuild" "latest" "/usr/local/bin" "recyclarr-linux-x64.tar.xz"

msg_info "正在配置 Recyclarr"
mkdir -p /root/.config/recyclarr/{configs,includes}
$STD recyclarr config create
msg_ok "已配置 Recyclarr"

msg_info "正在设置 Daily Sync Cron"
cat <<EOF >/etc/cron.d/recyclarr
# Run recyclarr sync daily
@daily root /usr/local/bin/recyclarr sync >> /root/.config/recyclarr/sync.log 2>&1
EOF
chmod 644 /etc/cron.d/recyclarr
msg_ok "设置 Daily Sync Cron"

motd_ssh
customize
cleanup_lxc
