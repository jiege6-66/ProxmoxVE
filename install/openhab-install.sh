#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://www.openhab.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

JAVA_VERSION="21" setup_java

msg_info "正在安装 openHAB"
setup_deb822_repo \
  "openhab" \
  "https://openhab.jfrog.io/artifactory/api/gpg/key/public" \
  "https://openhab.jfrog.io/artifactory/openhab-linuxpkg" \
  "stable" \
  "main"
$STD apt install -y openhab
msg_ok "已安装 openHAB"

msg_info "正在初始化 openHAB directories"
mkdir -p /var/lib/openhab/{tmp,etc,cache}
mkdir -p /etc/openhab
mkdir -p /var/log/openhab
chown -R openhab:openhab /var/lib/openhab /etc/openhab /var/log/openhab
msg_ok "已初始化 openHAB directories"

msg_info "正在启动 Service"
systemctl daemon-reload
systemctl enable -q --now openhab
msg_ok "已启动 Service"

motd_ssh
customize
cleanup_lxc
