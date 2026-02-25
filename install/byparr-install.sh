#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: luismco
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ThePhaseless/Byparr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt -y install --no-install-recommends \
  ffmpeg \
  libatk1.0-0 \
  libcairo-gobject2 \
  libcairo2 \
  libdbus-glib-1-2 \
  libfontconfig1 \
  libfreetype6 \
  libgdk-pixbuf-xlib-2.0-0 \
  libglib2.0-0 \
  libgtk-3-0 \
  libpango-1.0-0 \
  libpangocairo-1.0-0 \
  libpangoft2-1.0-0 \
  libx11-6 \
  libx11-xcb1 \
  libxcb-shm0 \
  libxcb1 \
  libxcomposite1 \
  libxcursor1 \
  libxdamage1 \
  libxext6 \
  libxfixes3 \
  libxi6 \
  libxrender1 \
  libxt6 \
  libxtst6 \
  xvfb \
  fonts-noto-color-emoji \
  fonts-unifont \
  xfonts-cyrillic \
  xfonts-scalable \
  fonts-liberation \
  fonts-ipafont-gothic \
  fonts-wqy-zenhei \
  fonts-tlwg-loma-otf
msg_ok "已安装依赖"

setup_uv
fetch_and_deploy_gh_release "Byparr" "ThePhaseless/Byparr" "tarball" "latest"

msg_info "正在配置 Byparr"
cd /opt/Byparr
$STD uv sync --link-mode copy
$STD uv run camoufox fetch
msg_ok "已配置 Byparr"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/byparr.service
[Unit]
Description=Byparr
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/Byparr
ExecStart=/usr/local/bin/uv run python3 main.py
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now byparr
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
