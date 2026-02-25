#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: prop4n
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://docs.sonarsource.com/sonarqube-server

APP="SonarQube"
var_tags="${var_tags:-automation}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-6144}"
var_disk="${var_disk:-25}"
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
  if [[ ! -d /opt/sonarqube ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "sonarqube" "SonarSource/sonarqube"; then
    msg_info "正在停止 Service"
    systemctl stop sonarqube
    msg_ok "已停止 Service"

    msg_info "正在创建 Backup"
    BACKUP_DIR="/opt/sonarqube-backup"
    mv /opt/sonarqube ${BACKUP_DIR}
    msg_ok "已创建 Backup"

    msg_info "正在更新 SonarQube"
    temp_file=$(mktemp)
    RELEASE=$(get_latest_github_release "SonarSource/sonarqube")
    curl -fsSL "https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-${RELEASE}.zip" -o $temp_file
    unzip -q "$temp_file" -d /opt
    mv /opt/sonarqube-${RELEASE} /opt/sonarqube
    echo "${RELEASE}" > ~/.sonarqube
    msg_ok "Updated SonarQube"

    msg_info "正在恢复 Backup"
    cp -rp ${BACKUP_DIR}/data/ /opt/sonarqube/data/
    cp -rp ${BACKUP_DIR}/extensions/ /opt/sonarqube/extensions/
    cp -p ${BACKUP_DIR}/conf/sonar.properties /opt/sonarqube/conf/sonar.properties
    rm -rf ${BACKUP_DIR}
    chown -R sonarqube:sonarqube /opt/sonarqube
    msg_ok "已恢复 Backup"

    msg_info "正在启动 Service"
    systemctl start sonarqube
    msg_ok "Service 已启动"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9000${CL}"
