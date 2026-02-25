#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info() {
  clear
  cat <<"EOF"
    _______ __     ____                                       ____                    __
   / ____(_) /__  / __ )_________ _      __________  _____   / __ \__  ______ _____  / /___  ______ ___
  / /_  / / / _ \/ __  / ___/ __ \ | /| / / ___/ _ \/ ___/  / / / / / / / __ `/ __ \/ __/ / / / __ `__ \
 / __/ / / /  __/ /_/ / /  / /_/ / |/ |/ (__  )  __/ /     / /_/ / /_/ / /_/ / / / / /_/ /_/ / / / / / /
/_/   /_/_/\___/_____/_/   \____/|__/|__/____/\___/_/      \___\_\__,_/\__,_/_/ /_/\__/\__,_/_/ /_/ /_/

EOF
}

YW=$(echo "\033[33m")
GN=$(echo "\033[1;92m")
RD=$(echo "\033[01;31m")
BL=$(echo "\033[36m")
CL=$(echo "\033[m")
CM="${GN}✔️${CL}"
CROSS="${RD}✖️${CL}"
INFO="${BL}ℹ️${CL}"

APP="FileBrowser Quantum"
INSTALL_PATH="/usr/local/bin/filebrowser"
CONFIG_PATH="/usr/local/community-scripts/fq-config.yaml"
DEFAULT_PORT=8080
SRC_DIR="/"
TMP_BIN="/tmp/filebrowser.$$"

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "filebrowser-quantum" "addon"

# Get primary IP
IFACE=$(ip -4 route | awk '/default/ {print $5; exit}')
IP=$(ip -4 addr show "$IFACE" | awk '/inet / {print $2}' | cut -d/ -f1 | head -n 1)
[[ -z "$IP" ]] && IP=$(hostname -I | awk '{print $1}')
[[ -z "$IP" ]] && IP="127.0.0.1"

# OS Detection
if [[ -f "/etc/alpine-release" ]]; then
  OS="Alpine"
  SERVICE_PATH="/etc/init.d/filebrowser"
  PKG_MANAGER="apk add --no-cache"
elif [[ -f "/etc/debian_version" ]]; then
  OS="Debian"
  SERVICE_PATH="/etc/systemd/system/filebrowser.service"
  PKG_MANAGER="apt-get install -y"
else
  echo -e "${CROSS} 检测到不支持的操作系统。正在退出。"
  exit 1
fi

header_info

function msg_info() { echo -e "${INFO} ${YW}$1...${CL}"; }
function msg_ok() { echo -e "${CM} ${GN}$1${CL}"; }
function msg_error() { echo -e "${CROSS} ${RD}$1${CL}"; }

# Detect legacy FileBrowser installation
LEGACY_DB="/usr/local/community-scripts/filebrowser.db"
LEGACY_BIN="/usr/local/bin/filebrowser"
LEGACY_SERVICE_DEB="/etc/systemd/system/filebrowser.service"
LEGACY_SERVICE_ALP="/etc/init.d/filebrowser"

if [[ -f "$LEGACY_DB" || -f "$LEGACY_BIN" && ! -f "$CONFIG_PATH" ]]; then
  echo -e "${YW}⚠️ 检测到旧版 FileBrowser 安装。${CL}"
  echo -n "卸载旧版 FileBrowser 并继续安装 Quantum 版本？(y/n): "
  read -r remove_legacy
  if [[ "${remove_legacy,,}" =~ ^(y|yes)$ ]]; then
    msg_info "正在卸载旧版 FileBrowser"
    if [[ -f "$LEGACY_SERVICE_DEB" ]]; then
      systemctl disable --now filebrowser.service &>/dev/null
      rm -f "$LEGACY_SERVICE_DEB"
    elif [[ -f "$LEGACY_SERVICE_ALP" ]]; then
      rc-service filebrowser stop &>/dev/null
      rc-update del filebrowser &>/dev/null
      rm -f "$LEGACY_SERVICE_ALP"
    fi
    rm -f "$LEGACY_BIN" "$LEGACY_DB"
    msg_ok "已移除旧版 FileBrowser"
  else
    echo -e "${YW}❌ 用户已中止安装。${CL}"
    exit 0
  fi
fi

