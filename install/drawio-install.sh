#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://www.drawio.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os
setup_hwaccel

msg_info "正在安装依赖"
$STD apt install -y tomcat11
msg_ok "已安装依赖"

USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "drawio" "jgraph/drawio" "singlefile" "latest" "/var/lib/tomcat11/webapps" "draw.war"

motd_ssh
customize
cleanup_lxc
