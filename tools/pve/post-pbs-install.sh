#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: tteck (tteckster) | MickLesk (CanbiZ) | thost96
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

header_info() {
  clear
  cat <<"EOF"
    ____  ____ _____    ____             __     ____           __        ____
   / __ \/ __ ) ___/   / __ \____  _____/ /_   /  _/___  _____/ /_____ _/ / /
  / /_/ / __  \__ \   / /_/ / __ \/ ___/ __/   / // __ \/ ___/ __/ __ `/ / / 
 / ____/ /_/ /__/ /  / ____/ /_/ (__  ) /_   _/ // / / (__  ) /_/ /_/ / / /  
/_/   /_____/____/  /_/    \____/____/\__/  /___/_/ /_/____/\__/\__,_/_/_/   

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

set -euo pipefail
shopt -s inherit_errexit nullglob

msg_info() { echo -ne " ${HOLD} ${YW}$1..."; }
msg_ok() { echo -e "${BFR} ${CM} ${GN}$1${CL}"; }
msg_error() { echo -e "${BFR} ${CROSS} ${RD}$1${CL}"; }

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "post-pbs-install" "pve"

# ---- helpers ----
get_pbs_codename() {
  awk -F'=' '/^VERSION_CODENAME=/{print $2}' /etc/os-release
}

repo_state_list() {
  local repo="$1"
  local file=""
  local state="missing"
  for f in /etc/apt/sources.list /etc/apt/sources.list.d/*.list; do
    [[ -f "$f" ]] || continue
    if grep -q "$repo" "$f"; then
      file="$f"
      if grep -qE "^[^#].*${repo}" "$f"; then
        state="active"
      elif grep -qE "^#.*${repo}" "$f"; then
        state="disabled"
      fi
      break
    fi
  done
  echo "$state $file"
}

component_exists_in_sources() {
  local component="$1"
  grep -h -E "^[^#]*Components:[^#]*\b${component}\b" /etc/apt/sources.list.d/*.sources 2>/dev/null | grep -q .
}

# ---- main ----
main() {
  header_info
  echo -e "\n此脚本将 执行安装后例行程序.\n"
  while true; do
    read -rp "Start the Proxmox Backup Server Post Install Script (y/n)? " yn
    case $yn in
    [Yy]*) break ;;
    [Nn]*)
      clear
      exit
      ;;
    *) echo "Please answer yes or no." ;;
    esac
  done

  if command -v pve版本 >/dev/null 2>&1; then
    echo -e "\n🛑  PVE 已检测到, Wrong Script!\n"
    exit 1
  fi

  local CODENAME
  CODENAME="$(get_pbs_codename)"

  case "$CODENAME" in
  bookworm) start_routines_3 ;;
  trixie) start_routines_4 ;;
  *)
    msg_error "不支持的 Debian codename: $CODENAME"
    echo -e "支持的版本： bookworm (PBS 3.x) and trixie (PBS 4.x)"
    exit 1
    ;;
  esac
}

# ---- PBS 3.x (Bookworm) ----
start_routines_3() {
  header_info
  local VERSION="bookworm"

  # --- Debian sources ---
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PBS SOURCES" --menu \
    "Correct Debian sources for Proxmox Backup Server 3.x?" 14 58 2 "yes" " " "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "正在修正 Debian 源"
    cat <<EOF >/etc/apt/sources.list
deb http://deb.debian.org/debian ${VERSION} main contrib
deb http://deb.debian.org/debian ${VERSION}-updates main contrib
deb http://security.debian.org/debian-security ${VERSION}-security main contrib
EOF
    msg_ok "已修正 Debian 源"
    ;;
  no) msg_error "已选择不 正在修正 Debian 源" ;;
  esac

  # --- Enterprise repo ---
  read -r state file <<<"$(repo_state_list pbs-enterprise)"
  case $state in
  active)
    sed -i "s/^[^#].*pbs-enterprise/# &/" "$file"
    msg_ok "已禁用 'pbs-enterprise' repository"
    ;;
  disabled) msg_ok "'pbs-enterprise' already disabled" ;;
  missing)
    cat >/etc/apt/sources.list.d/pbs-enterprise.list <<EOF
# deb https://enterprise.proxmox.com/debian/pbs ${VERSION} pbs-enterprise
EOF
    msg_ok "已添加 'pbs-enterprise' repository (disabled)"
    ;;
  esac

  # --- No-subscription repo ---
  read -r state file <<<"$(repo_state_list pbs-no-subscription)"
  if [[ "$state" == "missing" ]]; then
    cat >/etc/apt/sources.list.d/pbs-install-repo.list <<EOF
deb http://download.proxmox.com/debian/pbs ${VERSION} pbs-no-subscription
EOF
    msg_ok "已启用 'pbs-no-subscription' repository"
  else
    msg_ok "'pbs-no-subscription' repository already present"
  fi

  # --- Test repo (legacy name pbstest) ---
  read -r state file <<<"$(repo_state_list pbstest)"
  if [[ "$state" == "missing" ]]; then
    cat >/etc/apt/sources.list.d/pbstest-for-beta.list <<EOF
# deb http://download.proxmox.com/debian/pbs ${VERSION} pbstest
EOF
    msg_ok "已添加 'pbstest' repository (disabled)"
  else
    msg_ok "'pbstest' repository already exists"
  fi

  post_routines_common
}

# ---- PBS 4.x (Trixie, deb822) ----
start_routines_4() {
  header_info
  local VERSION="trixie"

  # --- Debian sources (deb822) ---
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PBS SOURCES" --menu \
    "Correct Debian sources for Proxmox Backup Server 4.x (deb822)?" 14 58 2 "yes" " " "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "正在修正 Debian 源 (deb822)"
    rm -f /etc/apt/sources.list.d/*.list
    sed -i '/proxmox/d;/bookworm/d' /etc/apt/sources.list || true
    cat >/etc/apt/sources.list.d/debian.sources <<EOF
Types: deb
URIs: http://deb.debian.org/debian/
Suites: trixie trixie-updates
Components: main contrib non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg

Types: deb
URIs: http://security.debian.org/debian-security/
Suites: trixie-security
Components: main contrib non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
    msg_ok "已修正 Debian 源"
    ;;
  no) msg_error "已选择不 正在修正 Debian 源" ;;
  esac

  # --- Enterprise repo ---
  if component_exists_in_sources "pbs-enterprise"; then
    CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "PBS Enterprise Repository" --menu \
      "Enterprise repository detected.

You normally need a valid subscription for this.
Disable it (recommended)?" 14 58 2 "yes" " " "no" " " 3>&2 2>&1 1>&3)
    case $CHOICE in
    yes)
      msg_info "正在禁用 'pbs-enterprise' repository"
      # Use 已启用: false instead of commenting 到void malformed entry
      if grep -q "^已启用:" /etc/apt/sources.list.d/pbs-enterprise.sources 2>/dev/null; then
        sed -i 's/^已启用:.*/已启用: false/' /etc/apt/sources.list.d/pbs-enterprise.sources
      else
        echo "已启用: false" >>/etc/apt/sources.list.d/pbs-enterprise.sources
      fi
      msg_ok "已禁用 'pbs-enterprise' repository"
      ;;
    no)
      msg_error "Keeping 'pbs-enterprise' active (subscription required!)"
      ;;
    esac
  else
    cat >/etc/apt/sources.list.d/pbs-enterprise.sources <<EOF
