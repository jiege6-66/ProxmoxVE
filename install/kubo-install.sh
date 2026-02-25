#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# Co-Author: ulmentflam
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/ipfs/kubo

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "kubo" "ipfs/kubo" "prebuild" "latest" "/usr/local/kubo" "kubo*linux-amd64.tar.gz"

msg_info "正在配置 IPFS"
$STD ln -s /usr/local/kubo/ipfs /usr/local/bin/ipfs
$STD ipfs init
ipfs config Addresses.API /ip4/0.0.0.0/tcp/5001
ipfs config Addresses.Gateway /ip4/0.0.0.0/tcp/8080
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Origin "[\"http://${LOCAL_IP}:5001\", \"http://localhost:3000\", \"http://127.0.0.1:5001\", \"https://webui.ipfs.io\", \"http://0.0.0.0:5001\"]"
ipfs config --json API.HTTPHeaders.Access-Control-Allow-Methods '["PUT", "POST"]'
msg_ok "已配置 IPFS"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/ipfs.service
[Unit]
Description=IPFS Daemon
After=syslog.target network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/ipfs daemon
Restart=on-failure
Environment=HOME=/root
[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now ipfs
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
