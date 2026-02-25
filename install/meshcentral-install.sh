#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://meshcentral.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y ca-certificates
msg_ok "已安装依赖"

NODE_VERSION="22" setup_nodejs

msg_info "正在安装 MeshCentral"
mkdir /opt/meshcentral
cd /opt/meshcentral
$STD npm install meshcentral
$STD node node_modules/meshcentral --install
msg_ok "已安装 MeshCentral"

motd_ssh
customize
cleanup_lxc
