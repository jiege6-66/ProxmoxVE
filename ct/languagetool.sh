#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://languagetool.org/

APP="LanguageTool"
var_tags="${var_tags:-spellcheck}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-16}"
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
  if [[ ! -d /opt/LanguageTool ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  RELEASE=$(curl -fsSL https://languagetool.org/download/ | grep -oP 'LanguageTool-\K[0-9]+\.[0-9]+(\.[0-9]+)?(?=\.zip)' | sort -V | tail -n1)
  if [[ "${RELEASE}" != "$(cat ~/.languagetool 2>/dev/null)" ]] || [[ ! -f ~/.languagetool ]]; then
    msg_info "正在停止 Service"
    systemctl stop language-tool
    msg_ok "已停止 Service"

    msg_info "正在创建 Backup"
    cp /opt/LanguageTool/server.properties /opt/server.properties
    msg_ok "已创建 Backup"

    msg_info "正在更新 LanguageTool"
    rm -rf /opt/LanguageTool
    download_file "https://languagetool.org/download/LanguageTool-stable.zip" /tmp/LanguageTool-stable.zip
    unzip -q /tmp/LanguageTool-stable.zip -d /opt
    mv /opt/LanguageTool-*/ /opt/LanguageTool/
    mv /opt/server.properties /opt/LanguageTool/server.properties
    rm -f /tmp/LanguageTool-stable.zip
    echo "${RELEASE}" >~/.languagetool
    msg_ok "Updated LanguageTool"

    msg_info "正在启动 Service"
    systemctl start language-tool
    msg_ok "已启动 Service"
    msg_ok "Updated successfuly!"
  else
    msg_ok "无需更新。 ${APP} is already at v${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "已成功完成！"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8081/v2${CL}"
