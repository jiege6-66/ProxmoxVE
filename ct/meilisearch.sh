#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://www.meilisearch.com/

APP="Meilisearch"
var_tags="${var_tags:-full-text-search}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-7}"
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

  setup_meilisearch

  if [[ -d /opt/meilisearch-ui ]]; then
    if check_for_gh_release "meilisearch-ui" "riccox/meilisearch-ui"; then
      msg_info "正在停止 Meilisearch-UI"
      systemctl stop meilisearch-ui
      msg_ok "已停止 Meilisearch-UI"

      cp /opt/meilisearch-ui/.env.local /tmp/.env.local.bak
      rm -rf /opt/meilisearch-ui
      fetch_and_deploy_gh_release "meilisearch-ui" "riccox/meilisearch-ui" "tarball"

      msg_info "正在配置 Meilisearch-UI"
      cd /opt/meilisearch-ui
      sed -i 's|const hash = execSync("git rev-parse HEAD").toString().trim();|const hash = "unknown";|' /opt/meilisearch-ui/vite.config.ts
      mv /tmp/.env.local.bak /opt/meilisearch-ui/.env.local
      $STD pnpm install
      msg_ok "已配置 Meilisearch-UI"

      msg_info "正在启动 Meilisearch-UI"
      systemctl start meilisearch-ui
      msg_ok "已启动 Meilisearch-UI"
    fi
  fi

  msg_ok "已成功更新!"
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}meilisearch: http://${IP}:7700$ | meilisearch-ui: http://${IP}:24900${CL}"
