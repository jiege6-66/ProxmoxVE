#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://www.audiobookshelf.org/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y ffmpeg
msg_ok "已安装依赖"

setup_deb822_repo \
  "audiobookshelf" \
  "https://advplyr.github.io/audiobookshelf-ppa/KEY.gpg" \
  "https://advplyr.github.io/audiobookshelf-ppa" \
  "./"

msg_info "设置 audiobookshelf"
$STD apt install -y audiobookshelf
echo "FFMPEG_PATH=/usr/bin/ffmpeg" >>/etc/default/audiobookshelf
echo "FFPROBE_PATH=/usr/bin/ffprobe" >>/etc/default/audiobookshelf
systemctl restart audiobookshelf
msg_ok "设置 audiobookshelf"

motd_ssh
customize
cleanup_lxc
