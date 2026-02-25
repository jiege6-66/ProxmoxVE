#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Casvt/Kapowarr

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y python3-pip
msg_ok "已安装依赖"

PYTHON_VERSION="3.12" setup_uv
fetch_and_deploy_gh_release "kapowarr" "Casvt/Kapowarr" "tarball"

msg_info "设置 Kapowarr"
cd /opt/kapowarr
$STD uv venv --clear .venv
$STD source .venv/bin/activate
$STD uv pip install --upgrade pip
$STD uv pip install --no-cache-dir -r requirements.txt
msg_ok "已安装 Kapowarr"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/kapowarr.service
[Unit]
Description=Kapowarr Service
After=network.target

[Service]
WorkingDirectory=/opt/kapowarr/
ExecStart=/opt/kapowarr/.venv/bin/python3 Kapowarr.py
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now kapowarr
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
