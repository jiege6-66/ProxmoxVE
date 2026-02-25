#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: EEJoshua
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://swizzin.ltd/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_warn "警告：此脚本将运行来自第三方来源的外部安装器 (https://swizzin.ltd/)."
msg_warn "以下代码不由我们的仓库维护或审计。"
msg_warn "如果您有任何疑虑，请在继续之前查看安装器代码："
msg_custom "${TAB3}${GATEWAY}${BGN}${CL}" "\e[1;34m" "→  https://s5n.sh"
echo
read -r -p "${TAB3}Do you want to continue? [y/N]: " CONFIRM
if [[ ! "$CONFIRM" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  msg_error "用户已中止。未做任何更改。"
  exit 10
fi
bash <(curl -fsSL https://s5n.sh)

motd_ssh
customize
cleanup_lxc
