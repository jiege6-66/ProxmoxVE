#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://heimdall.site/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y apt-transport-https
msg_ok "已安装依赖"

PHP_VERSION="8.4" PHP_FPM="YES" setup_php
setup_composer
fetch_and_deploy_gh_release "Heimdall" "linuxserver/Heimdall" "tarball"

msg_info "正在设置 Heimdall-Dashboard"
cd /opt/Heimdall
cp .env.example .env
$STD php artisan key:generate
msg_ok "设置 Heimdall-Dashboard"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/heimdall.service
[Unit]
Description=Heimdall
After=network.target

[Service]
Restart=always
RestartSec=5
Type=simple
User=root
WorkingDirectory=/opt/Heimdall
ExecStart=/usr/bin/php artisan serve --port 7990 --host 0.0.0.0
TimeoutStopSec=30

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now heimdall
cd /opt/Heimdall
export COMPOSER_ALLOW_SUPERUSER=1
$STD composer dump-autoload
systemctl restart heimdall.service
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