# Existing installation
if [[ -f "$INSTALL_PATH" ]]; then
  echo -e "${YW}⚠️ ${APP} 已安装。${CL}"
  echo -n "卸载 ${APP}? (y/N): "
  read -r uninstall_prompt
  if [[ "${uninstall_prompt,,}" =~ ^(y|yes)$ ]]; then
    msg_info "正在卸载 ${APP}"
    if [[ "$OS" == "Debian" ]]; then
      systemctl disable --now filebrowser.service &>/dev/null
      rm -f "$SERVICE_PATH"
    else
      rc-service filebrowser stop &>/dev/null
      rc-update del filebrowser &>/dev/null
      rm -f "$SERVICE_PATH"
    fi
    rm -f "$INSTALL_PATH" "$CONFIG_PATH"
    msg_ok "${APP} 已卸载。"
    exit 0
  fi

  echo -n "更新 ${APP}? (y/N): "
  read -r update_prompt
  if [[ "${update_prompt,,}" =~ ^(y|yes)$ ]]; then
    msg_info "正在更新 ${APP}"
    if ! command -v curl &>/dev/null; then $PKG_MANAGER curl &>/dev/null; fi
    curl -fsSL https://github.com/gtsteffaniak/filebrowser/releases/latest/download/linux-amd64-filebrowser -o "$TMP_BIN"
    chmod +x "$TMP_BIN"
    mv -f "$TMP_BIN" /usr/local/bin/filebrowser
    msg_ok "已更新 ${APP}"
    exit 0
  else
    echo -e "${YW}⚠️ 已跳过更新。正在退出。${CL}"
    exit 0
  fi
fi

echo -e "${YW}⚠️ ${APP} 未安装。${CL}"
echo -n "输入端口号（默认：${DEFAULT_PORT}）: "
read -r PORT
PORT=${PORT:-$DEFAULT_PORT}

echo -n "安装 ${APP}? (y/n): "
read -r install_prompt
if ! [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  echo -e "${YW}⚠️ 已跳过安装。正在退出。${CL}"
  exit 0
fi

msg_info "正在 ${OS} 上安装 ${APP}"
$PKG_MANAGER curl ffmpeg &>/dev/null
curl -fsSL https://github.com/gtsteffaniak/filebrowser/releases/latest/download/linux-amd64-filebrowser -o "$TMP_BIN"
chmod +x "$TMP_BIN"
mv -f "$TMP_BIN" /usr/local/bin/filebrowser
msg_ok "已安装 ${APP}"

msg_info "正在准备配置目录"
mkdir -p /usr/local/community-scripts
chown root:root /usr/local/community-scripts
chmod 755 /usr/local/community-scripts
msg_ok "目录已准备"

echo -n "使用无身份验证？(y/N): "
read -r noauth_prompt

# === YAML CONFIG GENERATION ===
if [[ "${noauth_prompt,,}" =~ ^(y|yes)$ ]]; then
  cat <<EOF >"$CONFIG_PATH"
server:
  port: $PORT
  sources:
    - path: "$SRC_DIR"      
      name: "RootFS"
      config:
        denyByDefault: false
        disableIndexing: false
        indexingIntervalMinutes: 240
        conditionals:
          rules:
            - neverWatchPath: "/proc"
            - neverWatchPath: "/sys"
            - neverWatchPath: "/dev"
            - neverWatchPath: "/run"
            - neverWatchPath: "/tmp"
            - neverWatchPath: "/lost+found"
auth:
  methods:
    noauth: true
EOF
  msg_ok "已配置为无身份验证"
else
  cat <<EOF >"$CONFIG_PATH"
server:
  port: $PORT
  sources:
    - path: "$SRC_DIR"
      name: "RootFS"
      config:
        denyByDefault: false
        disableIndexing: false
        indexingIntervalMinutes: 240
        conditionals:
          rules:
            - neverWatchPath: "/proc"
            - neverWatchPath: "/sys"
            - neverWatchPath: "/dev"
            - neverWatchPath: "/run"
            - neverWatchPath: "/tmp"
            - neverWatchPath: "/lost+found"
auth:
  adminUsername: admin
  adminPassword: helper-scripts.com
EOF
  msg_ok "已配置默认管理员（admin / helper-scripts.com）"
fi

msg_info "正在创建服务"
if [[ "$OS" == "Debian" ]]; then
  cat <<EOF >"$SERVICE_PATH"
[Unit]
Description=FileBrowser Quantum
After=network.target

[Service]
User=root
WorkingDirectory=/usr/local/community-scripts
ExecStart=/usr/local/bin/filebrowser -c $CONFIG_PATH
Restart=always

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable --now filebrowser &>/dev/null
else
  cat <<EOF >"$SERVICE_PATH"
#!/sbin/openrc-run

command="/usr/local/bin/filebrowser"
command_args="-c $CONFIG_PATH"
command_background=true
directory="/usr/local/community-scripts"
pidfile="/usr/local/community-scripts/pidfile"

depend() {
    need net
}
EOF
  chmod +x "$SERVICE_PATH"
  rc-update add filebrowser default &>/dev/null
  rc-service filebrowser start &>/dev/null
fi

msg_ok "服务创建成功"
echo -e "${CM} ${GN}${APP} 可通过以下地址访问: ${BL}http://$IP:$PORT${CL}"
