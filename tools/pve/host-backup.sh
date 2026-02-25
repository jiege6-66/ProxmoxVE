#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
   __ __         __    ___           __
  / // /__  ___ / /_  / _ )___ _____/ /____ _____
 / _  / _ \(_-</ __/ / _  / _ `/ __/  '_/ // / _ \
/_//_/\___/___/\__/ /____/\_,_/\__/_/\_\\_,_/ .__/
                                           /_/
EOF
}

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "host-backup" "pve"

# Function to perform backup
function perform_backup {
  local BACKUP_PATH
  local DIR
  local DIR_DASH
  local BACKUP_FILE
  local selected_directories=()

  # Get backup path from user
  BACKUP_PATH=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "\n默认为 /root/\n例如：/mnt/backups/" 11 68 --title "备份目标目录：" 3>&1 1>&2 2>&3) || return

  # Default to /root/ if no input
  BACKUP_PATH="${BACKUP_PATH:-/root/}"

  # Get directory to work in from user
  DIR=$(whiptail --backtitle "Proxmox VE Helper Scripts" --inputbox "\n默认为 /etc/\n例如：/root/, /var/lib/pve-cluster/ 等" 11 68 --title "工作目录：" 3>&1 1>&2 2>&3) || return

  # Default to /etc/ if no input
  DIR="${DIR:-/etc/}"

  DIR_DASH=$(echo "$DIR" | tr '/' '-')
  BACKUP_FILE="$(hostname)${DIR_DASH}backup"

  # Build a list of directories for backup
  local CTID_MENU=()
  CTID_MENU=("ALL" "备份所有文件夹" "OFF")
  while read -r dir; do
    CTID_MENU+=("$(basename "$dir")" "$dir " "OFF")
  done < <(ls -d "${DIR}"*)

  # Allow the user to select directories
  local HOST_BACKUP
  while [ -z "${HOST_BACKUP:+x}" ]; do
    HOST_BACKUP=$(whiptail --backtitle "Proxmox VE Host Backup" --title "在 ${DIR} 目录中工作 " --checklist \
      "\n选择要备份的文件/目录:\n" 16 $(((${#DIRNAME} + 2) + 88)) 6 "${CTID_MENU[@]}" 3>&1 1>&2 2>&3) || return

    for selected_dir in ${HOST_BACKUP//\"/}; do
      if [[ "$selected_dir" == "ALL" ]]; then
        # if ALL was chosen, secure all folders
        selected_directories=("${DIR}"*/)
        break
      else
        selected_directories+=("${DIR}$selected_dir")
      fi
    done
  done

  # Perform the backup
  header_info
  echo -e "这将在\e[1;33m $BACKUP_PATH \e[0m为这些文件和目录创建备份\e[1;33m ${selected_directories[*]} \e[0m"
  read -p "按 ENTER 继续..."
  header_info
  echo "正在工作..."
  tar -czf "$BACKUP_PATH$BACKUP_FILE-$(date +%Y_%m_%dT%H_%M).tar.gz" --absolute-names "${selected_directories[@]}"
  header_info
  echo -e "\n完成"
  echo -e "\e[1;33m \n当备份仍存储在主机上时，备份将失效。\n \e[0m"
  sleep 2
}

# Main script execution loop
while true; do
  if (whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE Host Backup" --yesno "这将为指定目录中的特定文件和目录创建备份。是否继续？" 10 88); then
    perform_backup
  else
    break
  fi
done
