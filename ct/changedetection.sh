#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck (tteckster)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://changedetection.io/

APP="Change Detection"
var_tags="${var_tags:-monitoring;crawler}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-10}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -f /etc/systemd/system/changedetection.service ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  ensure_dependencies libjpeg-dev

  NODE_VERSION="24" setup_nodejs

  msg_info "正在更新 ${APP}"
  $STD pip3 install changedetection.io --upgrade
  msg_ok "Updated ${APP}"

  msg_info "正在更新 Playwright"
  $STD pip3 install playwright --upgrade
  msg_ok "Updated Playwright"

  if [[ -f /etc/systemd/system/browserless.service ]]; then
    msg_info "正在更新 Browserless (Patience)"
    $STD git -C /opt/browserless/ fetch --all
    $STD git -C /opt/browserless/ reset --hard origin/main
    $STD npm update --prefix /opt/browserless
    $STD npm ci --include=optional --include=dev --prefix /opt/browserless
    $STD /opt/browserless/node_modules/playwright-core/cli.js install --with-deps
    # Update Chrome separately, as it has to be done with the force option. Otherwise the installation of other browsers will not be done if Chrome is already installed.
    $STD /opt/browserless/node_modules/playwright-core/cli.js install --force chrome
    $STD /opt/browserless/node_modules/playwright-core/cli.js install --force msedge
    $STD /opt/browserless/node_modules/playwright-core/cli.js install chromium firefox webkit
    $STD npm install --prefix /opt/browserless esbuild typescript ts-node @types/node --save-dev
    $STD npm run build --prefix /opt/browserless
    $STD npm run build:function --prefix /opt/browserless
    $STD npm prune production --prefix /opt/browserless
    systemctl restart browserless
    msg_ok "Updated Browserless"
  else
    msg_error "No Browserless 安装已找到！"
  fi

  systemctl restart changedetection
  msg_ok "已成功更新!"
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:5000${CL}"
