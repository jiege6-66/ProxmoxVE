#!/usr/bin/env bash

set -eEuo pipefail

function header_info() {
  clear
  cat <<"EOF"
    _______ __                     __                    ______     _
   / ____(_) /__  _______  _______/ /____  ____ ___     /_  __/____(_)___ ___
  / /_  / / / _ \/ ___/ / / / ___/ __/ _ \/ __ `__ \     / / / ___/ / __ `__ \
 / __/ / / /  __(__  ) /_/ (__  ) /_/  __/ / / / / /    / / / /  / / / / / / /
/_/   /_/_/\___/____/\__, /____/\__/\___/_/ /_/ /_/    /_/ /_/  /_/_/ /_/ /_/
                    /____/
EOF
}

BL="\033[36m"
RD="\033[01;31m"
GN="\033[1;92m"
CL="\033[m"

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "fstrim" "pve"

LOGFILE="/var/log/fstrim.log"
touch "$LOGFILE"
chmod 600 "$LOGFILE"
echo -e "\n----- $(date '+%Y-%m-%d %H:%M:%S') | fstrim Run by $(whoami) on $(hostname) -----" >>"$LOGFILE"

header_info
echo "加载中..."

whiptail --backtitle "Proxmox VE Helper Scripts" \
  --title "关于 fstrim (LXC)" \
  --msgbox "'fstrim' 命令将未使用的块释放回存储设备。这仅对 SSD、NVMe、Thin-LVM 或支持 discard/TRIM 的存储上的容器有意义。\n\n如果您的根文件系统或容器磁盘位于经典 HDD、厚 LVM 或不支持的存储类型上，运行 fstrim 将不会有任何效果。\n\n建议：\n- 仅在启用了 discard 的 SSD、NVMe 或精简配置存储上使用 fstrim。\n- 对于 ZFS，请确保在您的池上设置了 'autotrim=on'。\n" 16 88

ROOT_FS=$(df -Th "/" | awk 'NR==2 {print $2}')
if [ "$ROOT_FS" != "ext4" ]; then
  whiptail --backtitle "Proxmox VE Helper Scripts" \
    --title "警告" \
    --yesno "根文件系统不是 ext4 ($ROOT_FS)。\n仍然继续？" 12 80 || exit 1
fi

NODE=$(hostname)
EXCLUDE_MENU=()
STOPPED_MENU=()
MAX_NAME_LEN=0
MAX_STAT_LEN=0

# Build arrays with one pct list
mapfile -t CTLINES < <(pct list | awk 'NR>1')

