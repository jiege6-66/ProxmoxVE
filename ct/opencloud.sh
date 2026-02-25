#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://opencloud.eu

APP="OpenCloud"
var_tags="${var_tags:-files;cloud}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-20}"
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

  if [[ ! -d /etc/opencloud ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  RELEASE="v5.1.0"
  if check_for_gh_release "OpenCloud" "opencloud-eu/opencloud" "${RELEASE}"; then
    msg_info "正在停止 services"
    systemctl stop opencloud opencloud-wopi
    msg_ok "已停止 services"

    msg_info "正在更新 packages"
    $STD apt-get update
    $STD apt-get dist-upgrade -y
    ensure_dependencies "inotify-tools"
    msg_ok "Updated packages"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "OpenCloud" "opencloud-eu/opencloud" "singlefile" "${RELEASE}" "/usr/bin" "opencloud-*-linux-amd64"

    if ! grep -q 'POSIX_WATCH' /etc/opencloud/opencloud.env; then
      sed -i '/^## External/i ## Uncomment below to enable PosixFS Collaborative Mode\
## Increase inotify watch/instance limits on your PVE host:\
### sysctl -w fs.inotify.max_user_watches=1048576\
### sysctl -w fs.inotify.max_user_instances=1024\
# STORAGE_USERS_POSIX_ENABLE_COLLABORATION=true\
# STORAGE_USERS_POSIX_WATCH_TYPE=inotifywait\
# STORAGE_USERS_POSIX_WATCH_FS=true\
# STORAGE_USERS_POSIX_WATCH_PATH=<path-to-storage-or-bind-mount>' /etc/opencloud/opencloud.env
    fi

    msg_info "正在启动 services"
    systemctl start opencloud opencloud-wopi
    msg_ok "已启动 services"
    msg_ok "已成功更新"
  fi
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}https://<your-OpenCloud-FQDN>${CL}"
