#!/usr/bin/env bash

# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster) | MickLesk (CanbiZ)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
   ________
  / ____/ /___ _____  ________  _____
 / / __/ / __ `/ __ \/ ___/ _ \/ ___/
/ /_/ / / /_/ / / / / /__/  __(__  )
\____/_/\__,_/_/ /_/\___/\___/____/

EOF
}

APP="Glances"
YW=$(echo "\033[33m")
GN=$(echo "\033[1;92m")
RD=$(echo "\033[01;31m")
BL=$(echo "\033[36m")
CL=$(echo "\033[m")
CM="${GN}✔️${CL}"
CROSS="${RD}✖️${CL}"
INFO="${BL}ℹ️${CL}"

function msg_info() { echo -e "${INFO} ${YW}$1...${CL}"; }
function msg_ok() { echo -e "${CM} ${GN}$1${CL}"; }
function msg_error() { echo -e "${CROSS} ${RD}$1${CL}"; }

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "glances" "addon"

get_lxc_ip() {
  if command -v hostname >/dev/null 2>&1 && hostname -I 2>/dev/null; then
    hostname -I | awk '{print $1}'
  elif command -v ip >/dev/null 2>&1; then
    ip -4 addr show scope global | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1
  else
    echo "127.0.0.1"
  fi
}
IP=$(get_lxc_ip)

install_glances_debian() {
  msg_info "正在安装依赖项"
  apt-get update >/dev/null 2>&1
  apt-get install -y gcc lm-sensors wireless-tools curl >/dev/null 2>&1
  msg_ok "已安装依赖项"

  msg_info "正在设置 Python + uv"
  source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/tools.func)
  setup_uv PYTHON_VERSION="3.12"
  msg_ok "已设置 Python + uv"

  msg_info "正在安装 $APP（包含 Web UI）"
  cd /opt
  mkdir -p glances
  cd glances
  uv venv --clear
  source .venv/bin/activate >/dev/null 2>&1
  uv pip install --upgrade pip wheel setuptools >/dev/null 2>&1
  uv pip install "glances[web]" >/dev/null 2>&1
  deactivate
  msg_ok "已安装 $APP"

  msg_info "正在创建 systemd 服务"
  cat <<EOF >/etc/systemd/system/glances.service
[Unit]
Description=Glances - An eye on your system
After=network.target

[Service]
Type=simple
ExecStart=/opt/glances/.venv/bin/glances -w
Restart=on-failure
WorkingDirectory=/opt/glances

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable -q --now glances
  msg_ok "已创建 systemd 服务"

  echo -e "\n$APP 现在运行于: http://$IP:61208\n"
}

# update on Debian/Ubuntu
update_glances_debian() {
  if [[ ! -d /opt/glances/.venv ]]; then
    msg_error "$APP 未安装"
    exit 1
  fi
  msg_info "正在更新 $APP"
  cd /opt/glances
  source .venv/bin/activate
  uv pip install --upgrade "glances[web]" >/dev/null 2>&1
  deactivate
  systemctl restart glances
  msg_ok "更新成功！"
}

# uninstall on Debian/Ubuntu
uninstall_glances_debian() {
  msg_info "正在卸载 $APP"
  systemctl disable -q --now glances || true
  rm -f /etc/systemd/system/glances.service
  rm -rf /opt/glances
  msg_ok "已移除 $APP"
}

# install on Alpine
install_glances_alpine() {
  msg_info "正在安装依赖项"
  apk update >/dev/null 2>&1
  $STD apk add --no-cache \
    gcc musl-dev linux-headers python3-dev \
    python3 py3-pip py3-virtualenv lm-sensors wireless-tools curl >/dev/null 2>&1
  msg_ok "已安装依赖项"

  msg_info "正在设置 Python + uv"
  source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/tools.func)
  setup_uv PYTHON_VERSION="3.12"
  msg_ok "已设置 Python + uv"

  msg_info "正在安装 $APP（包含 Web UI）"
  cd /opt
  mkdir -p glances
  cd glances
  uv venv --clear
  source .venv/bin/activate
  uv pip install --upgrade pip wheel setuptools >/dev/null 2>&1
  uv pip install "glances[web]" >/dev/null 2>&1
  deactivate
  msg_ok "已安装 $APP"

  msg_info "正在创建 OpenRC 服务"
  cat <<'EOF' >/etc/init.d/glances
#!/sbin/openrc-run
command="/opt/glances/.venv/bin/glances"
command_args="-w"
command_background="yes"
pidfile="/run/glances.pid"
name="glances"
description="Glances monitoring tool"
EOF
  chmod +x /etc/init.d/glances
  rc-update add glances default
  rc-service glances start
  msg_ok "已创建 OpenRC 服务"

  echo -e "\n$APP 现在运行于: http://$IP:61208\n"
}

# update on Alpine
update_glances_alpine() {
  if [[ ! -d /opt/glances/.venv ]]; then
    msg_error "$APP 未安装"
    exit 1
  fi
  msg_info "正在更新 $APP"
  cd /opt/glances
  source .venv/bin/activate
  uv pip install --upgrade "glances[web]" >/dev/null 2>&1
  deactivate
  rc-service glances restart
  msg_ok "更新成功！"
}

# uninstall on Alpine
uninstall_glances_alpine() {
  msg_info "正在卸载 $APP"
  rc-service glances stop || true
  rc-update del glances || true
  rm -f /etc/init.d/glances
  rm -rf /opt/glances
  msg_ok "已移除 $APP"
}

# options menu
OPTIONS=(Install "安装 $APP"
  Update "更新 $APP"
  Uninstall "卸载 $APP")

CHOICE=$(whiptail --backtitle "Proxmox VE Helper Scripts" --title "$APP" --menu "选择一个选项:" 12 58 3 \
  "${OPTIONS[@]}" 3>&1 1>&2 2>&3 || true)

# OS detection
if grep -qi "alpine" /etc/os-release; then
  case "$CHOICE" in
  Install) install_glances_alpine ;;
  Update) update_glances_alpine ;;
  Uninstall) uninstall_glances_alpine ;;
  *) exit 0 ;;
  esac
else
  case "$CHOICE" in
  Install) install_glances_debian ;;
  Update) update_glances_debian ;;
  Uninstall) uninstall_glances_debian ;;
  *) exit 0 ;;
  esac
fi
