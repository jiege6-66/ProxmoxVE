#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck
# Co-Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.rabbitmq.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y apt-transport-https
msg_ok "已安装依赖"

setup_deb822_repo \
  "rabbitmq" \
  "https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA" \
  "https://deb1.rabbitmq.com/rabbitmq-server/debian/trixie" \
  "trixie"

msg_info "正在设置 RabbitMQ"
$STD apt install -y \
  erlang-base erlang-asn1 erlang-crypto erlang-eldap erlang-ftp \
  erlang-inets erlang-mnesia erlang-os-mon erlang-parsetools \
  erlang-public-key erlang-runtime-tools erlang-snmp erlang-ssl \
  erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl
$STD apt install -y --fix-missing rabbitmq-server
msg_ok "设置 RabbitMQ "

msg_info "正在启动 Service"
systemctl enable -q --now rabbitmq-server
msg_ok "已启动 Service"

msg_info "正在启用 RabbitMQ Management Plugin"
$STD rabbitmq-plugins enable rabbitmq_management
$STD rabbitmqctl enable_feature_flag all
msg_ok "已启用 RabbitMQ Management Plugin"

msg_info "正在创建 User"
$STD rabbitmqctl add_user proxmox proxmox
$STD rabbitmqctl set_user_tags proxmox administrator
$STD rabbitmqctl set_permissions -p / proxmox ".*" ".*" ".*"
msg_ok "已创建 User"

motd_ssh
customize
cleanup_lxc
