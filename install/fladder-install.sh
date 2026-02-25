#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: wendyliga
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/DonutWare/Fladder

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y nginx
msg_ok "已安装依赖"

fetch_and_deploy_gh_release "Fladder" "DonutWare/Fladder" "prebuild" "latest" "/opt/fladder" "Fladder-Web-*.zip"

msg_info "正在配置 Nginx"
cat <<EOF >/etc/nginx/conf.d/fladder.conf
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    server_name _;

    root /opt/fladder;
    index index.html;

    location / {
        try_files \$uri \$uri/ /index.html;
    }
}
EOF
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-available/default
systemctl enable -q --now nginx
systemctl reload nginx
msg_ok "已配置 Nginx"

motd_ssh
customize
cleanup_lxc
