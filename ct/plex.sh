#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: tteck (tteckster) | MickLesk (CanbiZ)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://www.plex.tv/

APP="Plex"
var_tags="${var_tags:-media}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_unprivileged="${var_unprivileged:-1}"
var_gpu="${var_gpu:-yes}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if ! dpkg -l plexmediaserver &>/dev/null; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  # Migrate from old repository to new one if needed
  if [[ -f /etc/apt/sources.list.d/plexmediaserver.sources ]]; then
    local current_uri
    current_uri=$(grep -oP '(?<=URIs: ).*' /etc/apt/sources.list.d/plexmediaserver.sources 2>/dev/null || true)
    if [[ "$current_uri" == *"downloads.plex.tv/repo/deb"* ]]; then
      msg_info "正在迁移 to new Plex repository"
      rm -f /etc/apt/sources.list.d/plexmediaserver.sources
      rm -f /usr/share/keyrings/PlexSign.asc
      setup_deb822_repo \
        "plexmediaserver" \
        "https://downloads.plex.tv/plex-keys/PlexSign.v2.key" \
        "https://repo.plex.tv/deb/" \
        "public" \
        "main"
      msg_ok "已迁移 to new Plex repository"
    fi
  elif [[ -f /etc/apt/sources.list.d/plexmediaserver.list ]]; then
    msg_info "正在迁移 to new Plex repository (deb822)"
    rm -f /etc/apt/sources.list.d/plexmediaserver.list
    rm -f /etc/apt/sources.list.d/plex*
    rm -f /usr/share/keyrings/PlexSign.asc
    setup_deb822_repo \
      "plexmediaserver" \
      "https://downloads.plex.tv/plex-keys/PlexSign.v2.key" \
      "https://repo.plex.tv/deb/" \
      "public" \
      "main"
    msg_ok "已迁移 to new Plex repository (deb822)"
  fi
  if [[ -f /usr/local/bin/plexupdate ]] || [[ -d /opt/plexupdate ]]; then
    msg_info "正在移除 legacy plexupdate"
    rm -rf /opt/plexupdate /usr/local/bin/plexupdate
    crontab -l 2>/dev/null | grep -v plexupdate | crontab - 2>/dev/null || true
    msg_ok "已移除 legacy plexupdate"
  fi

  msg_info "正在更新 Plex Media Server"
  $STD apt update
  $STD apt install -y plexmediaserver
  msg_ok "Updated Plex Media Server"
  msg_ok "已成功更新!"
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:32400/web${CL}"
