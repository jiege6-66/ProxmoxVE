#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://forgejo.org/

APP="Forgejo"
var_tags="${var_tags:-git}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
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
  if [[ ! -d /opt/forgejo ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_codeberg_release "forgejo" "forgejo/forgejo"; then
    msg_info "正在停止 Service"
    systemctl stop forgejo
    msg_ok "已停止 Service"

    fetch_and_deploy_codeberg_release "forgejo" "forgejo/forgejo" "singlefile" "latest" "/opt/forgejo" "forgejo-*-linux-amd64"
    ln -sf /opt/forgejo/forgejo /usr/local/bin/forgejo

    if grep -q "GITEA_WORK_DIR" /etc/systemd/system/forgejo.service; then
      msg_info "正在更新 Service File"
      sed -i "s/GITEA_WORK_DIR/FORGEJO_WORK_DIR/g" /etc/systemd/system/forgejo.service
      systemctl daemon-reload
      msg_ok "Updated Service File"
    fi

    msg_info "正在启动 Service"
    systemctl start forgejo
    msg_ok "已启动 Service"
    msg_ok "已成功更新!"
  else
    msg_ok "无需更新。 ${APP} is already at the latest version."
  fi
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
