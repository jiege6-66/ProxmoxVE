#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Florianb63
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://itsm-ng.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

setup_mariadb

msg_info "正在设置 database"
DB_NAME=itsmng_db
DB_USER=itsmng
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
mariadb-tzinfo-to-sql /usr/share/zoneinfo | mariadb mysql
mariadb -u root -e "CREATE DATABASE $DB_NAME;"
mariadb -u root -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_PASS';"
mariadb -u root -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mariadb -u root -e "GRANT SELECT ON \`mysql\`.\`time_zone_name\` TO '$DB_USER'@'localhost'; FLUSH PRIVILEGES;"
{
  echo "ITSM-NG Database Credentials"
  echo "Database: $DB_NAME"
  echo "Username: $DB_USER"
  echo "Password: $DB_PASS"
} >>~/itsmng_db.creds
msg_ok "Set up database"

msg_info "设置 ITSM-NG Repository"
setup_deb822_repo \
  "itsm-ng" \
  "http://deb.itsm-ng.org/pubkey.gpg" \
  "http://deb.itsm-ng.org/$(get_os_info id)/" \
  "$(get_os_info codename)"
msg_ok "设置 ITSM-NG Repository"

msg_info "正在安装 ITSM-NG"
$STD apt install -y itsm-ng
cd /usr/share/itsm-ng
$STD php bin/console db:install --db-name=$DB_NAME --db-user=$DB_USER --db-password=$DB_PASS --no-interaction
$STD a2dissite 000-default.conf
echo "* * * * * php /usr/share/itsm-ng/front/cron.php" | crontab -
msg_ok "已安装 ITSM-NG"

msg_info "正在配置 PHP"
PHP_VERSION=$(ls /etc/php/ | grep -E '^[0-9]+\.[0-9]+$' | head -n 1)
PHP_INI="/etc/php/$PHP_VERSION/apache2/php.ini"
sed -i 's/^upload_max_filesize = .*/upload_max_filesize = 20M/' $PHP_INI
sed -i 's/^post_max_size = .*/post_max_size = 20M/' $PHP_INI
sed -i 's/^max_execution_time = .*/max_execution_time = 60/' $PHP_INI
sed -i 's/^[;]*max_input_vars *=.*/max_input_vars = 5000/' "$PHP_INI"
sed -i 's/^memory_limit = .*/memory_limit = 256M/' $PHP_INI
sed -i 's/^;\?\s*session.cookie_httponly\s*=.*/session.cookie_httponly = On/' $PHP_INI
systemctl restart apache2
rm -rf /usr/share/itsm-ng/install
msg_ok "已配置 PHP"

motd_ssh
customize
cleanup_lxc
