#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Dolibarr/dolibarr/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt-get install -y \
  php-imap \
  debconf-utils
msg_ok "已安装依赖"

setup_mariadb

msg_info "正在设置 Database"
ROOT_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
$STD mariadb -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$ROOT_PASS'; flush privileges;"
{
  echo "Dolibarr DB Credentials"
  echo "MariaDB Root Password: $ROOT_PASS"
} >>~/dolibarr.creds
msg_ok "Set up database"

msg_info "设置 Dolibarr"
BASE="https://sourceforge.net/projects/dolibarr/files/Dolibarr%20installer%20for%20Debian-Ubuntu%20(DoliDeb)/"
RELEASE=$(curl -fsSL "$BASE" | grep -oP '(?<=/Dolibarr%20installer%20for%20Debian-Ubuntu%20%28DoliDeb%29/)\d+(\.\d+)+(?=/)' | sort -V | tail -n1)
FILE=$(curl -fsSL "${BASE}${RELEASE}/" | grep -oP 'dolibarr_[^"]+_all.deb' | head -n1)
curl -fsSL "https://altushost-swe.dl.sourceforge.net/project/dolibarr/Dolibarr%20installer%20for%20Debian-Ubuntu%20(DoliDeb)/${RELEASE}/${FILE}?viasf=1" -o ""$FILE""
echo "dolibarr dolibarr/reconfigure-webserver multiselect apache2" | debconf-set-selections
$STD apt-get install ./$FILE -y
$STD apt install -f
rm -rf ~/$FILE
echo "${RELEASE}" >"/opt/${APPLICATION}_version.txt"
msg_ok "设置 Dolibarr"

motd_ssh
customize
cleanup_lxc
