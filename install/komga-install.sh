#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: madelyn (DysfunctionalProgramming)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://komga.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装 dependencies"
$STD apt -y install \
  libarchive-dev \
  libjxl-dev \
  libheif-dev \
  libwebp-dev
msg_ok "已安装 dependencies"

JAVA_VERSION="23" setup_java
fetch_and_deploy_gh_release "kepubify" "pgaskin/kepubify" "singlefile" "latest" "/usr/bin" "kepubify-linux-64bit"
USE_ORIGINAL_FILENAME="true" fetch_and_deploy_gh_release "komga-org" "gotson/komga" "singlefile" "latest" "/opt/komga" "komga*.jar"
mv /opt/komga/komga-*.jar /opt/komga/komga.jar

msg_info "正在创建 Service"
cat <<EOF >/etc/systemd/system/komga.service
[Unit]
Description=Komga
After=syslog.target network.target

[Service]
Type=simple
WorkingDirectory=/opt/komga/
Environment=LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu
ExecStart=/usr/bin/java --enable-native-access=ALL-UNNAMED -jar -Xmx2g komga.jar
TimeoutStopSec=20
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now komga
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