for LINE in "${CTLINES[@]}"; do
  CTID=$(awk '{print $1}' <<<"$LINE")
  STATUS=$(awk '{print $2}' <<<"$LINE")
  NAME=$(awk '{print $3}' <<<"$LINE")
  ((${#NAME} > MAX_NAME_LEN)) && MAX_NAME_LEN=${#NAME}
  ((${#STATUS} > MAX_STAT_LEN)) && MAX_STAT_LEN=${#STATUS}
done

FMT="%-${MAX_NAME_LEN}s | %-${MAX_STAT_LEN}s"

for LINE in "${CTLINES[@]}"; do
  CTID=$(awk '{print $1}' <<<"$LINE")
  STATUS=$(awk '{print $2}' <<<"$LINE")
  NAME=$(awk '{print $3}' <<<"$LINE")
  DESC=$(printf "$FMT" "$NAME" "$STATUS")
  EXCLUDE_MENU+=("$CTID" "$DESC" "OFF")
  if [[ "$STATUS" == "stopped" ]]; then
    STOPPED_MENU+=("$CTID" "$DESC" "OFF")
  fi
done

excluded_containers_raw=$(whiptail --backtitle "Proxmox VE Helper Scripts" \
  --title "Containers on $NODE" \
  --checklist "\n选择要跳过修剪的容器:\n" \
  20 $((MAX_NAME_LEN + MAX_STAT_LEN + 20)) 12 "${EXCLUDE_MENU[@]}" 3>&1 1>&2 2>&3)
[ $? -ne 0 ] && exit
read -ra EXCLUDED <<<$(echo "$excluded_containers_raw" | tr -d '"')

TO_START=()
if [ ${#STOPPED_MENU[@]} -gt 0 ]; then
  for ((i = 0; i < ${#STOPPED_MENU[@]}; i += 3)); do
    CTID="${STOPPED_MENU[i]}"
    DESC="${STOPPED_MENU[i + 1]}"
    if [[ " ${EXCLUDED[*]} " =~ " $CTID " ]]; then
      continue
    fi
    header_info
    echo -e "${BL}[信息]${GN} 容器 $CTID ($DESC) 当前已停止。${CL}"
    read -rp "临时启动以进行 fstrim？[y/N]: " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
      TO_START+=("$CTID")
    fi
  done
fi

declare -A WAS_STOPPED
for ct in "${TO_START[@]}"; do
  WAS_STOPPED["$ct"]=1
done

function trim_container() {
  local container="$1"
  local name="$2"
  header_info
  echo -e "${BL}[信息]${GN} 正在修剪 ${BL}$container${CL} \n"

  local before_trim after_trim
  local lv_name="vm-${container}-disk-0"
  if lvs --noheadings -o lv_name 2>/dev/null | grep -qw "$lv_name"; then
    before_trim=$(lvs --noheadings -o lv_name,data_percent 2>/dev/null | awk -v ctid="$lv_name" '$1 == ctid {gsub(/%/, "", $2); print $2}')
    [[ -n "$before_trim" ]] && echo -e "${RD}修剪前数据 $before_trim%${CL}" || echo -e "${RD}修剪前数据: 不可用${CL}"
  else
    before_trim=""
    echo -e "${RD}修剪前数据: 不可用（非 LVM 存储）${CL}"
  fi

  local fstrim_output
  fstrim_output=$(pct fstrim "$container" 2>&1)
  if echo "$fstrim_output" | grep -qi "not supported"; then
    echo -e "${RD}此存储不支持 fstrim！${CL}"
  elif echo "$fstrim_output" | grep -Eq '([0-9]+(\.[0-9]+)?\s*[KMGT]?B)'; then
    echo -e "${GN}fstrim 结果: $fstrim_output${CL}"
  else
    echo -e "${RD}fstrim 结果: $fstrim_output${CL}"
  fi

  if lvs --noheadings -o lv_name 2>/dev/null | grep -qw "$lv_name"; then
    after_trim=$(lvs --noheadings -o lv_name,data_percent 2>/dev/null | awk -v ctid="$lv_name" '$1 == ctid {gsub(/%/, "", $2); print $2}')
    [[ -n "$after_trim" ]] && echo -e "${GN}修剪后数据 $after_trim%${CL}" || echo -e "${GN}修剪后数据: 不可用${CL}"
  else
    after_trim=""
    echo -e "${GN}修剪后数据: 不可用（非 LVM 存储）${CL}"
  fi

  # Logging
  echo "$(date '+%Y-%m-%d %H:%M:%S') | CTID=$container | Name=$name | Before=${before_trim:-N/A}% | After=${after_trim:-N/A}% | fstrim: $fstrim_output" >>"$LOGFILE"
  sleep 0.5
}

for LINE in "${CTLINES[@]}"; do
  CTID=$(awk '{print $1}' <<<"$LINE")
  STATUS=$(awk '{print $2}' <<<"$LINE")
  NAME=$(awk '{print $3}' <<<"$LINE")
  if [[ " ${EXCLUDED[*]} " =~ " $CTID " ]]; then
    header_info
    echo -e "${BL}[信息]${GN} 跳过 $CTID ($NAME, 已排除)${CL}"
    sleep 0.5
    continue
  fi
  if pct config "$CTID" | grep -q "template:"; then
    header_info
    echo -e "${BL}[信息]${GN} 跳过 $CTID ($NAME, 模板)${CL}\n"
    sleep 0.5
    continue
  fi
  if [[ "$STATUS" != "running" ]]; then
    if [[ -n "${WAS_STOPPED[$CTID]:-}" ]]; then
      header_info
      echo -e "${BL}[信息]${GN} 正在启动 $CTID ($NAME) 以进行修剪...${CL}"
      pct start "$CTID"
      sleep 2
    else
      header_info
      echo -e "${BL}[信息]${GN} 跳过 $CTID ($NAME, 未运行, 未选择)${CL}"
      sleep 0.5
      continue
    fi
  fi

  trim_container "$CTID" "$NAME"

  if [[ -n "${WAS_STOPPED[$CTID]:-}" ]]; then
    read -rp "修剪后再次停止 LXC $CTID ($NAME)？[Y/n]: " answer
    if [[ ! "$answer" =~ ^[Nn]$ ]]; then
      header_info
      echo -e "${BL}[信息]${GN} 再次停止 $CTID ($NAME)...${CL}"
      pct stop "$CTID"
      sleep 1
    else
      header_info
      echo -e "${BL}[信息]${GN} 按要求保持 $CTID ($NAME) 运行。${CL}"
      sleep 1
    fi
  fi
done

header_info
echo -e "${GN}完成，LXC 容器已修剪。${CL} \n"
echo -e "${BL}如果您想查看完整日志: cat $LOGFILE${CL}"
exit 0
