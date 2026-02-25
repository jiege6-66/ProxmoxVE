#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://adguardhome.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在下载 AdGuard Home"
$STD curl -fsSL -o /tmp/AdGuardHome_linux_amd64.tar.gz \
  "https://github.com/AdguardTeam/AdGuardHome/releases/latest/download/AdGuardHome_linux_amd64.tar.gz"
msg_ok "已下载 AdGuard Home"

msg_info "正在安装 AdGuard Home"
$STD tar -xzf /tmp/AdGuardHome_linux_amd64.tar.gz -C /opt
$STD rm /tmp/AdGuardHome_linux_amd64.tar.gz
msg_ok "已安装 AdGuard Home"

msg_info "正在创建 AdGuard Home Service"
cat <<EOF >/etc/init.d/adguardhome
#!/sbin/openrc-run
name="AdGuardHome"
description="AdGuard Home Service"
command="/opt/AdGuardHome/AdGuardHome"
command_background="yes"
pidfile="/run/adguardhome.pid"
EOF
$STD chmod +x /etc/init.d/adguardhome
msg_ok "已创建 AdGuard Home Service"

msg_info "正在启用 AdGuard Home Service"
$STD rc-update add adguardhome default
msg_ok "已启用 AdGuard Home Service"

msg_info "正在启动 AdGuard Home"
$STD rc-service adguardhome start
msg_ok "已启动 AdGuard Home"

motd_ssh
customize
