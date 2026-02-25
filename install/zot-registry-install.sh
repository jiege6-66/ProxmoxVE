#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://zotregistry.dev/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y apache2-utils
msg_ok "已安装依赖"

fetch_and_deploy_gh_release "zot" "project-zot/zot" "singlefile" "latest" "/usr/bin" "zot-linux-amd64"

msg_info "正在配置 Zot Registry"
mkdir -p /etc/zot
curl -fsSL https://raw.githubusercontent.com/project-zot/zot/refs/heads/main/examples/config-ui.json -o /etc/zot/config.json
ZOTPASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD htpasswd -b -B -c /etc/zot/htpasswd admin "$ZOTPASSWORD"
{
  echo "Zot-Credentials"
  echo "Zot User: admin"
  echo "Zot Password: $ZOTPASSWORD"
} >>~/zot.creds
msg_ok "已配置 Zot Registry"

msg_info "设置 Service"
cat <<EOF >/etc/systemd/system/zot.service
[Unit]
Description=OCI Distribution Registry
Documentation=https://zotregistry.dev/
After=network.target auditd.service local-fs.target

[Service]
Type=simple
ExecStart=/usr/bin/zot serve /etc/zot/config.json
Restart=on-failure
User=root
LimitNOFILE=500000
MemoryHigh=2G
MemoryMax=4G

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now zot
msg_ok "设置 Service"

motd_ssh
customize
cleanup_lxc
