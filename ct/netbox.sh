#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: bvdberg01
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://netboxlabs.com/

APP="NetBox"
var_tags="${var_tags:-network}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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
  if [[ ! -f /etc/systemd/system/netbox.service ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "netbox" "netbox-community/netbox"; then
    msg_info "正在停止 Services"
    systemctl stop netbox netbox-rq
    msg_ok "已停止 Services"

    msg_info "正在备份 NetBox configurations"
    mv /opt/netbox/ /opt/netbox-backup
    msg_ok "已备份 NetBox configurations"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "netbox" "netbox-community/netbox" "tarball"

    cp -r /opt/netbox-backup/netbox/netbox/configuration.py /opt/netbox/netbox/netbox/
    cp -r /opt/netbox-backup/netbox/{media,scripts,reports}/ /opt/netbox/netbox/
    cp -r /opt/netbox-backup/gunicorn.py /opt/netbox/
    [[ -f /opt/netbox-backup/local_requirements.txt ]] && cp -r /opt/netbox-backup/local_requirements.txt /opt/netbox/
    [[ -f /opt/netbox-backup/netbox/netbox/ldap_config.py ]] && cp -r /opt/netbox-backup/netbox/netbox/ldap_config.py /opt/netbox/netbox/netbox/

    $STD /opt/netbox/upgrade.sh
    rm -r /opt/netbox-backup

    msg_info "正在启动 Services"
    systemctl start netbox netbox-rq
    msg_ok "已启动 Services"
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
echo -e "${TAB}${GATEWAY}${BGN}https://${IP}${CL}"
