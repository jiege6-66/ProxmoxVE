#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/saltstack/salt

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在设置 Salt Repo"
setup_deb822_repo \
  "salt" \
  "https://packages.broadcom.com/artifactory/api/security/keypair/SaltProjectKey/public" \
  "https://packages.broadcom.com/artifactory/saltproject-deb" \
  "stable"
msg_ok "设置 Salt Repo"

msg_info "正在安装 Salt"
RELEASE=$(get_latest_github_release "saltstack/salt")
cat <<EOF >/etc/apt/preferences.d/salt-pin-1001
Package: salt-*
Pin: version ${RELEASE}
Pin-Priority: 1001
EOF
$STD apt install -y salt-master
echo "${RELEASE}" >/~.salt
msg_ok "已安装 Salt"

motd_ssh
customize
cleanup_lxc
