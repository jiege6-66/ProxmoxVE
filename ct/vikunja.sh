#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (Canbiz) | Co-Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://vikunja.io/

APP="Vikunja"
var_tags="${var_tags:-todo-app}"
var_cpu="${var_cpu:-1}"
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
  if [[ ! -d /opt/vikunja ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  RELEASE="$( [[ -f "$HOME/.vikunja" ]] && cat "$HOME/.vikunja" 2>/dev/null || [[ -f /opt/Vikunja_version ]] && cat /opt/Vikunja_version 2>/dev/null || true)"
  if [[ -z "$RELEASE" ]] || [[ "$RELEASE" == "unstable" ]] || dpkg --compare-versions "${RELEASE:-0.0.0}" lt "1.0.0"; then
    msg_warn "You are upgrading from Vikunja '$RELEASE'."
    msg_warn "This requires MANUAL config changes in /etc/vikunja/config.yml."
    msg_warn "See: https://vikunja.io/changelog/whats-new-in-vikunja-1.0.0/#config-changes"

    read -rp "Continue with update? (y to proceed): " -t 30 CONFIRM1 || exit 1
    [[ "$CONFIRM1" =~ ^[yY]$ ]] || exit 0

    echo
    msg_warn "Vikunja may not start after the update until you manually adjust the config."
    msg_warn "Details: https://vikunja.io/changelog/whats-new-in-vikunja-1.0.0/#config-changes"

    read -rp "Acknowledge and continue? (y): " -t 30 CONFIRM2 || exit 1
    [[ "$CONFIRM2" =~ ^[yY]$ ]] || exit 0
  fi

  if check_for_gh_release "vikunja" "go-vikunja/vikunja"; then
    echo
    msg_warn "The package update may include config file changes."
    echo -e "${TAB}${YW}How do you want to handle /etc/vikunja/config.yml?${CL}"
    echo -e "${TAB}  1) Keep your current config"
    echo -e "${TAB}  2) Install the new package maintainer's config"
    read -rp "  Choose [1/2] (default: 1): " -t 60 CONFIG_CHOICE || CONFIG_CHOICE="1"
    [[ -z "$CONFIG_CHOICE" ]] && CONFIG_CHOICE="1"

    if [[ "$CONFIG_CHOICE" == "2" ]]; then
      export DPKG_FORCE_CONFNEW="1"
    else
      export DPKG_FORCE_CONFOLD="1"
    fi

    msg_info "正在停止 Service"
    systemctl stop vikunja
    msg_ok "已停止 Service"

    fetch_and_deploy_gh_release "vikunja" "go-vikunja/vikunja" "binary"

    msg_info "正在启动 Service"
    systemctl start vikunja
    msg_ok "已启动 Service"
    msg_ok "已成功更新!"
  fi
  exit 0
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3456${CL}"
