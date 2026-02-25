#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT
# https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE

clear
if ! command -v pveversion >/dev/null 2>&1; then
  echo -e "⚠️  从 Proxmox Shell 运行"
  exit
fi
while true; do
  read -p "用于将所有数据从 Home Assistant Container LXC 复制到 Home Assistant Core LXC。是否继续(y/n)?" yn
  case $yn in
  [Yy]*) break ;;
  [Nn]*) exit ;;
  *) echo "请回答 yes 或 no。" ;;
  esac
done
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail
shopt -s expand_aliases
alias die='EXIT=$? LINE=$LINENO error_exit'
trap die ERR
trap cleanup EXIT

function error_exit() {
  trap - ERR
  local DEFAULT='发生未知故障。'
  local REASON="\e[97m${1:-$DEFAULT}\e[39m"
  local FLAG="\e[91m[错误] \e[93m$EXIT@$LINE"
  msg "$FLAG $REASON"
  exit $EXIT
}
function warn() {
  local REASON="\e[97m$1\e[39m"
  local FLAG="\e[93m[警告]\e[39m"
  msg "$FLAG $REASON"
}
function info() {
  local REASON="$1"
  local FLAG="\e[36m[信息]\e[39m"
  msg "$FLAG $REASON"
}
function msg() {
  local TEXT="$1"
  echo -e "$TEXT"
}
function cleanup() {
  [ -d "${CTID_FROM_PATH:-}" ] && pct unmount $CTID_FROM
  [ -d "${CTID_TO_PATH:-}" ] && pct unmount $CTID_TO
  popd >/dev/null
  rm -rf $TEMP_DIR
}
TEMP_DIR=$(mktemp -d)
pushd $TEMP_DIR >/dev/null

TITLE="Home Assistant LXC 数据复制"
while read -r line; do
  TAG=$(echo "$line" | awk '{print $1}')
  ITEM=$(echo "$line" | awk '{print substr($0,36)}')
  OFFSET=2
  if [[ $((${#ITEM} + $OFFSET)) -gt ${MSG_MAX_LENGTH:-} ]]; then
    MSG_MAX_LENGTH=$((${#ITEM} + $OFFSET))
  fi
  CTID_MENU+=("$TAG" "$ITEM " "OFF")
done < <(pct list | awk 'NR>1')
while [ -z "${CTID_FROM:+x}" ]; do
  CTID_FROM=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "$TITLE" --radiolist \
    "\n您想从哪个 HA Container LXC 复制？\n" \
    16 $(($MSG_MAX_LENGTH + 23)) 6 \
    "${CTID_MENU[@]}" 3>&1 1>&2 2>&3)
done
while [ -z "${CTID_TO:+x}" ]; do
  CTID_TO=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "$TITLE" --radiolist \
    "\n您想复制到哪个 HA Core LXC？\n" \
    16 $(($MSG_MAX_LENGTH + 23)) 6 \
    "${CTID_MENU[@]}" 3>&1 1>&2 2>&3)
done
for i in ${!CTID_MENU[@]}; do
  [ "${CTID_MENU[$i]}" == "$CTID_FROM" ] &&
    CTID_FROM_HOSTNAME=$(sed 's/[[:space:]]*$//' <<<${CTID_MENU[$i + 1]})
  [ "${CTID_MENU[$i]}" == "$CTID_TO" ] &&
    CTID_TO_HOSTNAME=$(sed 's/[[:space:]]*$//' <<<${CTID_MENU[$i + 1]})
done
whiptail --backtitle "Proxmox VE Helper Scripts" --defaultno --title "$TITLE" --yesno \
  "您确定要在以下 LXC 之间复制数据吗？
$CTID_FROM (${CTID_FROM_HOSTNAME}) -> $CTID_TO (${CTID_TO_HOSTNAME})
版本: 2022.10.02" 13 50
info "Home Assistant 数据从 '$CTID_FROM' 到 '$CTID_TO'"
if [ $(pct status $CTID_TO | sed 's/.* //') == 'running' ]; then
  msg "正在停止 '$CTID_TO'..."
  pct stop $CTID_TO
fi
msg "正在挂载容器磁盘..."
DOCKER_PATH=/var/lib/docker/volumes/hass_config/_data
CORE_PATH=/root/.homeassistant
CTID_FROM_PATH=$(pct mount $CTID_FROM | sed -n "s/.*'\(.*\)'/\1/p") ||
  die "挂载 LXC '${CTID_FROM}' 的根磁盘时出现问题。"
[ -d "${CTID_FROM_PATH}${DOCKER_PATH}" ] ||
  die "未找到 '$CTID_FROM' 中的 Home Assistant 目录。"
CTID_TO_PATH=$(pct mount $CTID_TO | sed -n "s/.*'\(.*\)'/\1/p") ||
  die "挂载 LXC '${CTID_TO}' 的根磁盘时出现问题。"
[ -d "${CTID_TO_PATH}${CORE_PATH}" ] ||
  die "未找到 '$CTID_TO' 中的 Home Assistant 目录。"

msg "正在复制数据..."
RSYNC_OPTIONS=(
  --archive
  --hard-links
  --sparse
  --xattrs
  --no-inc-recursive
  --info=progress2
)
msg "<======== Docker 数据 ========>"
rsync ${RSYNC_OPTIONS[*]} ${CTID_FROM_PATH}${DOCKER_PATH} ${CTID_TO_PATH}${CORE_PATH}
echo -en "\e[1A\e[0K\e[1A\e[0K"

info "成功传输数据。"

# Use to copy all data from a Home Assistant Container LXC to a Home Assistant Core LXC
# run from the Proxmox Shell
# bash -c "$(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/mainmain/tools/copy-data//home-assistant-container-copy-data-home-assistant-core.sh)"
