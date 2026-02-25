#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/CyferShepard/Jellystat

if ! command -v curl &>/dev/null; then
  printf "\r\e[2K%b" '\033[93m Setup Source \033[m' >&2
  apt-get update >/dev/null 2>&1
  apt-get install -y curl >/dev/null 2>&1
fi
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/core.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/tools.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/error_handler.func)
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true

# Enable error handling
set -Eeuo pipefail
trap 'error_handler' ERR

# ==============================================================================
# CONFIGURATION
# ==============================================================================
APP="Jellystat"
APP_TYPE="addon"
INSTALL_PATH="/opt/jellystat"
CONFIG_PATH="/opt/jellystat/.env"
DEFAULT_PORT=3000

# Initialize all core functions (colors, formatting, icons, STD mode)
load_functions
init_tool_telemetry "" "addon"

# ==============================================================================
# HEADER
# ==============================================================================
function header_info {
  clear
  cat <<"EOF"
       __     ____           __        __
      / /__  / / /_  _______/ /_____ _/ /_
 __  / / _ \/ / / / / / ___/ __/ __ `/ __/
/ /_/ /  __/ / / /_/ (__  ) /_/ /_/ / /_
\____/\___/_/_/\__, /____/\__/\__,_/\__/
              /____/
EOF
}

# ==============================================================================
# OS DETECTION
# ==============================================================================
if [[ -f "/etc/alpine-release" ]]; then
  msg_error "Alpine 不支持 ${APP}。请使用 Debian/Ubuntu。"
  exit 1
elif [[ -f "/etc/debian_version" ]]; then
  OS="Debian"
  SERVICE_PATH="/etc/systemd/system/jellystat.service"
else
  echo -e "${CROSS} 检测到不支持的操作系统。正在退出。"
  exit 1
fi

# ==============================================================================
# UNINSTALL
# ==============================================================================
function uninstall() {
  msg_info "正在卸载 ${APP}"
  systemctl disable --now jellystat.service &>/dev/null || true
  rm -f "$SERVICE_PATH"
  rm -rf "$INSTALL_PATH"
  rm -f "/usr/local/bin/update_jellystat"
  rm -f "$HOME/.jellystat"
  msg_ok "${APP} 已卸载"

  # Ask about PostgreSQL database removal
  echo ""
  echo -n "${TAB}同时移除 PostgreSQL 数据库 'jellystat'？(y/N): "
  read -r db_prompt
  if [[ "${db_prompt,,}" =~ ^(y|yes)$ ]]; then
    if command -v psql &>/dev/null; then
      msg_info "正在移除 PostgreSQL 数据库和用户"
      $STD sudo -u postgres psql -c "DROP DATABASE IF EXISTS jellystat;" &>/dev/null || true
      $STD sudo -u postgres psql -c "DROP USER IF EXISTS jellystat;" &>/dev/null || true
      msg_ok "已移除 PostgreSQL 数据库 'jellystat' 和用户 'jellystat'"
    else
      msg_warn "未找到 PostgreSQL - 数据库可能已被移除"
    fi
  else
    msg_warn "PostgreSQL 数据库未移除。如需手动移除："
    echo -e "${TAB}  sudo -u postgres psql -c \"DROP DATABASE jellystat;\""
    echo -e "${TAB}  sudo -u postgres psql -c \"DROP USER jellystat;\""
  fi
}

# ==============================================================================
# UPDATE
# ==============================================================================
function update() {
  if check_for_gh_release "jellystat" "CyferShepard/Jellystat"; then
    msg_info "正在停止服务"
    systemctl stop jellystat.service &>/dev/null || true
    msg_ok "已停止服务"

    msg_info "正在备份配置"
    cp "$CONFIG_PATH" /tmp/jellystat.env.bak 2>/dev/null || true
    msg_ok "已备份配置"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "jellystat" "CyferShepard/Jellystat" "tarball" "latest" "$INSTALL_PATH"

    msg_info "正在恢复配置"
    cp /tmp/jellystat.env.bak "$CONFIG_PATH" 2>/dev/null || true
    rm -f /tmp/jellystat.env.bak
    msg_ok "已恢复配置"

    msg_info "正在安装依赖项"
    cd "$INSTALL_PATH"
    $STD npm install
    msg_ok "已安装依赖项"

    msg_info "正在构建 ${APP}"
    $STD npm run build
    msg_ok "已构建 ${APP}"

    msg_info "正在启动服务"
    systemctl start jellystat
    msg_ok "已启动服务"
    msg_ok "更新成功"
    exit
  fi
}

# ==============================================================================
# INSTALL
# ==============================================================================
function install() {
  # Setup Node.js (only installs if not present or different version)
  if command -v node &>/dev/null; then
    msg_ok "Node.js 已安装 ($(node -v))"
  else
    NODE_VERSION="22" setup_nodejs
  fi

  # Setup PostgreSQL (only installs if not present)
  if command -v psql &>/dev/null; then
    msg_ok "PostgreSQL 已安装"
  else
    PG_VERSION="17" setup_postgresql
  fi

  # Create database and user (skip if already exists)
  local DB_NAME="jellystat"
  local DB_USER="jellystat"
  local DB_PASS

  msg_info "正在设置 PostgreSQL 数据库"

  # Check if database already exists
  if sudo -u postgres psql -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
    msg_warn "数据库 '${DB_NAME}' 已存在 - 跳过创建"
    echo -n "${TAB}输入 '${DB_USER}' 的现有数据库密码: "
    read -rs DB_PASS
    echo ""
  else
    # Generate new password
    DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c16)

    # Check if user exists, create if not
    if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${DB_USER}'" 2>/dev/null | grep -q 1; then
      msg_info "用户 '${DB_USER}' 已存在，正在更新密码"
      $STD sudo -u postgres psql -c "ALTER USER ${DB_USER} WITH PASSWORD '${DB_PASS}';" || {
        msg_error "更新 PostgreSQL 用户失败"
        return 1
      }
    else
      $STD sudo -u postgres psql -c "CREATE USER ${DB_USER} WITH PASSWORD '${DB_PASS}';" || {
        msg_error "创建 PostgreSQL 用户失败"
        return 1
      }
    fi

    # Create database (use template0 for UTF8 encoding compatibility)
    $STD sudo -u postgres psql -c "CREATE DATABASE ${DB_NAME} WITH OWNER ${DB_USER} ENCODING 'UTF8' LC_COLLATE='C' LC_CTYPE='C' TEMPLATE template0;" || {
      msg_error "创建 PostgreSQL 数据库失败"
      return 1
    }
    $STD sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE ${DB_NAME} TO ${DB_USER};" || {
      msg_error "授予权限失败"
      return 1
    }

    # Grant schema permissions (required for PostgreSQL 15+)
    $STD sudo -u postgres psql -d "${DB_NAME}" -c "GRANT ALL ON SCHEMA public TO ${DB_USER};" || true

    # Configure pg_hba.conf for password authentication on localhost
    local PG_HBA
    PG_HBA=$(sudo -u postgres psql -tAc "SHOW hba_file;" 2>/dev/null | tr -d ' ')
    if [[ -n "$PG_HBA" && -f "$PG_HBA" ]]; then
      # Check if md5/scram-sha-256 auth is already configured for local connections
      if ! grep -qE "^host\s+${DB_NAME}\s+${DB_USER}\s+127.0.0.1" "$PG_HBA"; then
        msg_info "正在配置 PostgreSQL 身份验证"
        # Add password auth for jellystat user on localhost (before the default rules)
        sed -i "/^# IPv4 local connections:/a host    ${DB_NAME}    ${DB_USER}    127.0.0.1/32    scram-sha-256" "$PG_HBA"
        sed -i "/^# IPv4 local connections:/a host    ${DB_NAME}    ${DB_USER}    ::1/128         scram-sha-256" "$PG_HBA"
        # Reload PostgreSQL to apply changes
        systemctl reload postgresql
        msg_ok "已配置 PostgreSQL 身份验证"
      fi
    fi

    msg_ok "已创建 PostgreSQL 数据库 '${DB_NAME}'"
  fi

  # Generate JWT Secret
  local JWT_SECRET
  JWT_SECRET=$(openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c32)

  # Force fresh download by removing version cache
  rm -f "$HOME/.jellystat"
  fetch_and_deploy_gh_release "jellystat" "CyferShepard/Jellystat" "tarball" "latest" "$INSTALL_PATH"

  msg_info "正在安装依赖项"
  cd "$INSTALL_PATH"
  $STD npm install
  msg_ok "已安装依赖项"

  msg_info "正在构建 ${APP}"
  $STD npm run build
  msg_ok "已构建 ${APP}"

  msg_info "正在创建配置"
  cat <<EOF >"$CONFIG_PATH"
# Jellystat Configuration
# Database
POSTGRES_USER=${DB_USER}
POSTGRES_PASSWORD=${DB_PASS}
POSTGRES_IP=localhost
POSTGRES_PORT=5432
POSTGRES_DB=${DB_NAME}

# Security
JWT_SECRET=${JWT_SECRET}

# Server
JS_LISTEN_IP=0.0.0.0
JS_BASE_URL=/
TZ=$(cat /etc/timezone 2>/dev/null || echo "UTC")

# Optional: GeoLite for IP Geolocation
# JS_GEOLITE_ACCOUNT_ID=
# JS_GEOLITE_LICENSE_KEY=

# Optional: Master Override (if you forget your password)
# JS_USER=admin
# JS_PASSWORD=admin

# Optional: Minimum playback duration to record (seconds)
# MINIMUM_SECONDS_TO_INCLUDE_PLAYBACK=1

# Optional: Self-signed certificates
REJECT_SELF_SIGNED_CERTIFICATES=true
EOF
  chmod 600 "$CONFIG_PATH"
  msg_ok "已创建配置"

  msg_info "正在创建服务"
  cat <<EOF >"$SERVICE_PATH"
[Unit]
Description=Jellystat - Statistics for Jellyfin
After=network.target postgresql.service

[Service]
Type=simple
User=root
WorkingDirectory=${INSTALL_PATH}/backend
EnvironmentFile=${CONFIG_PATH}
ExecStart=/usr/bin/node ${INSTALL_PATH}/backend/server.js
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
  systemctl enable --now jellystat &>/dev/null
  msg_ok "已创建并启动服务"

  # Create update script (simple wrapper that calls this addon with type=update)
  msg_info "正在创建更新脚本"
  cat <<'UPDATEEOF' >/usr/local/bin/update_jellystat
#!/usr/bin/env bash
# Jellystat Update Script
type=update bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/jellystat.sh)"
UPDATEEOF
  chmod +x /usr/local/bin/update_jellystat
  msg_ok "已创建更新脚本 (/usr/local/bin/update_jellystat)"

  # Save credentials
  local CREDS_FILE="/root/jellystat.creds"
  cat <<EOF >"$CREDS_FILE"
Jellystat 凭据
=====================
数据库用户: ${DB_USER}
数据库密码: ${DB_PASS}
数据库名称: ${DB_NAME}
JWT 密钥: ${JWT_SECRET}

Web UI: http://${LOCAL_IP}:${DEFAULT_PORT}
EOF
  chmod 600 "$CREDS_FILE"

  echo ""
  msg_ok "${APP} 可通过以下地址访问: ${BL}http://${LOCAL_IP}:${DEFAULT_PORT}${CL}"
  msg_ok "凭据已保存到: ${BL}${CREDS_FILE}${CL}"
  echo ""
  msg_warn "首次访问时，您需要配置 Jellyfin 服务器连接。"
}

# ==============================================================================
# MAIN
# ==============================================================================

# Handle type=update (called from update script)
if [[ "${type:-}" == "update" ]]; then
  header_info
  if [[ -d "$INSTALL_PATH" && -f "$INSTALL_PATH/package.json" ]]; then
    update
  else
    msg_error "${APP} 未安装。无需更新。"
    exit 1
  fi
  exit 0
fi

header_info
get_lxc_ip

# Check if already installed
if [[ -d "$INSTALL_PATH" && -f "$INSTALL_PATH/package.json" ]]; then
  msg_warn "${APP} 已安装。"
  echo ""

  echo -n "${TAB}卸载 ${APP}? (y/N): "
  read -r uninstall_prompt
  if [[ "${uninstall_prompt,,}" =~ ^(y|yes)$ ]]; then
    uninstall
    exit 0
  fi

  echo -n "${TAB}更新 ${APP}? (y/N): "
  read -r update_prompt
  if [[ "${update_prompt,,}" =~ ^(y|yes)$ ]]; then
    update
    exit 0
  fi

  msg_warn "未选择操作。正在退出。"
  exit 0
fi

# Fresh installation
msg_warn "${APP} 未安装。"
echo ""
echo -e "${TAB}${INFO} 这将安装："
echo -e "${TAB}  - Node.js 22"
echo -e "${TAB}  - PostgreSQL 17"
echo -e "${TAB}  - Jellystat"
echo ""

echo -n "${TAB}安装 ${APP}? (y/N): "
read -r install_prompt
if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
  install
else
  msg_warn "安装已取消。正在退出。"
  exit 0
fi
