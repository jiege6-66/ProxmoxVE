#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: StellaeAlis
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/writefreely/writefreely

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y crudini
msg_ok "已安装依赖"

setup_mariadb
MARIADB_DB_NAME="writefreely" MARIADB_DB_USER="writefreely" setup_mariadb_db
fetch_and_deploy_gh_release "writefreely" "writefreely/writefreely" "prebuild" "latest" "/opt/writefreely" "writefreely_*_linux_amd64.tar.gz"

msg_info "正在设置 WriteFreely"
cd /opt/writefreely
$STD ./writefreely config generate
$STD ./writefreely keys generate
msg_ok "设置 WriteFreely"

msg_info "正在配置 WriteFreely"
$STD crudini --set config.ini server port 80
$STD crudini --set config.ini server bind $LOCAL_IP
$STD crudini --set config.ini database username $MARIADB_DB_USER
$STD crudini --set config.ini database password $MARIADB_DB_PASS
$STD crudini --set config.ini database database $MARIADB_DB_NAME
$STD crudini --set config.ini app host http://$LOCAL_IP:80
$STD ./writefreely db init
ln -s /opt/writefreely/writefreely /usr/local/bin/writefreely
msg_ok "已配置 WriteFreely"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/writefreely.service
[Unit]
Description=WriteFreely Service
After=syslog.target network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/writefreely
ExecStart=/opt/writefreely/writefreely
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now writefreely
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
