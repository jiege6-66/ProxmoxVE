#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: kristocopani
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://www.inspircd.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "inspircd" "inspircd/inspircd" "binary" "latest" "/opt/inspircd" "inspircd_*.deb13u1_amd64.deb"

msg_info "正在配置 InspIRCd"
cat <<EOF >/etc/inspircd/inspircd.conf
<define name="networkDomain" value="helper-scripts.com">
<define name="networkName" value="Proxmox VE Helper-Scripts">

<server
        name="irc.&networkDomain;"
        description="&networkName; IRC server"
        network="&networkName;">
<admin
       name="Admin"
       description="Supreme Overlord"
       email="irc@&networkDomain;">
<bind address="" port="6667" type="clients">
EOF
msg_ok "已安装 InspIRCd"

motd_ssh
customize
cleanup_lxc
