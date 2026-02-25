#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/motioneye-project/motioneye

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_hwaccel

msg_info "正在安装依赖"
$STD apt install -y git
$STD apt install -y cifs-utils
msg_ok "已安装依赖"

msg_info "设置 Python3"
$STD apt install -y \
  python3 \
  python3-dev \
  python3-pip
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
msg_ok "设置 Python3"

msg_info "正在安装 Motion"
$STD apt install -y motion
systemctl stop motion
$STD systemctl disable motion
msg_ok "已安装 Motion"

msg_info "正在安装 FFmpeg"
$STD apt install -y ffmpeg v4l-utils
msg_ok "已安装 FFmpeg"

msg_info "正在安装 MotionEye"
$STD apt update
$STD pip install git+https://github.com/motioneye-project/motioneye.git@dev
mkdir -p /etc/motioneye
chown -R root:root /etc/motioneye
chmod -R 777 /etc/motioneye
curl -fsSL "https://raw.githubusercontent.com/motioneye-project/motioneye/dev/motioneye/extra/motioneye.conf.sample" -o "/etc/motioneye/motioneye.conf"
mkdir -p /var/lib/motioneye
msg_ok "已安装 MotionEye"

msg_info "正在创建 Service"
curl -fsSL "https://raw.githubusercontent.com/motioneye-project/motioneye/dev/motioneye/extra/motioneye.systemd" -o "/etc/systemd/system/motioneye.service"
systemctl enable -q --now motioneye
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
