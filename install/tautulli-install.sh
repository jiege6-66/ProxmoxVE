#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tautulli.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y git
msg_ok "已安装依赖"

PYTHON_VERSION="3.13" setup_uv
fetch_and_deploy_gh_release "Tautulli" "Tautulli/Tautulli" "tarball"

msg_info "正在安装 Tautulli"
cd /opt/Tautulli
TAUTULLI_VERSION=$(get_latest_github_release "Tautulli/Tautulli" "false")
echo "${TAUTULLI_VERSION}" >/opt/Tautulli/version.txt
echo "master" >/opt/Tautulli/branch.txt
$STD uv venv --clear
$STD source /opt/Tautulli/.venv/bin/activate
$STD uv pip install -r requirements.txt
$STD uv pip install pyopenssl
$STD uv pip install "setuptools<81"
msg_ok "已安装 Tautulli"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/tautulli.service
[Unit]
Description=Tautulli
After=syslog.target network.target

[Service]
WorkingDirectory=/opt/Tautulli/
Restart=on-failure
RestartSec=5
Type=simple
ExecStart=/opt/Tautulli/.venv/bin/python3 /opt/Tautulli/Tautulli.py
KillSignal=SIGINT
TimeoutStopSec=20
SyslogIdentifier=tautulli

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now tautulli
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
