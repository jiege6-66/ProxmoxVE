#!/usr/bin/env bash
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    ____                                               __  ____                                __
   / __ \_________  ________  ______________  _____   /  |/  (_)_____________  _________  ____/ /__
  / /_/ / ___/ __ \/ ___/ _ \/ ___/ ___/ __ \/ ___/  / /|_/ / / ___/ ___/ __ \/ ___/ __ \/ __  / _ \
 / ____/ /  / /_/ / /__/  __(__  |__  ) /_/ / /     / /  / / / /__/ /  / /_/ / /__/ /_/ / /_/ /  __/
/_/   /_/   \____/\___/\___/____/____/\____/_/     /_/  /_/_/\___/_/   \____/\___/\____/\__,_/\___/

EOF
}

RD=$(echo "\033[01;31m")
YW=$(echo "\033[33m")
GN=$(echo "\033[1;92m")
CL=$(echo "\033[m")
BFR="\\r\\033[K"
HOLD="-"
CM="${GN}✓${CL}"
CROSS="${RD}✗${CL}"

msg_info() { echo -ne " ${HOLD} ${YW}$1..."; }
msg_ok() { echo -e "${BFR} ${CM} ${GN}$1${CL}"; }
msg_error() { echo -e "${BFR} ${CROSS} ${RD}$1${CL}"; }

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "microcode" "pve"

header_info
current_microcode=$(journalctl -k | grep -i 'microcode: Current revision:' | grep -oP 'Current revision: \K0x[0-9a-f]+')
[ -z "$current_microcode" ] && current_microcode="Not found."

intel() {
  if ! dpkg -s iucode-tool >/dev/null 2>&1; then
    msg_info "正在安装 iucode-tool (Intel 微码更新器)"
    apt-get install -y iucode-tool &>/dev/null
    msg_ok "已安装 iucode-tool"
  else
    msg_ok "Intel iucode-tool 已安装"
    sleep 1
  fi

  intel_microcode=$(curl -fsSL "https://ftp.debian.org/debian/pool/non-free-firmware/i/intel-microcode//" | grep -o 'href="[^"]*amd64.deb"' | sed 's/href="//;s/"//')
  [ -z "$intel_microcode" ] && {
    whiptail --backtitle "Proxmox VE Helper Scripts" --title "未找到微码" --msgbox "似乎未找到微码包\n请稍后重试。" 10 68
    msg_info "正在退出"
    sleep 1
    msg_ok "完成"
    exit
  }

  MICROCODE_MENU=()
  MSG_MAX_LENGTH=0

  while read -r TAG ITEM; do
    OFFSET=2
    ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
    MICROCODE_MENU+=("$TAG" "$ITEM " "OFF")
  done < <(echo "$intel_microcode")

  microcode=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "当前微码版本:${current_microcode}" --radiolist "\n选择要安装的微码包:\n" 16 $((MSG_MAX_LENGTH + 58)) 6 "${MICROCODE_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"')

  [ -z "$microcode" ] && {
    whiptail --backtitle "Proxmox VE Helper Scripts" --title "未选择微码" --msgbox "似乎未选择微码包" 10 68
    msg_info "正在退出"
    sleep 1
    msg_ok "完成"
    exit
  }

  msg_info "正在下载 Intel 处理器微码包 $microcode"
  curl -fsSL "http://ftp.debian.org/debian/pool/non-free-firmware/i/intel-microcode/$microcode" -o $(basename "http://ftp.debian.org/debian/pool/non-free-firmware/i/intel-microcode/$microcode")
  msg_ok "已下载 Intel 处理器微码包 $microcode"

  msg_info "正在安装 $microcode (请耐心等待)"
  dpkg -i $microcode &>/dev/null
  msg_ok "已安装 $microcode"

  msg_info "正在清理"
  rm $microcode
  msg_ok "已清理"
  echo -e "\n为了应用更改，需要重启系统。\n"
}

amd() {
  amd_microcode=$(curl -fsSL "https://ftp.debian.org/debian/pool/non-free-firmware/a/amd64-microcode///" | grep -o 'href="[^"]*amd64.deb"' | sed 's/href="//;s/"//')

  [ -z "$amd_microcode" ] && {
    whiptail --backtitle "Proxmox VE Helper Scripts" --title "未找到微码" --msgbox "似乎未找到微码包\n请稍后重试。" 10 68
    msg_info "正在退出"
    sleep 1
    msg_ok "完成"
    exit
  }

  MICROCODE_MENU=()
  MSG_MAX_LENGTH=0

  while read -r TAG ITEM; do
    OFFSET=2
    ((${#ITEM} + OFFSET > MSG_MAX_LENGTH)) && MSG_MAX_LENGTH=${#ITEM}+OFFSET
    MICROCODE_MENU+=("$TAG" "$ITEM " "OFF")
  done < <(echo "$amd_microcode")

  microcode=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "当前微码版本:${current_microcode}" --radiolist "\n选择要安装的微码包:\n" 16 $((MSG_MAX_LENGTH + 58)) 6 "${MICROCODE_MENU[@]}" 3>&1 1>&2 2>&3 | tr -d '"')

  [ -z "$microcode" ] && {
    whiptail --backtitle "Proxmox VE Helper Scripts" --title "未选择微码" --msgbox "似乎未选择微码包" 10 68
    msg_info "正在退出"
    sleep 1
    msg_ok "完成"
    exit
  }

  msg_info "正在下载 AMD 处理器微码包 $microcode"
  curl -fsSL "https://ftp.debian.org/debian/pool/non-free-firmware/a/amd64-microcode/$microcode" -o $(basename "https://ftp.debian.org/debian/pool/non-free-firmware/a/amd64-microcode/$microcode")
  msg_ok "已下载 AMD 处理器微码包 $microcode"

  msg_info "正在安装 $microcode (请耐心等待)"
  dpkg -i $microcode &>/dev/null
  msg_ok "已安装 $microcode"

  msg_info "正在清理"
  rm $microcode
  msg_ok "已清理"
  echo -e "\n为了应用更改，需要重启系统。\n"
}

if ! command -v pveversion >/dev/null 2>&1; then
  header_info
  msg_error "未检测到 PVE！"
  exit
fi

whiptail --backtitle "Proxmox VE Helper Scripts" --title "Proxmox VE 处理器微码" --yesno "这将检查 CPU 微码包并提供安装选项。是否继续？" 10 58

msg_info "正在检查 CPU 供应商"
cpu=$(lscpu | grep -oP 'Vendor ID:\s*\K\S+' | head -n 1)
if [ "$cpu" == "GenuineIntel" ]; then
  msg_ok "检测到 ${cpu}"
  sleep 1
  intel
elif [ "$cpu" == "AuthenticAMD" ]; then
  msg_ok "检测到 ${cpu}"
  sleep 1
  amd
else
  msg_error "不支持 ${cpu}"
  exit
fi
