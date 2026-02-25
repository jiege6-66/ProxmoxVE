#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: BrynnJKnight
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://verdaccio.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y build-essential
msg_ok "已安装依赖"

NODE_VERSION="22" NODE_MODULE="verdaccio" setup_nodejs

msg_info "正在配置 Verdaccio"
mkdir -p /opt/verdaccio/config
mkdir -p /opt/verdaccio/storage
cat <<EOF >/opt/verdaccio/config/config.yaml
# Verdaccio configuration
storage: /opt/verdaccio/storage
auth:
  htpasswd:
    file: /opt/verdaccio/storage/htpasswd
    max_users: 1000
uplinks:
  npmjs:
    url: https://registry.npmjs.org/
packages:
  '@*/*':
    access: \$all
    publish: \$authenticated
    proxy: npmjs
  '**':
    access: \$all
    publish: \$authenticated
    proxy: npmjs
middlewares:
  audit:
    enabled: true
logs:
  - {type: stdout, format: pretty, level: http}
listen:
  - 0.0.0.0:4873
web:
  enable: true
  title: Verdaccio
  gravatar: true
  sort_packages: asc
  login: true
EOF
chown -R root:root /opt/verdaccio
chmod -R 755 /opt/verdaccio
msg_ok "已配置 Verdaccio"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/verdaccio.service
[Unit]
Description=Verdaccio lightweight private npm proxy registry
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/verdaccio --config /opt/verdaccio/config/config.yaml
Restart=on-failure
StandardOutput=journal
StandardError=journal
SyslogIdentifier=verdaccio
KillMode=control-group

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now verdaccio
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