Types: deb
URIs: https://enterprise.proxmox.com/debian/pbs
Suites: trixie
Components: pbs-enterprise
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
已启用: false
EOF
    msg_ok "已添加 'pbs-enterprise' repository (disabled)"
  fi

  # --- No-subscription repo ---
  if ! component_exists_in_sources "pbs-no-subscription"; then
    cat >/etc/apt/sources.list.d/proxmox.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/pbs
Suites: trixie
Components: pbs-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
    msg_ok "已添加 'pbs-no-subscription' repository"
  else
    msg_ok "'pbs-no-subscription' repository already present"
  fi

  # --- Test repo (pbs-test, renamed) ---
  if ! component_exists_in_sources "pbs-test"; then
    cat >/etc/apt/sources.list.d/pbs-test.sources <<EOF
Types: deb
URIs: http://download.proxmox.com/debian/pbs
Suites: trixie
Components: pbs-test
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
已启用: false
EOF
    msg_ok "已添加 'pbs-test' repository (disabled)"
  else
    msg_ok "'pbs-test' repository already present"
  fi

  post_routines_common
}

# ---- Shared routines ----
post_routines_common() {
  # Subscription nag
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "SUBSCRIPTION NAG" --menu \
    "Disable subscription nag in PBS UI?" 14 58 2 "yes" " " "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    whiptail --backtitle "Proxmox VE Helper Scripts" --msgbox \
      "Supporting the software's development team is essential.\nPlease consider buying a subscription." 10 58
    msg_info "正在禁用 subscription nag"
    echo "DPkg::Post-Invoke { \"if [ -s /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js ] && ! grep -q -F 'NoMoreNagging' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; then sed -i '/data\\.status/{s/\\!//;s/active/NoMoreNagging/}' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; fi\" };" >/etc/apt/apt.conf.d/no-nag-script
    msg_ok "已禁用 subscription nag (clear browser cache!)"
    ;;
  no)
    msg_error "已选择不 正在禁用 subscription nag"
    rm -f /etc/apt/apt.conf.d/no-nag-script 2>/dev/null
    ;;
  esac
  apt --reinstall install proxmox-widget-toolkit &>/dev/null || msg_error "Widget toolkit reinstall failed"

  # Update
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "UPDATE" --menu \
    "Update Proxmox Backup Server now?" 11 58 2 "yes" " " "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "正在更新 Proxmox Backup Server (Patience)"
    apt update &>/dev/null || msg_error "apt update failed"
    apt -y dist-upgrade &>/dev/null || msg_error "apt dist-upgrade failed"
    msg_ok "已更新 Proxmox Backup Server"
    ;;
  no) msg_error "已选择不 updating Proxmox Backup Server" ;;
  esac

  # Reminder
  whiptail --backtitle "Proxmox VE Helper Scripts" --title "Post-Install Reminder" --msgbox \
    "IMPORTANT:

Please run this script on every PBS node individually if you have multiple nodes.

After completing these steps, it is strongly recommended to REBOOT your node.

After the upgrade or post-install routines, always clear your browser cache or perform a hard reload (Ctrl+Shift+R) before using the PBS Web UI 到void UI display issues." 20 80

  # Reboot
  CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "REBOOT" --menu \
    "Reboot Proxmox Backup Server now? (recommended)" 11 58 2 "yes" " " "no" " " 3>&2 2>&1 1>&3)
  case $CHOICE in
  yes)
    msg_info "Rebooting PBS"
    sleep 2
    msg_ok "已完成 Post Install Routines"
    reboot
    ;;
  no)
    msg_error "已选择不 Reboot (Reboot recommended)"
    msg_ok "已完成 Post Install Routines"
    ;;
  esac
}

main
