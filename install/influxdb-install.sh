#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.influxdata.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在设置 InfluxDB Repository"
setup_deb822_repo \
  "influxdata" \
  "https://repos.influxdata.com/influxdata-archive.key" \
  "https://repos.influxdata.com/debian" \
  "stable"
msg_ok "Set up InfluxDB Repository"

read -r -p "${TAB3}Which version of InfluxDB to install? (1, 2 or 3) " prompt
if [[ $prompt == "3" ]]; then
  INFLUX="3"
elif [[ $prompt == "2" ]]; then
  INFLUX="2"
else
  INFLUX="1"
fi

msg_info "正在安装 InfluxDB v${INFLUX}"
if [[ $INFLUX == "3" ]]; then
  $STD apt install -y influxdb3-core
  systemctl enable -q --now influxdb3-core
elif [[ $INFLUX == "2" ]]; then
  $STD apt install -y influxdb2
  systemctl enable -q --now influxdb
else
  $STD apt install -y influxdb
  download_file "https://dl.influxdata.com/chronograf/releases/chronograf_1.10.8_amd64.deb" "${HOME}/chronograf_1.10.8_amd64.deb"
  $STD dpkg -i "${HOME}/chronograf_1.10.8_amd64.deb"
  rm -rf "${HOME}/chronograf_1.10.8_amd64.deb"
  systemctl enable -q --now influxdb
fi
msg_ok "已安装 InfluxDB"

read -r -p "${TAB3}Would you like to add Telegraf? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  msg_info "正在安装 Telegraf"
  $STD apt install -y telegraf
  msg_ok "已安装 Telegraf"
fi

motd_ssh
customize
cleanup_lxc
