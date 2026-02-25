#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.emqx.com/en

APP="EMQX"
var_tags="${var_tags:-mqtt}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-6}"
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

  RELEASE=$(curl -fsSL https://www.emqx.com/en/downloads/enterprise | grep -oP '/en/downloads/enterprise/v\K[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -n1)
  if [[ "$RELEASE" != "$(cat ~/.emqx 2>/dev/null)" ]] || [[ ! -f ~/.emqx ]]; then
    msg_info "正在停止 EMQX"
    systemctl stop emqx
    msg_ok "已停止 EMQX"

    msg_info "正在移除 old EMQX"
    if dpkg -l | grep -q "^ii\s\+emqx\s"; then
      $STD apt remove --purge -y emqx
    elif dpkg -l | grep -q "^ii\s\+emqx-enterprise\s"; then
      $STD apt remove --purge -y emqx-enterprise
    else
      msg_ok "No old EMQX package found"
    fi
    msg_ok "已移除 old EMQX"

    msg_info "正在下载 EMQX v${RELEASE}"
    DEB_FILE="/tmp/emqx-enterprise-${RELEASE}-debian12-amd64.deb"
    curl -fsSL -o "$DEB_FILE" "https://www.emqx.com/en/downloads/enterprise/v${RELEASE}/emqx-enterprise-${RELEASE}-debian12-amd64.deb"
    msg_ok "已下载 EMQX"

    msg_info "正在安装 EMQX"
    $STD apt install -y "$DEB_FILE"
    rm -f "$DEB_FILE"
    echo "$RELEASE" >~/.emqx
    msg_ok "已安装 EMQX v${RELEASE}"

    msg_info "正在启动 EMQX"
    systemctl start emqx
    msg_ok "已启动 EMQX"
    msg_ok "已成功更新!"
  else
    msg_ok "无需更新。 EMQX is already at v${RELEASE}"
  fi

  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:18083${CL}"
