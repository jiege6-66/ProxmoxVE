#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/slskd/slskd, https://github.com/mrusse/soularr

APP="slskd"
var_tags="${var_tags:-arr;p2p}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-512}"
var_disk="${var_disk:-4}"
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

  if [[ ! -d /opt/slskd ]]; then
    msg_error "No Slskd 安装已找到！"
    exit
  fi

  if check_for_gh_release "Slskd" "slskd/slskd"; then
    msg_info "正在停止 Service(s)"
    systemctl stop slskd
    [[ -f /etc/systemd/system/soularr.service ]] && systemctl stop soularr.timer soularr.service
    msg_ok "已停止 Service(s)"

    msg_info "正在备份 config"
    cp /opt/slskd/config/slskd.yml /opt/slskd.yml.bak
    msg_ok "已备份 config"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Slskd" "slskd/slskd" "prebuild" "latest" "/opt/slskd" "slskd-*-linux-x64.zip"

    msg_info "正在恢复 config"
    mv /opt/slskd.yml.bak /opt/slskd/config/slskd.yml
    msg_ok "已恢复 config"

    msg_info "正在启动 Service(s)"
    systemctl start slskd
    [[ -f /etc/systemd/system/soularr.service ]] && systemctl start soularr.timer
    msg_ok "已启动 Service(s)"
    msg_ok "Updated Slskd successfully!"
  fi
  [[ -d /opt/soularr ]] && if check_for_gh_release "Soularr" "mrusse/soularr"; then
    if systemctl is-active soularr.timer >/dev/null; then
      msg_info "正在停止 Timer and Service"
      systemctl stop soularr.timer soularr.service
      msg_ok "已停止 Timer and Service"
    fi

    msg_info "正在备份 Soularr config"
    cp /opt/soularr/config.ini /opt/soularr_config.ini.bak
    cp /opt/soularr/run.sh /opt/soularr_run.sh.bak
    msg_ok "已备份 Soularr config"

    PYTHON_VERSION="3.11" setup_uv
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Soularr" "mrusse/soularr" "tarball" "latest" "/opt/soularr"
    msg_info "正在更新 Soularr"
    cd /opt/soularr
    $STD uv venv -c venv
    $STD source venv/bin/activate
    $STD uv pip install -r requirements.txt
    deactivate
    msg_ok "Updated Soularr"

    msg_info "正在恢复 Soularr config"
    mv /opt/soularr_config.ini.bak /opt/soularr/config.ini
    mv /opt/soularr_run.sh.bak /opt/soularr/run.sh
    msg_ok "已恢复 Soularr config"

    msg_info "正在启动 Soularr Timer"
    systemctl restart soularr.timer
    msg_ok "已启动 Soularr Timer"
    msg_ok "Updated Soularr successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5030${CL}"
