#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.commafeed.com/#/welcome

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y rsync
msg_ok "已安装依赖"

JAVA_VERSION="25" setup_java
fetch_and_deploy_gh_release "commafeed" "Athou/commafeed" "prebuild" "latest" "/opt/commafeed" "commafeed-*-h2-jvm.zip"

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/commafeed.service
[Unit]
Description=CommaFeed Service
After=network.target

[Service]
ExecStart=java -Xminf0.05 -Xmaxf0.1 -jar quarkus-run.jar
WorkingDirectory=/opt/commafeed/
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now commafeed
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
