#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://grocy.info/

APP="grocy"
var_tags="${var_tags:-grocery;household}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-2}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -f /etc/apache2/sites-available/grocy.conf ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  php_ver=$(php -v | head -n 1 | awk '{print $2}')
  if [[ ! $php_ver == "8.3"* ]]; then
    PHP_VERSION="8.3" PHP_APACHE="YES" setup_php
  fi
  if check_for_gh_release "grocy" "grocy/grocy"; then
    msg_info "正在更新 grocy"
    bash /var/www/html/update.sh
    msg_ok "已成功更新!"
  fi
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
