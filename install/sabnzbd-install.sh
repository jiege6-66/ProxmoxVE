#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster) | Co-Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://sabnzbd.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y \
  par2 \
  p7zip-full
msg_ok "已安装依赖"

PYTHON_VERSION="3.13" setup_uv

msg_info "设置 Unrar"
cat <<EOF >/etc/apt/sources.list.d/non-free.sources
Types: deb
URIs: http://deb.debian.org/debian/
Suites: trixie
Components: non-free 
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
$STD apt update
$STD apt install -y unrar
msg_ok "设置 Unrar"

fetch_and_deploy_gh_release "sabnzbd-org" "sabnzbd/sabnzbd" "prebuild" "latest" "/opt/sabnzbd" "SABnzbd-*-src.tar.gz"

msg_info "正在安装 SABnzbd"
$STD uv venv --clear /opt/sabnzbd/venv
$STD uv pip install -r /opt/sabnzbd/requirements.txt --python=/opt/sabnzbd/venv/bin/python
msg_ok "已安装 SABnzbd"

read -r -p "Would you like to install par2cmdline-turbo? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  mv /usr/bin/par2 /usr/bin/par2.old
  fetch_and_deploy_gh_release "par2cmdline-turbo" "animetosho/par2cmdline-turbo" "prebuild" "latest" "/usr/bin/" "*-linux-amd64.zip"
fi

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/sabnzbd.service
[Unit]
Description=SABnzbd
After=network.target

[Service]
WorkingDirectory=/opt/sabnzbd
ExecStart=/opt/sabnzbd/venv/bin/python SABnzbd.py -s 0.0.0.0:7777
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now sabnzbd
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
