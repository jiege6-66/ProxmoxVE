#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://nextpvr.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os
setup_hwaccel

msg_info "正在安装依赖 (Patience)"
$STD apt install -y \
  mediainfo \
  libmediainfo-dev \
  libc6 \
  libgdiplus \
  acl \
  dvb-tools \
  libdvbv5-0 \
  dtv-scan-tables \
  libc6-dev \
  ffmpeg
msg_ok "已安装依赖"

msg_info "设置 NextPVR (Patience)"
cd /opt
curl -fsSL "https://nextpvr.com/nextpvr-helper.deb" -o "/opt/nextpvr-helper.deb"
$STD dpkg -i nextpvr-helper.deb
rm -rf /opt/nextpvr-helper.deb
msg_ok "已安装 NextPVR"

motd_ssh
customize
cleanup_lxc
