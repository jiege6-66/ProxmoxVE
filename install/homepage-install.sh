#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://gethomepage.dev/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt-get install -y jq
msg_ok "已安装依赖"

NODE_VERSION="22" NODE_MODULE="pnpm@latest" setup_nodejs
fetch_and_deploy_gh_release "homepage" "gethomepage/homepage" "tarball"
RELEASE=$(get_latest_github_release "gethomepage/homepage")

msg_info "正在安装 Homepage (Patience)"
mkdir -p /opt/homepage/config
cd /opt/homepage
cp /opt/homepage/src/skeleton/* /opt/homepage/config
$STD pnpm install
export NEXT_PUBLIC_VERSION="v$RELEASE"
export NEXT_PUBLIC_REVISION="source"
export NEXT_PUBLIC_BUILDTIME=$(curl -fsSL https://api.github.com/repos/gethomepage/homepage/releases/latest | jq -r '.published_at')
export NEXT_TELEMETRY_DISABLED=1
$STD pnpm build
echo "HOMEPAGE_ALLOWED_HOSTS=localhost:3000,${LOCAL_IP}:3000" >/opt/homepage/.env
msg_ok "已安装 Homepage"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/homepage.service
[Unit]
Description=Homepage
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
User=root
WorkingDirectory=/opt/homepage/
ExecStart=pnpm start

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now homepage
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
