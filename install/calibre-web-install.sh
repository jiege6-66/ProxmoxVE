#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: mikolaj92
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/janeczku/calibre-web

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y \
  build-essential \
  python3 \
  python3-dev \
  libldap2-dev \
  libsasl2-dev \
  libssl-dev \
  imagemagick \
  libpango-1.0-0 \
  libharfbuzz0b \
  libpangoft2-1.0-0 \
  fonts-liberation
msg_ok "已安装依赖"

msg_info "正在安装 Calibre (for eBook conversion)"
$STD apt install -y calibre
msg_ok "已安装 Calibre"

fetch_and_deploy_gh_release "Calibre-Web" "janeczku/calibre-web" "prebuild" "latest" "/opt/calibre-web" "calibre-web*.tar.gz"
setup_uv

msg_info "正在安装 Python 依赖"
cd /opt/calibre-web
$STD uv venv
$STD uv pip install --python /opt/calibre-web/.venv/bin/python --no-cache-dir --upgrade pip setuptools wheel
$STD uv pip install --python /opt/calibre-web/.venv/bin/python --no-cache-dir -r requirements.txt
msg_ok "已安装 Python 依赖"

msg_info "正在创建 Service"
mkdir -p /opt/calibre-web/data
cat <<EOF >/etc/systemd/system/calibre-web.service
[Unit]
Description=Calibre-Web Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/calibre-web
ExecStart=/opt/calibre-web/.venv/bin/python /opt/calibre-web/cps.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now calibre-web
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
