#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/scanopy/scanopy

APP="Scanopy"
var_tags="${var_tags:-analytics}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-3072}"
var_disk="${var_disk:-6}"
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

  if [[ ! -d /opt/netvisor ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  msg_info "正在停止 services"
  systemctl -q disable --now netvisor-daemon netvisor-server
  msg_ok "已停止 services"

  NODE_VERSION="24" setup_nodejs
  CLEAN_INSTALL=1 fetch_and_deploy_gh_release "scanopy" "scanopy/scanopy" "tarball" "latest" "/opt/scanopy"

  ensure_dependencies pkg-config libssl-dev
  TOOLCHAIN="$(grep "channel" /opt/scanopy/backend/rust-toolchain.toml | awk -F\" '{print $2}')"
  RUST_TOOLCHAIN=$TOOLCHAIN setup_rust

  mv /opt/netvisor/.env /opt/scanopy/.env
  if [[ -f /opt/netvisor/oidc.toml ]]; then
    mv /opt/netvisor/oidc.toml /opt/scanopy/oidc.toml
  fi
  if ! grep -q "PUBLIC_URL" /opt/scanopy/.env; then
    sed -i "\|_PATH=|a\NETVISOR_PUBLIC_URL=http://${LOCAL_IP}:60072" /opt/scanopy/.env
  fi
  sed -i 's|_TARGET=.*$|_URL=http://127.0.0.1:60072|' /opt/scanopy/.env
  sed -i 's/NETVISOR/SCANOPY/g; s|netvisor/|scanopy/|' /opt/scanopy/.env

  msg_info "正在创建 frontend UI"
  export PUBLIC_SERVER_HOSTNAME=default
  export PUBLIC_SERVER_PORT=""
  cd /opt/scanopy/ui
  $STD npm ci --no-fund --no-audit
  $STD npm run build
  msg_ok "已创建 frontend UI"

  msg_info "正在构建 Scanopy-server (patience)"
  cd /opt/scanopy/backend
  $STD cargo build --release --bin server
  mv ./target/release/server /usr/bin/scanopy-server
  msg_ok "已构建 Scanopy-server"

  msg_info "正在构建 Scanopy-daemon"
  $STD cargo build --release --bin daemon
  cp ./target/release/daemon /usr/bin/scanopy-daemon
  msg_ok "已构建 Scanopy-daemon"

  sed -i '/^  \"server_target.*$/d' /root/.config/daemon/config.json
  sed -i -e 's|-target|-url|' \
    -e 's| --server-port |:|' \
    -e 's/NetVisor/Scanopy/' \
    -e 's/netvisor/scanopy/' \
    /etc/systemd/system/netvisor-daemon.service
  mv /etc/systemd/system/netvisor-daemon.service /etc/systemd/system/scanopy-daemon.service
  sed -i -e 's/NetVisor/Scanopy/' \
    -e 's/netvisor/scanopy/g' \
    /etc/systemd/system/netvisor-server.service
  mv /etc/systemd/system/netvisor-server.service /etc/systemd/system/scanopy-server.service
  systemctl daemon-reload

  msg_info "正在启动 services"
  systemctl -q enable --now scanopy-server scanopy-daemon
  msg_ok "已成功更新!"

  sed -i 's/netvisor/scanopy/' /usr/bin/update
  mv ~/NetVisor.creds ~/scanopy.creds
  rm ~/.netvisor
  rm -rf /opt/netvisor

  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:60072${CL}"
echo -e "${INFO}${YW} Then create your account, and run the 'configure_daemon.sh' script to setup the daemon.${CL}"
