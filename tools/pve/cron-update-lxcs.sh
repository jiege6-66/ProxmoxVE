#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/cron-update-lxcs.sh)"

clear
cat <<"EOF"
   ______                    __  __          __      __          __   _  ________
  / ____/________  ____     / / / /___  ____/ /___ _/ /____     / /  | |/ / ____/____
 / /   / ___/ __ \/ __ \   / / / / __ \/ __  / __ `/ __/ _ \   / /   |   / /   / ___/
/ /___/ /  / /_/ / / / /  / /_/ / /_/ / /_/ / /_/ / /_/  __/  / /___/   / /___(__  )
\____/_/   \____/_/ /_/   \____/ .___/\__,_/\__,_/\__/\___/  /_____/_/|_\____/____/
                              /_/
EOF

add() {
  while true; do
    read -p "此脚本将添加一个 crontab 计划，在每周日午夜更新所有 LXC。是否继续(y/n)?" yn
    case $yn in
    [Yy]*) break ;;
    [Nn]*) exit ;;
    *) echo "请回答 yes 或 no。" ;;
    esac
  done
  sh -c '(crontab -l -u root 2>/dev/null; echo "0 0 * * 0 PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/update-lxcs-cron.sh)\" >>/var/log/update-lxcs-cron.log 2>/dev/null") | crontab -u root -'
  clear
  echo -e "\n 查看 Cron 更新 LXC 日志: cat /var/log/update-lxcs-cron.log"
}

remove() {
  (crontab -l | grep -v "update-lxcs-cron.sh") | crontab -
  rm -rf /var/log/update-lxcs-cron.log
  echo "已从 Proxmox VE 移除 Crontab 计划"
}

OPTIONS=(Add "添加 Crontab 计划"
  Remove "移除 Crontab 计划")

CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "Cron 更新 LXC" --menu "选择一个选项:" 10 58 2 \
  "${OPTIONS[@]}" 3>&1 1>&2 2>&3)

case $CHOICE in
"Add")
  add
  ;;
"Remove")
  remove
  ;;
*)
  echo "正在退出..."
  exit 0
  ;;
esac
