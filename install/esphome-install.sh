#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://esphome.io/

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

PYTHON_VERSION="3.12" setup_uv

msg_info "正在设置 Virtual Environment"
mkdir -p /opt/esphome
mkdir -p /root/config
cd /opt/esphome
$STD uv venv --clear /opt/esphome/.venv
$STD /opt/esphome/.venv/bin/python -m ensurepip --upgrade
$STD /opt/esphome/.venv/bin/python -m pip install --upgrade pip
$STD /opt/esphome/.venv/bin/python -m pip install esphome tornado esptool
msg_ok "设置 and 已安装 ESPHome"

msg_info "Linking esphome to /usr/local/bin"
rm -f /usr/local/bin/esphome
ln -s /opt/esphome/.venv/bin/esphome /usr/local/bin/esphome
msg_ok "Linked esphome binary"

msg_info "正在创建 Service"
mkdir -p /root/config
cat <<EOF >/etc/systemd/system/esphomeDashboard.service
[Unit]
Description=ESPHome Dashboard
After=network.target

[Service]
ExecStart=/opt/esphome/.venv/bin/esphome dashboard /root/config/
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl enable -q --now esphomeDashboard
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
