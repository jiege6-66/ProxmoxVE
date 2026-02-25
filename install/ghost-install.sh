#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: fabrice1236
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ghost.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y \
  nginx \
  ca-certificates \
  libjemalloc2 \
  git
msg_ok "已安装依赖"

setup_mariadb
MARIADB_DB_NAME="ghost" MARIADB_DB_USER="ghostuser" setup_mariadb_db
NODE_VERSION="22" setup_nodejs

msg_info "正在安装 Ghost CLI"
$STD npm install ghost-cli@latest -g
msg_ok "已安装 Ghost CLI"

msg_info "正在创建 Service"
$STD adduser --disabled-password --gecos "Ghost user" ghost-user
$STD usermod -aG sudo ghost-user
echo "ghost-user ALL=(ALL) NOPASSWD:ALL" | tee /etc/sudoers.d/ghost-user
mkdir -p /var/www/ghost
chown -R ghost-user:ghost-user /var/www/ghost
chmod 775 /var/www/ghost
$STD sudo -u ghost-user -H sh -c "cd /var/www/ghost && ghost install --db=mysql --dbhost=localhost --dbuser=$MARIADB_DB_USER --dbpass=$MARIADB_DB_PASS --dbname=$MARIADB_DB_NAME --url=http://localhost:2368 --no-prompt --no-setup-nginx --no-setup-ssl --no-setup-mysql --enable --start --ip 0.0.0.0"
rm /etc/sudoers.d/ghost-user
msg_ok "正在创建 Service"

motd_ssh
customize
cleanup_lxc
