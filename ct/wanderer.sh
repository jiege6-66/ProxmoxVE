#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: rrole
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://wanderer.to

APP="Wanderer"
var_tags="${var_tags:-travelling;sport}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-8}"
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

  if [[ ! -f /opt/wanderer/start.sh ]]; then
    msg_error "No wanderer 安装已找到！"
    exit
  fi

  if check_for_gh_release "wanderer" "Flomp/wanderer"; then
    msg_info "正在停止 service"
    systemctl stop wanderer-web
    msg_ok "已停止 service"

    fetch_and_deploy_gh_release "wanderer" "open-wanderer/wanderer" "tarball" "latest" "/opt/wanderer/source"

    msg_info "正在更新 wanderer"
    cd /opt/wanderer/source/db
    $STD go mod tidy
    $STD go build
    cd /opt/wanderer/source/web
    $STD npm ci --omit=dev
    $STD npm run build
    msg_ok "Updated wanderer"

    msg_info "正在启动 service"
    systemctl start wanderer-web
    msg_ok "已启动 service"
    msg_ok "更新成功"
  fi
  if check_for_gh_release "meilisearch" "meilisearch/meilisearch"; then
    msg_info "正在停止 service"
    systemctl stop wanderer-web
    msg_ok "已停止 service"

    fetch_and_deploy_gh_release "meilisearch" "meilisearch/meilisearch" "binary" "latest" "/opt/wanderer/source/search"
    grep -q -- '--experimental-dumpless-upgrade' /opt/wanderer/start.sh || sed -i 's|meilisearch --master-key|meilisearch --experimental-dumpless-upgrade --master-key|' /opt/wanderer/start.sh

    msg_info "正在启动 service"
    systemctl start wanderer-web
    msg_ok "已启动 service"
    msg_ok "更新成功"
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
