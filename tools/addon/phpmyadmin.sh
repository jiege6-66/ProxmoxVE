#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE

function header_info {
  clear
  cat <<"EOF"
    ____  __          __  ___      ___       __          _
   / __ \/ /_  ____  /  |/  /_  __/   | ____/ /___ ___  (_)___
  / /_/ / __ \/ __ \/ /|_/ / / / / /| |/ __  / __ `__ \/ / __ \
 / ____/ / / / /_/ / /  / / /_/ / ___ / /_/ / / / / / / / / / /
/_/   /_/ /_/ .___/_/  /_/\__, /_/  |_\__,_/_/ /_/ /_/_/_/ /_/
           /_/           /____/
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

APP="phpMyAdmin"
INSTALL_DIR_DEBIAN="/var/www/html/phpMyAdmin"
INSTALL_DIR_ALPINE="/usr/share/phpmyadmin"

# Telemetry
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/api.func) 2>/dev/null || true
declare -f init_tool_telemetry &>/dev/null && init_tool_telemetry "phpmyadmin" "addon"

IFACE=$(ip -4 route | awk '/default/ {print $5; exit}')
IP=$(ip -4 addr show "$IFACE" | awk '/inet / {print $2}' | cut -d/ -f1 | head -n 1)
[[ -z "$IP" ]] && IP=$(hostname -I | awk '{print $1}')
[[ -z "$IP" ]] && IP="127.0.0.1"

# Detect OS
if [[ -f "/etc/alpine-release" ]]; then
  OS="Alpine"
  PKG_MANAGER_INSTALL="apk add --no-cache"
  PKG_QUERY="apk info -e"
  INSTALL_DIR="$INSTALL_DIR_ALPINE"
elif [[ -f "/etc/debian_version" ]]; then
  OS="Debian"
  PKG_MANAGER_INSTALL="apt-get install -y"
  PKG_QUERY="dpkg -l"
  INSTALL_DIR="$INSTALL_DIR_DEBIAN"
else
  echo -e "${CROSS} 检测到不支持的操作系统。正在退出。"
  exit 1
fi

header_info

function msg_info() { echo -e "${INFO} ${YW}${1}...${CL}"; }
function msg_ok() { echo -e "${CM} ${GN}${1}${CL}"; }
function msg_error() { echo -e "${CROSS} ${RD}${1}${CL}"; }

function check_internet() {
  if ! command -v curl &>/dev/null; then
    apt-get update >/dev/null 2>&1
    apt-get install -y curl >/dev/null 2>&1
  fi
  msg_info "正在检查到 GitHub 的互联网连接"
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://github.com)
  if [[ "$HTTP_CODE" -ge 200 && "$HTTP_CODE" -lt 400 ]]; then
    msg_ok "互联网连接正常"
  else
    msg_error "互联网连接或 GitHub 无法访问（状态 $HTTP_CODE）。正在退出。"
    exit 1
  fi
}

function is_phpmyadmin_installed() {
  if [[ "$OS" == "Debian" ]]; then
    [[ -f "$INSTALL_DIR/config.inc.php" ]]
  else
    [[ -d "$INSTALL_DIR_ALPINE" ]] && rc-service lighttpd status &>/dev/null
  fi
}

function install_php_and_modules() {
  msg_info "正在检查现有 PHP 安装"
  if command -v php >/dev/null 2>&1; then
    PHP_VERSION=$(php -r 'echo PHP_VERSION;')
    msg_ok "找到 PHP 版本 $PHP_VERSION"
  else
    msg_info "未找到 PHP，将安装 PHP 核心"
  fi

  if [[ "$OS" == "Debian" ]]; then
    PHP_MODULES=("php" "php-mysqli" "php-mbstring" "php-zip" "php-gd" "php-json" "php-curl")
    MISSING_PACKAGES=()
    for pkg in "${PHP_MODULES[@]}"; do
      if ! dpkg -l | grep -qw "$pkg"; then
        MISSING_PACKAGES+=("$pkg")
      fi
    done
    if [[ ${#MISSING_PACKAGES[@]} -gt 0 ]]; then
      msg_info "正在安装缺失的 PHP 包：${MISSING_PACKAGES[*]}"
      if ! apt-get update &>/dev/null || ! apt-get install -y "${MISSING_PACKAGES[@]}" &>/dev/null; then
        msg_error "安装所需 PHP 模块失败。正在退出。"
        exit 1
      fi
      msg_ok "已安装缺失的 PHP 包"
    else
      msg_ok "所有所需的 PHP 模块已安装"
    fi
  else
    msg_info "正在为 Alpine 安装 Lighttpd 和 PHP"
    $PKG_MANAGER_INSTALL lighttpd php php-fpm php-session php-json php-mysqli curl tar openssl &>/dev/null
    msg_ok "已安装 Lighttpd 和 PHP"
  fi
}

function install_phpmyadmin() {
  msg_info "正在从 GitHub 获取最新的 phpMyAdmin 版本"
  LATEST_VERSION_RAW=$(curl -s https://api.github.com/repos/phpmyadmin/phpmyadmin/releases/latest | grep tag_name | cut -d '"' -f4)
  LATEST_VERSION=$(echo "$LATEST_VERSION_RAW" | sed -e 's/^RELEASE_//' -e 's/_/./g')
  if [[ -z "$LATEST_VERSION" ]]; then
    msg_error "无法从 GitHub 确定最新的 phpMyAdmin 版本 – 回退到 5.2.2"
    LATEST_VERSION="RELEASE_5_2_2"
  fi
  msg_ok "最新版本：$LATEST_VERSION"

  TARBALL_URL="https://files.phpmyadmin.net/phpMyAdmin/${LATEST_VERSION}/phpMyAdmin-${LATEST_VERSION}-all-languages.tar.gz"
  msg_info "正在下载 ${TARBALL_URL}"
  if ! curl -fsSL "$TARBALL_URL" -o /tmp/phpmyadmin.tar.gz; then
    msg_error "下载失败：$TARBALL_URL"
    exit 1
  fi

  mkdir -p "$INSTALL_DIR"
  tar xf /tmp/phpmyadmin.tar.gz --strip-components=1 -C "$INSTALL_DIR"
}

function configure_phpmyadmin() {
  if [[ "$OS" == "Debian" ]]; then
    cp "$INSTALL_DIR/config.sample.inc.php" "$INSTALL_DIR/config.inc.php"
    SECRET=$(openssl rand -base64 24)
    sed -i "s#\$cfg\['blowfish_secret'\] = '';#\$cfg['blowfish_secret'] = '${SECRET}';#" "$INSTALL_DIR/config.inc.php"
    chmod 660 "$INSTALL_DIR/config.inc.php"
    chown -R www-data:www-data "$INSTALL_DIR"
    systemctl restart apache2
    msg_ok "已使用 Apache 配置 phpMyAdmin"
  else
    msg_info "正在为 phpMyAdmin 配置 Lighttpd（检测到 Alpine）"

    mkdir -p /etc/lighttpd
    cat <<EOF >/etc/lighttpd/lighttpd.conf
server.modules = (
    "mod_access",
    "mod_alias",
    "mod_accesslog",
    "mod_fastcgi"
)

server.document-root = "${INSTALL_DIR}"
server.port = 80

index-file.names = ( "index.php", "index.html" )

fastcgi.server = ( ".php" =>
  ((
    "host" => "127.0.0.1",
    "port" => 9000,
    "check-local" => "disable"
  ))
)

alias.url = ( "/phpMyAdmin/" => "${INSTALL_DIR}/" )

accesslog.filename = "/var/log/lighttpd/access.log"
server.errorlog = "/var/log/lighttpd/error.log"
EOF

    msg_info "正在启动 PHP-FPM 和 Lighttpd"

    PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION . PHP_MINOR_VERSION;')
    PHP_FPM_SERVICE="php-fpm${PHP_VERSION}"

    if $STD rc-service "$PHP_FPM_SERVICE" start && $STD rc-update add "$PHP_FPM_SERVICE" default; then
      msg_ok "已启动 PHP-FPM 服务：$PHP_FPM_SERVICE"
    else
      msg_error "启动 PHP-FPM 服务失败：$PHP_FPM_SERVICE"
      exit 1
    fi

    $STD rc-service lighttpd start
    $STD rc-update add lighttpd default
    msg_ok "已成功配置并启动 Lighttpd"

  fi
}

function uninstall_phpmyadmin() {
  msg_info "正在停止 Web 服务器"
  if [[ "$OS" == "Debian" ]]; then
    systemctl stop apache2
  else
    $STD rc-service lighttpd stop
    $STD rc-service php-fpm stop
  fi

  msg_info "正在移除 phpMyAdmin 目录"
  rm -rf "$INSTALL_DIR"

  if [[ "$OS" == "Alpine" ]]; then
    msg_info "正在移除 Lighttpd 配置"
    rm -f /etc/lighttpd/lighttpd.conf
    $STD rc-service php-fpm restart
    $STD rc-service lighttpd restart
  else
    $STD systemctl restart apache2
  fi
  msg_ok "已卸载 phpMyAdmin"
}

function update_phpmyadmin() {
  msg_info "正在从 GitHub 获取最新的 phpMyAdmin 版本"
  LATEST_VERSION_RAW=$(curl -s https://api.github.com/repos/phpmyadmin/phpmyadmin/releases/latest | grep tag_name | cut -d '"' -f4)
  LATEST_VERSION=$(echo "$LATEST_VERSION_RAW" | sed -e 's/^RELEASE_//' -e 's/_/./g')

  if [[ -z "$LATEST_VERSION" ]]; then
    msg_error "无法从 GitHub 确定最新的 phpMyAdmin 版本 – 回退到 5.2.2"
    LATEST_VERSION="5.2.2"
  fi
  msg_ok "最新版本：$LATEST_VERSION"

  TARBALL_URL="https://files.phpmyadmin.net/phpMyAdmin/${LATEST_VERSION}/phpMyAdmin-${LATEST_VERSION}-all-languages.tar.gz"
  msg_info "正在下载 ${TARBALL_URL}"

  if ! curl -fsSL "$TARBALL_URL" -o /tmp/phpmyadmin.tar.gz; then
    msg_error "下载失败：$TARBALL_URL"
    exit 1
  fi

  BACKUP_DIR="/tmp/phpmyadmin-backup-$(date +%Y%m%d-%H%M%S)"
  mkdir -p "$BACKUP_DIR"
  BACKUP_ITEMS=("config.inc.php" "upload" "save" "tmp" "themes")

  msg_info "正在备份现有 phpMyAdmin 数据"
  for item in "${BACKUP_ITEMS[@]}"; do
    [[ -e "$INSTALL_DIR/$item" ]] && cp -a "$INSTALL_DIR/$item" "$BACKUP_DIR/" && echo "  ↪︎ $item"
  done
  msg_ok "备份完成：$BACKUP_DIR"

  tar xf /tmp/phpmyadmin.tar.gz --strip-components=1 -C "$INSTALL_DIR"
  msg_ok "已解压 phpMyAdmin $LATEST_VERSION"

  msg_info "正在恢复保留的文件"
  for item in "${BACKUP_ITEMS[@]}"; do
    [[ -e "$BACKUP_DIR/$item" ]] && cp -a "$BACKUP_DIR/$item" "$INSTALL_DIR/" && echo "  ↪︎ $item 已恢复"
  done
  msg_ok "恢复完成"

  configure_phpmyadmin
}

if is_phpmyadmin_installed; then
  echo -e "${YW}⚠️ ${APP} 已安装在 ${INSTALL_DIR}。${CL}"
  read -r -p "您想更新 (1)、卸载 (2) 还是取消 (3)？[1/2/3]: " action
  action="${action//[[:space:]]/}"
  case "$action" in
  1)
    check_internet
    update_phpmyadmin
    ;;
  2)
    uninstall_phpmyadmin
    ;;
  3)
    echo -e "${YW}⚠️ 操作已取消。正在退出。${CL}"
    exit 0
    ;;
  *)
    echo -e "${YW}⚠️ 无效输入。正在退出。${CL}"
    exit 1
    ;;
  esac
else
  read -r -p "您想安装 ${APP} 吗？(y/n): " install_prompt
  install_prompt="${install_prompt//[[:space:]]/}"
  if [[ "${install_prompt,,}" =~ ^(y|yes)$ ]]; then
    check_internet
    install_php_and_modules
    install_phpmyadmin
    configure_phpmyadmin
    if [[ "$OS" == "Debian" ]]; then
      echo -e "${CM} ${GN}${APP} 可通过以下地址访问: ${BL}http://${IP}/phpMyAdmin${CL}"
    else
      echo -e "${CM} ${GN}${APP} 可通过以下地址访问: ${BL}http://${IP}/${CL}"
    fi
  else
    echo -e "${YW}⚠️ 已跳过安装。正在退出。${CL}"
    exit 0
  fi
fi
