#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Termix-SSH/Termix

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y \
  build-essential \
  python3 \
  nginx \
  openssl \
  gettext-base
msg_ok "已安装依赖"

NODE_VERSION="22" setup_nodejs
fetch_and_deploy_gh_release "termix" "Termix-SSH/Termix"

msg_info "正在构建 Frontend"
cd /opt/termix
export COREPACK_ENABLE_DOWNLOAD_PROMPT=0
find public/fonts -name "*.ttf" ! -name "*Regular.ttf" ! -name "*Bold.ttf" ! -name "*Italic.ttf" -delete 2>/dev/null || true
$STD npm install --ignore-scripts --force
$STD npm cache clean --force
$STD npm run build
msg_ok "已构建 Frontend"

msg_info "正在构建 Backend"
$STD npm rebuild better-sqlite3 --force
$STD npm run build:backend
msg_ok "已构建 Backend"

msg_info "正在设置 Node 依赖"
cd /opt/termix
$STD npm ci --only=production --ignore-scripts --force
$STD npm rebuild better-sqlite3 bcryptjs --force
$STD npm cache clean --force
msg_ok "Set up Node 依赖"

msg_info "正在设置 Directories"
mkdir -p /opt/termix/data \
  /opt/termix/uploads \
  /opt/termix/html \
  /opt/termix/nginx \
  /opt/termix/nginx/logs \
  /opt/termix/nginx/cache \
  /opt/termix/nginx/client_body

cp -r /opt/termix/dist/* /opt/termix/html/ 2>/dev/null || true
cp -r /opt/termix/src/locales /opt/termix/html/locales 2>/dev/null || true
cp -r /opt/termix/public/fonts /opt/termix/html/fonts 2>/dev/null || true
msg_ok "Set up Directories"

msg_info "正在配置 Nginx"
curl -fsSL "https://raw.githubusercontent.com/Termix-SSH/Termix/main/docker/nginx.conf" -o /etc/nginx/nginx.conf
sed -i '/^master_process/d' /etc/nginx/nginx.conf
sed -i '/^pid \/app\/nginx/d' /etc/nginx/nginx.conf
sed -i 's|/app/html|/opt/termix/html|g' /etc/nginx/nginx.conf
sed -i 's|/app/nginx|/opt/termix/nginx|g' /etc/nginx/nginx.conf
sed -i 's|listen ${PORT};|listen 80;|g' /etc/nginx/nginx.conf

rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx
msg_ok "已配置 Nginx"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/termix.service
[Unit]
Description=Termix Backend
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/termix
Environment=NODE_ENV=production
Environment=DATA_DIR=/opt/termix/data
ExecStart=/usr/bin/node /opt/termix/dist/backend/backend/starter.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now termix
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
