#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://grafana.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y apt-transport-https
msg_ok "已安装依赖"

msg_info "正在设置 Grafana Repository"
setup_deb822_repo \
  "grafana" \
  "https://apt.grafana.com/gpg.key" \
  "https://apt.grafana.com" \
  "stable" \
  "main"
msg_ok "Grafana Repository setup sucessfully"

msg_info "正在安装 Grafana"
$STD apt install -y grafana
systemctl enable -q --now grafana-server
msg_ok "已安装 Grafana"

motd_ssh
customize
cleanup_lxc
