#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: andrej-kocijan (Andrej Kocijan)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/redlib-org/redlib

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

fetch_and_deploy_gh_release "redlib" "redlib-org/redlib" "prebuild" "latest" "/opt/redlib" "redlib-x86_64-unknown-linux-musl.tar.gz"

msg_info "正在配置 Redlib"
cat <<EOF >/opt/redlib/redlib.conf
############################################
# Redlib Instance Configuration File
# Uncomment and edit values as needed
############################################

## Instance settings
ADDRESS=0.0.0.0
PORT=5252                           # Integer (0-65535) - Internal port
#REDLIB_SFW_ONLY=off                # ["on", "off"] - Filter all NSFW content
#REDLIB_BANNER=                     # String - Displayed on instance info page
#REDLIB_ROBOTS_DISABLE_INDEXING=off # ["on", "off"] - Disable search engine indexing
#REDLIB_PUSHSHIFT_FRONTEND=undelete.pullpush.io # Pushshift frontend for removed links
#REDLIB_ENABLE_RSS=off              # ["on", "off"] - Enable RSS feed generation
#REDLIB_FULL_URL=                   # String - Needed for proper RSS URLs

## Default user settings
#REDLIB_DEFAULT_THEME=system        # Theme (system, light, dark, black, dracula, nord, laserwave, violet, gold, rosebox, gruvboxdark, gruvboxlight, tokyoNight, icebergDark, doomone, libredditBlack, libredditDark, libredditLight)
#REDLIB_DEFAULT_FRONT_PAGE=default  # ["default", "popular", "all"]
#REDLIB_DEFAULT_LAYOUT=card         # ["card", "clean", "compact"]
#REDLIB_DEFAULT_WIDE=off            # ["on", "off"]
#REDLIB_DEFAULT_POST_SORT=hot       # ["hot", "new", "top", "rising", "controversial"]
#REDLIB_DEFAULT_COMMENT_SORT=confidence # ["confidence", "top", "new", "controversial", "old"]
#REDLIB_DEFAULT_BLUR_SPOILER=off    # ["on", "off"]
#REDLIB_DEFAULT_SHOW_NSFW=off       # ["on", "off"]
#REDLIB_DEFAULT_BLUR_NSFW=off       # ["on", "off"]
#REDLIB_DEFAULT_USE_HLS=off         # ["on", "off"]
#REDLIB_DEFAULT_HIDE_HLS_NOTIFICATION=off # ["on", "off"]
#REDLIB_DEFAULT_AUTOPLAY_VIDEOS=off # ["on", "off"]
#REDLIB_DEFAULT_SUBSCRIPTIONS=      # Example: sub1+sub2+sub3
#REDLIB_DEFAULT_HIDE_AWARDS=off     # ["on", "off"]
#REDLIB_DEFAULT_DISABLE_VISIT_REDDIT_CONFIRMATION=off # ["on", "off"]
#REDLIB_DEFAULT_HIDE_SCORE=off      # ["on", "off"]
#REDLIB_DEFAULT_HIDE_SIDEBAR_AND_SUMMARY=off # ["on", "off"]
#REDLIB_DEFAULT_FIXED_NAVBAR=on     # ["on", "off"]
#REDLIB_DEFAULT_REMOVE_DEFAULT_FEEDS=off # ["on", "off"]
EOF
msg_ok "已配置 Redlib"

msg_info "正在创建 Redlib Service"
cat <<EOF >/etc/init.d/redlib
#!/sbin/openrc-run

name="Redlib"
description="Redlib Service"
command="/opt/redlib/redlib"
pidfile="/run/redlib.pid"
supervisor="supervise-daemon"
command_background="yes"

depend() {
    need net
}

start_pre() {

    set -a
    . /opt/redlib/redlib.conf
    set +a

    : ${ADDRESS:=0.0.0.0}
    : ${PORT:=5252}

    command_args="-a ${ADDRESS} -p ${PORT}"
}
EOF
$STD chmod +x /etc/init.d/redlib
$STD rc-update add redlib default
msg_ok "已创建 Redlib Service"

msg_info "正在启动 Redlib Service"
$STD rc-service redlib start
msg_ok "已启动 Redlib Service"

motd_ssh
customize

msg_info "正在清理"
$STD apk cache clean
msg_ok "已清理"
