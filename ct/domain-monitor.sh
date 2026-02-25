#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Hosteroid/domain-monitor

APP="Domain-Monitor"
var_tags="${var_tags:-proxy}"
var_cpu="${var_cpu:-2}"
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
  if [[ ! -d /opt/domain-monitor ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  setup_mariadb

  if grep -Fq "root /usr/bin/php /opt/domain-monitor/cron/check_domains.php" /etc/crontab; then
    sed -i 's|root /usr/bin/php /opt/domain-monitor/cron/check_domains.php|www-data /usr/bin/php /opt/domain-monitor/cron/check_domains.php|' /etc/crontab
  fi

  if ! grep -Fq "www-data /usr/bin/php /opt/domain-monitor/cron/check_domains.php" /etc/crontab; then
    echo "0 0 * * * www-data /usr/bin/php /opt/domain-monitor/cron/check_domains.php" >> /etc/crontab
  fi

  if check_for_gh_release "domain-monitor" "Hosteroid/domain-monitor"; then
    msg_info "正在停止 Service"
    systemctl stop apache2
    msg_info "Service stopped"

    msg_info "正在创建 backup"
    mv /opt/domain-monitor/.env /opt
    msg_ok "已创建 backup"

    setup_composer
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "domain-monitor" "Hosteroid/domain-monitor" "prebuild" "latest" "/opt/domain-monitor" "domain-monitor-v*.zip"

    msg_info "正在更新 Domain Monitor"
    cd /opt/domain-monitor
    $STD composer install
    msg_ok "Updated Domain Monitor"

    msg_info "正在恢复 backup"
    mv /opt/.env /opt/domain-monitor
    msg_ok "已恢复 backup"

    msg_info "正在重启 Services"
    systemctl reload apache2
    msg_ok "已重启 Services"
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
