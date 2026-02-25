#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: chrisbenincasa
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://tunarr.com/

APP="Tunarr"
var_tags="${var_tags:-iptv}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-1024}"
var_disk="${var_disk:-5}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
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
  if [[ ! -d /opt/tunarr ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "tunarr" "chrisbenincasa/tunarr"; then
    msg_info "正在停止 Service"
    systemctl stop tunarr
    msg_ok "已停止 Service"

    msg_info "正在创建 Backup"
    if [ -d "/usr/local/share/tunarr" ]; then
      tar -czf "/opt/${APP}_backup_$(date +%F).tar.gz" /usr/local/share/tunarr $STD
      msg_ok "Backup 已创建"
    else
      msg_error "Backup failed: /usr/local/share/tunarr does not exist"
    fi

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "tunarr" "chrisbenincasa/tunarr" "prebuild" "latest" "/opt/tunarr" "*linux-x64.tar.gz"
    cd /opt/tunarr
    mv tunarr* tunarr

    msg_info "正在启动 Service"
    systemctl start tunarr
    msg_ok "已启动 Service"
    msg_ok "已成功更新!"
  fi

  if check_for_gh_release "ersatztv-ffmpeg" "ErsatzTV/ErsatzTV-ffmpeg"; then
    msg_info "正在停止 Service"
    systemctl stop tunarr
    msg_ok "已停止 Service"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "ersatztv-ffmpeg" "ErsatzTV/ErsatzTV-ffmpeg" "prebuild" "latest" "/opt/ErsatzTV-ffmpeg" "*-linux64-gpl-7.1.tar.xz"

    msg_info "Set ErsatzTV-ffmpeg links"
    chmod +x /opt/ErsatzTV-ffmpeg/bin/*
    ln -sf /opt/ErsatzTV-ffmpeg/bin/ffmpeg /usr/local/bin/ffmpeg
    ln -sf /opt/ErsatzTV-ffmpeg/bin/ffplay /usr/local/bin/ffplay
    ln -sf /opt/ErsatzTV-ffmpeg/bin/ffprobe /usr/local/bin/ffprobe
    msg_ok "ffmpeg links set"

    msg_info "正在启动 Service"
    systemctl start tunarr
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8000${CL}"
