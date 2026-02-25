#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.stirlingpdf.com/

APP="Stirling-PDF"
var_tags="${var_tags:-pdf-editor}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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
  if [[ ! -d /opt/Stirling-PDF ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "stirling-pdf" "Stirling-Tools/Stirling-PDF"; then
    if [[ ! -f /etc/systemd/system/unoserver.service ]]; then
      msg_custom "⚠️ " "\e[33m" "Legacy installation detected – please recreate the container using the latest install script."
      exit 0
    fi

    PYTHON_VERSION="3.12" setup_uv
    JAVA_VERSION="21" setup_java

    msg_info "正在停止 Services"
    systemctl stop stirlingpdf libreoffice-listener unoserver
    msg_ok "已停止 Services"

    if [[ -f ~/.Stirling-PDF-login ]]; then
      USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "stirling-pdf" "Stirling-Tools/Stirling-PDF" "singlefile" "latest" "/opt/Stirling-PDF" "Stirling-PDF-with-login.jar"
      mv /opt/Stirling-PDF/Stirling-PDF-with-login.jar /opt/Stirling-PDF/Stirling-PDF.jar
    else
      USE_ORIGINAL_FILENAME=true fetch_and_deploy_gh_release "stirling-pdf" "Stirling-Tools/Stirling-PDF" "singlefile" "latest" "/opt/Stirling-PDF" "Stirling-PDF.jar"
    fi

    msg_info "Refreshing Font Cache"
    $STD fc-cache -fv
    msg_ok "Font Cache Updated"

    msg_info "正在启动 Services"
    systemctl start stirlingpdf libreoffice-listener unoserver
    msg_ok "已启动 Services"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
