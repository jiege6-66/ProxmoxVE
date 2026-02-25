#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT |  https://github.com/tteck/Proxmox/raw/main/LICENSE
# Source: https://github.com/odoo/odoo

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y python3-lxml wkhtmltopdf
curl -fsSL "http://archive.ubuntu.com/ubuntu/pool/universe/l/lxml-html-clean/python3-lxml-html-clean_0.1.1-1_all.deb" -o /opt/python3-lxml-html-clean.deb
$STD dpkg -i /opt/python3-lxml-html-clean.deb
msg_ok "已安装依赖"

PG_VERSION="18" setup_postgresql

RELEASE=$(curl -fsSL https://nightly.odoo.com/ | grep -oE 'href="[0-9]+\.[0-9]+/nightly"' | head -n1 | cut -d'"' -f2 | cut -d/ -f1)
LATEST_VERSION=$(curl -fsSL "https://nightly.odoo.com/${RELEASE}/nightly/deb/" |
  grep -oP "odoo_${RELEASE}\.\d+_all\.deb" |
  sed -E "s/odoo_(${RELEASE}\.[0-9]+)_all\.deb/\1/" |
  sort -V |
  tail -n1)

msg_info "设置 Odoo $RELEASE"
curl -fsSL https://nightly.odoo.com/${RELEASE}/nightly/deb/odoo_${RELEASE}.latest_all.deb -o /opt/odoo.deb
$STD apt install -y /opt/odoo.deb
msg_ok "设置 Odoo $RELEASE"

msg_info "设置 PostgreSQL Database"
DB_NAME="odoo"
DB_USER="odoo_usr"
DB_PASS="$(openssl rand -base64 18 | cut -c1-13)"
$STD sudo -u postgres psql -c "CREATE DATABASE $DB_NAME;"
$STD sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;"
$STD sudo -u postgres psql -c "ALTER DATABASE $DB_NAME OWNER TO $DB_USER;"
$STD sudo -u postgres psql -c "ALTER USER $DB_USER WITH SUPERUSER;"
{
  echo "Odoo-Credentials"
  echo -e "Odoo Database User: $DB_USER"
  echo -e "Odoo Database Password: $DB_PASS"
  echo -e "Odoo Database Name: $DB_NAME"
} >>~/odoo.creds
msg_ok "设置 PostgreSQL"

msg_info "正在配置 Odoo"
sed -i \
  -e "s|^;*db_host *=.*|db_host = localhost|" \
  -e "s|^;*db_port *=.*|db_port = 5432|" \
  -e "s|^;*db_user *=.*|db_user = $DB_USER|" \
  -e "s|^;*db_password *=.*|db_password = $DB_PASS|" \
  /etc/odoo/odoo.conf
$STD sudo -u odoo odoo -c /etc/odoo/odoo.conf -d odoo -i base --stop-after-init
rm -f /opt/odoo.deb
rm -f /opt/python3-lxml-html-clean.deb
echo "${LATEST_VERSION}" >/opt/${APPLICATION}_version.txt
msg_ok "已配置 Odoo"

msg_info "正在重启 Odoo"
systemctl restart odoo
msg_ok "已重启 Odoo"

motd_ssh
customize
cleanup_lxc
