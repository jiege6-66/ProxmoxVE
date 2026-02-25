#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://www.wireguard.com/

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y git
msg_ok "已安装依赖"

msg_info "正在安装 WireGuard"
$STD apt install -y wireguard wireguard-tools net-tools iptables
DEBIAN_FRONTEND=noninteractive apt -o Dpkg::Options::="--force-confnew" install -y iptables-persistent &>/dev/null
$STD netfilter-persistent reload
msg_ok "已安装 WireGuard"

read -r -p "${TAB3}Would you like to add WGDashboard? <y/N> " prompt
if [[ "${prompt,,}" =~ ^(y|yes)$ ]]; then
  git clone -q https://github.com/WGDashboard/WGDashboard.git /etc/wgdashboard

  msg_info "正在安装 WGDashboard"
  cd /etc/wgdashboard/src
  chmod u+x wgd.sh
  $STD ./wgd.sh install
  . /etc/os-release
  if [ "$VERSION_CODENAME" = "trixie" ]; then
    echo "net.ipv4.ip_forward=1" >>/etc/sysctl.d/sysctl.conf
    $STD sysctl -p /etc/sysctl.d/sysctl.conf
  else
    echo "net.ipv4.ip_forward=1" >>/etc/sysctl.conf
    $STD sysctl -p /etc/sysctl.conf
  fi
  msg_ok "已安装 WGDashboard"

  msg_info "Create Example Config for WGDashboard"
  private_key=$(wg genkey)
  cat <<EOF >/etc/wireguard/wg0.conf
[Interface]
PrivateKey = ${private_key}
Address = 10.0.0.1/24
SaveConfig = true
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE;
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE;
ListenPort = 51820
EOF
  msg_ok "已创建 Example Config for WGDashboard"

  msg_info "正在创建 Service"
  cat <<EOF >/etc/systemd/system/wg-dashboard.service
[Unit]
After=syslog.target network-online.target
Wants=wg-quick.target
ConditionPathIsDirectory=/etc/wireguard

[Service]
Type=forking
PIDFile=/etc/wgdashboard/src/gunicorn.pid
WorkingDirectory=/etc/wgdashboard/src
ExecStart=/etc/wgdashboard/src/wgd.sh start
ExecStop=/etc/wgdashboard/src/wgd.sh stop
ExecReload=/etc/wgdashboard/src/wgd.sh restart
TimeoutSec=120
PrivateTmp=yes
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now wg-dashboard
  msg_ok "已创建 Service"
fi

motd_ssh
customize
cleanup_lxc
