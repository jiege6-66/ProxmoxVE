#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/VictoriaMetrics/VictoriaMetrics

APP="VictoriaMetrics"
var_tags="${var_tags:-database}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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
  if [[ ! -d /opt/victoriametrics ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "victoriametrics" "VictoriaMetrics/VictoriaMetrics"; then
    msg_info "正在停止 Service"
    systemctl stop victoriametrics
    [[ -f /etc/systemd/system/victoriametrics-logs.service ]] && systemctl stop victoriametrics-logs
    msg_ok "已停止 Service"

    victoriametrics_filename=$(curl -fsSL "https://api.github.com/repos/VictoriaMetrics/VictoriaMetrics/releases/latest" |
      jq -r '.assets[].name' |
      grep -E '^victoria-metrics-linux-amd64-v[0-9.]+\.tar\.gz$')
    vmutils_filename=$(curl -fsSL "https://api.github.com/repos/VictoriaMetrics/VictoriaMetrics/releases/latest" |
      jq -r '.assets[].name' |
      grep -E '^vmutils-linux-amd64-v[0-9.]+\.tar\.gz$')

    fetch_and_deploy_gh_release "victoriametrics" "VictoriaMetrics/VictoriaMetrics" "prebuild" "latest" "/opt/victoriametrics" "$victoriametrics_filename"
    fetch_and_deploy_gh_release "vmutils" "VictoriaMetrics/VictoriaMetrics" "prebuild" "latest" "/opt/victoriametrics" "$vmutils_filename"

    if [[ -f /etc/systemd/system/victoriametrics-logs.service ]]; then
      vmlogs_filename=$(curl -fsSL "https://api.github.com/repos/VictoriaMetrics/VictoriaLogs/releases/latest" |
        jq -r '.assets[].name' |
        grep -E '^victoria-logs-linux-amd64-v[0-9.]+\.tar\.gz$')  
      vlutils_filename=$(curl -fsSL "https://api.github.com/repos/VictoriaMetrics/VictoriaLogs/releases/latest" |
        jq -r '.assets[].name' |
        grep -E '^vlutils-linux-amd64-v[0-9.]+\.tar\.gz$')
        
      fetch_and_deploy_gh_release "victorialogs" "VictoriaMetrics/VictoriaLogs" "prebuild" "latest" "/opt/victoriametrics" "$vmlogs_filename"
      fetch_and_deploy_gh_release "vlutils" "VictoriaMetrics/VictoriaLogs" "prebuild" "latest" "/opt/victoriametrics" "$vlutils_filename"
    fi
    chmod +x /opt/victoriametrics/*

    msg_info "正在启动 Service"
    systemctl start victoriametrics
    [[ -f /etc/systemd/system/victoriametrics-logs.service ]] && systemctl start victoriametrics-logs
    msg_ok "已启动 Service"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8428/vmui${CL}"
