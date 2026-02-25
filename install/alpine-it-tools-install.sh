#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: nicedevil007 (NiceDevil)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://it-tools.tech/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apk add --no-cache \
  nginx \
  python3
msg_ok "已安装依赖"

msg_info "正在安装 IT-Tools"
RELEASE=$(curl -fsSL https://api.github.com/repos/sharevb/it-tools/releases/latest | grep '"tag_name":' | cut -d '"' -f4)
curl -fsSL "https://github.com/sharevb/it-tools/releases/download/${RELEASE}/it-tools-${RELEASE#v}.zip" -o it-tools.zip
mkdir -p /usr/share/nginx/html
$STD unzip it-tools.zip -d /tmp/
mv /tmp/dist/* /usr/share/nginx/html
cat <<'EOF' >/etc/nginx/http.d/default.conf
server {
  listen 80;
  server_name localhost;
  root /usr/share/nginx/html;
  index index.html;
  
  location / {
      try_files $uri $uri/ /index.html;
  }
}
EOF
$STD rc-update add nginx default
$STD rc-service nginx start
echo "${RELEASE}" >/opt/"${APPLICATION}"_version.txt
msg_ok "已安装 IT-Tools"

motd_ssh
customize

msg_info "正在清理"
rm -rf /tmp/dist
rm -f it-tools.zip
$STD apk cache clean
msg_ok "已清理"
