#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://www.home-assistant.io/

APP="Podman-Home Assistant"
var_tags="${var_tags:-podman;smarthome}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-16}"
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
  if [[ ! -f /etc/systemd/system/homeassistant.service ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  UPD=$(msg_menu "Home Assistant Update Options" \
    "1" "Update system and containers" \
    "2" "Install HACS" \
    "3" "Install FileBrowser" \
    "4" "Remove ALL Unused Images")

  if [ "$UPD" == "1" ]; then
    msg_info "正在更新 ${APP} LXC"
    $STD apt update
    $STD apt upgrade -y
    msg_ok "已成功更新!"

    msg_info "正在更新 All Containers\n"
    CONTAINER_LIST="${1:-$(podman ps -q)}"
    for container in ${CONTAINER_LIST}; do
      CONTAINER_IMAGE="$(podman inspect --format "{{.Config.Image}}" --type container ${container})"
      RUNNING_IMAGE="$(podman inspect --format "{{.Image}}" --type container "${container}")"
      podman pull "${CONTAINER_IMAGE}"
      LATEST_IMAGE="$(podman inspect --format "{{.Id}}" --type image "${CONTAINER_IMAGE}")"
      if [[ "${RUNNING_IMAGE}" != "${LATEST_IMAGE}" ]]; then
        echo "正在更新 ${container} image ${CONTAINER_IMAGE}"
        systemctl restart homeassistant
      fi
    done
    msg_ok "All containers updated."
    exit
  fi
  if [ "$UPD" == "2" ]; then
    msg_info "正在安装 Home Assistant Community Store (HACS)"
    $STD apt update
    cd /var/lib/containers/storage/volumes/hass_config/_data
    $STD bash <(curl -fsSL https://get.hacs.xyz)
    msg_ok "已安装 Home Assistant Community Store (HACS)"
    echo -e "\n Reboot Home Assistant and clear browser cache then Add HACS integration.\n"
    exit
  fi
  if [ "$UPD" == "3" ]; then
    msg_info "正在安装 FileBrowser"
    $STD curl -fsSL https://raw.githubusercontent.com/filebrowser/get/master/get.sh | bash
    $STD filebrowser config init -a '0.0.0.0'
    $STD filebrowser config set -a '0.0.0.0'
    $STD filebrowser users add admin helper-scripts.com --perm.admin
    msg_ok "已安装 FileBrowser"

    msg_info "正在创建 Service"
    cat <<EOF >/etc/systemd/system/filebrowser.service
[Unit]
Description=Filebrowser
After=network-online.target

[Service]
User=root
WorkingDirectory=/root/
ExecStart=/usr/local/bin/filebrowser -r /

[Install]
WantedBy=default.target
EOF
    systemctl enable -q --now filebrowser
    msg_ok "已创建 Service"

    msg_ok "已成功完成！\n"
    echo -e "FileBrowser should be reachable by going to the following URL.
         ${BL}http://$LOCAL_IP:8080${CL}   admin|helper-scripts.com\n"
    exit
  fi
  if [ "$UPD" == "4" ]; then
    msg_info "正在移除 ALL Unused Images"
    podman image prune -a -f
    msg_ok "已移除 ALL Unused Images"
    exit
  fi
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8123${CL}"
