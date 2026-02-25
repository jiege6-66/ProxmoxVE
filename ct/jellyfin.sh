#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://jellyfin.org/

APP="Jellyfin"
var_tags="${var_tags:-media}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-16}"
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
  if [[ ! -d /usr/lib/jellyfin ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if ! grep -qEi 'ubuntu' /etc/os-release; then
    msg_info "正在更新 Intel 依赖"
    rm -f ~/.intel-* || true
    fetch_and_deploy_gh_release "intel-igc-core-2" "intel/intel-graphics-compiler" "binary" "latest" "" "intel-igc-core-2_*_amd64.deb"
    fetch_and_deploy_gh_release "intel-igc-opencl-2" "intel/intel-graphics-compiler" "binary" "latest" "" "intel-igc-opencl-2_*_amd64.deb"
    fetch_and_deploy_gh_release "intel-libgdgmm12" "intel/compute-runtime" "binary" "latest" "" "libigdgmm12_*_amd64.deb"
    fetch_and_deploy_gh_release "intel-opencl-icd" "intel/compute-runtime" "binary" "latest" "" "intel-opencl-icd_*_amd64.deb"
    msg_ok "Updated Intel 依赖"
  fi

  msg_info "正在更新 Jellyfin"
  ensure_dependencies libjemalloc2
  if [[ ! -f /usr/lib/libjemalloc.so ]]; then
    ln -sf /usr/lib/x86_64-linux-gnu/libjemalloc.so.2 /usr/lib/libjemalloc.so
  fi
  $STD apt update
  $STD apt -y upgrade
  $STD apt -y --with-new-pkgs upgrade jellyfin jellyfin-server
  msg_ok "Updated Jellyfin"
  msg_ok "已成功更新!"
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8096${CL}"
