#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://www.bazarr.media/

APP="Bazarr"
var_tags="${var_tags:-arr}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
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
  if [[ ! -d /var/lib/bazarr/ ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "bazarr" "morpheus65535/bazarr"; then
    msg_info "正在停止 Service"
    systemctl stop bazarr
    msg_ok "已停止 Service"

    PYTHON_VERSION="3.12" setup_uv
    fetch_and_deploy_gh_release "bazarr" "morpheus65535/bazarr" "prebuild" "latest" "/opt/bazarr" "bazarr.zip"

    msg_info "设置 Bazarr"
    mkdir -p /var/lib/bazarr/
    chmod 775 /opt/bazarr /var/lib/bazarr/
    # Always ensure venv exists
    if [[ ! -d /opt/bazarr/venv/ ]]; then
      $STD uv venv --clear /opt/bazarr/venv --python 3.12
    fi
    
    # Always check and fix service file if needed
    if [[ -f /etc/systemd/system/bazarr.service ]] && grep -q "ExecStart=/usr/bin/python3" /etc/systemd/system/bazarr.service; then
      sed -i "s|ExecStart=/usr/bin/python3 /opt/bazarr/bazarr.py|ExecStart=/opt/bazarr/venv/bin/python3 /opt/bazarr/bazarr.py|g" /etc/systemd/system/bazarr.service
      systemctl daemon-reload
    fi
    sed -i.bak 's/--only-binary=Pillow//g' /opt/bazarr/requirements.txt
    $STD uv pip install -r /opt/bazarr/requirements.txt --python /opt/bazarr/venv/bin/python3
    msg_ok "设置 Bazarr"

    msg_info "正在启动 Service"
    systemctl start bazarr
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6767${CL}"
