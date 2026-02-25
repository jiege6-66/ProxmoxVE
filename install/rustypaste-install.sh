#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: GoldenSpringness | MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/orhun/rustypaste

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "rustypaste" "orhun/rustypaste" "prebuild" "latest" "/opt/rustypaste" "*x86_64-unknown-linux-gnu.tar.gz"
fetch_and_deploy_gh_release "rustypaste-cli" "orhun/rustypaste-cli" "prebuild" "latest" "/usr/local/bin" "*x86_64-unknown-linux-gnu.tar.gz"

msg_info "正在设置 RustyPaste"
cd /opt/rustypaste
sed -i 's|^address = ".*"|address = "0.0.0.0:8000"|' config.toml
msg_ok "Set up RustyPaste"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/rustypaste.service
[Unit]
Description=rustypaste Service
After=network.target

[Service]
WorkingDirectory=/opt/rustypaste
ExecStart=/opt/rustypaste/rustypaste
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now rustypaste
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
