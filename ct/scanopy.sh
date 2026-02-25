#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
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

  if [[ ! -d /opt/scanopy ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "Scanopy" "scanopy/scanopy"; then
    msg_info "正在停止 services"
    systemctl stop scanopy-server
    [[ -f /etc/systemd/system/scanopy-daemon.service ]] && systemctl stop scanopy-daemon
    msg_ok "已停止 services"

    msg_info "正在备份 configurations"
    cp /opt/scanopy/.env /opt/scanopy.env
    [[ -f /opt/scanopy/oidc.toml ]] && cp /opt/scanopy/oidc.toml /opt/scanopy.oidc.toml
    msg_ok "已备份 configurations"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Scanopy" "scanopy/scanopy" "tarball" "latest" "/opt/scanopy"

    ensure_dependencies pkg-config libssl-dev
    TOOLCHAIN="$(grep "channel" /opt/scanopy/backend/rust-toolchain.toml | awk -F\" '{print $2}')"
    RUST_TOOLCHAIN=$TOOLCHAIN setup_rust

    [[ -f /opt/scanopy.env ]] && mv /opt/scanopy.env /opt/scanopy/.env
    [[ -f /opt/scanopy.oidc.toml ]] && mv /opt/scanopy.oidc.toml /opt/scanopy/oidc.toml
    if ! grep -q "PUBLIC_URL" /opt/scanopy/.env; then
      sed -i "\|_PATH=|a\\scanopy_PUBLIC_URL=http://${LOCAL_IP}:60072" /opt/scanopy/.env
    fi
    sed -i 's|_TARGET=.*$|_URL=http://127.0.0.1:60072|' /opt/scanopy/.env

    msg_info "正在创建 frontend UI"
    export PUBLIC_SERVER_HOSTNAME=default
    export PUBLIC_SERVER_PORT=""
    cd /opt/scanopy/ui
    $STD npm ci --no-fund --no-audit
    $STD npm run build
    msg_ok "已创建 frontend UI"

    msg_info "正在构建 Scanopy Server (patience)"
    cd /opt/scanopy/backend
    $STD cargo build --release --bin server
    mv ./target/release/server /usr/bin/scanopy-server
    msg_ok "已构建 Scanopy Server"

    if [[ -f /etc/systemd/system/scanopy-daemon.service ]]; then
      fetch_and_deploy_gh_release "Scanopy Daemon" "scanopy/scanopy" "singlefile" "latest" "/usr/local/bin" "scanopy-daemon-linux-amd64"
      mv "/usr/local/bin/Scanopy Daemon" /usr/local/bin/scanopy-daemon
      rm -f /usr/bin/scanopy-daemon ~/configure_daemon.sh
      sed -i -e 's|usr/bin|usr/local/bin|' \
        -e 's/push/daemon_poll/' \
        -e 's/pull/server_poll/' /etc/systemd/system/scanopy-daemon.service
      systemctl daemon-reload
      msg_ok "Updated Scanopy Daemon"
    fi

    msg_info "正在启动 services"
    systemctl start scanopy-server
    [[ -f /etc/systemd/system/scanopy-daemon.service ]] && systemctl start scanopy-daemon
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:60072${CL}"
echo -e "${INFO}${YW} Then create your account, and create a daemon in the UI.${CL}"
