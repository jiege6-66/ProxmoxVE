#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.seerr.dev/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt-get install -y build-essential
msg_ok "已安装依赖"

fetch_and_deploy_gh_release "seerr" "seerr-team/seerr" "tarball"
pnpm_desired=$(grep -Po '"pnpm":\s*"\K[^"]+' /opt/seerr/package.json)
NODE_VERSION="22" NODE_MODULE="pnpm@$pnpm_desired" setup_nodejs

msg_info "正在安装 Seerr (Patience)"
export CYPRESS_INSTALL_BINARY=0
cd /opt/seerr
$STD pnpm install --frozen-lockfile
export NODE_OPTIONS="--max-old-space-size=3072"
$STD pnpm build
mkdir -p /etc/seerr/
cat <<EOF >/etc/seerr/seerr.conf
## Seerr's default port is 5055, if you want to use both, change this.
## specify on which port to listen
PORT=5055

## specify on which interface to listen, by default seerr listens on all interfaces
HOST=0.0.0.0

## Uncomment if you want to force Node.js to resolve IPv4 before IPv6 (advanced users only)
# FORCE_IPV4_FIRST=true
EOF
msg_ok "已安装 Seerr"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/seerr.service
[Unit]
Description=Seerr Service
Wants=network-online.target
After=network-online.target

[Service]
EnvironmentFile=/etc/seerr/seerr.conf
Environment=NODE_ENV=production
Type=exec
Restart=on-failure
WorkingDirectory=/opt/seerr
ExecStart=/usr/bin/node dist/index.js

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now seerr
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
