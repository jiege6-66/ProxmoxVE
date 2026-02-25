#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (Canbiz)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/alexta69/metube

APP="MeTube"
var_tags="${var_tags:-media;youtube}"
var_cpu="${var_cpu:-1}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-10}"
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

  if [[ ! -d /opt/metube ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if [[ $(echo ":$PATH:" != *":/usr/local/bin:"*) ]]; then
    echo -e "\nexport PATH=\"/usr/local/bin:\$PATH\"" >>~/.bashrc
    source ~/.bashrc
    if ! command -v deno &>/dev/null; then
      export DENO_INSTALL="/usr/local"
      curl -fsSL https://deno.land/install.sh | $STD sh -s -- -y
    else
      $STD deno upgrade
    fi
  fi

  NODE_VERSION="24" NODE_MODULE="pnpm" setup_nodejs

  if check_for_gh_release "metube" "alexta69/metube"; then
    msg_info "正在停止 Service"
    systemctl stop metube
    msg_ok "已停止 Service"

    msg_info "正在备份 Old Installation"
    if [[ -d /opt/metube_bak ]]; then
      rm -rf /opt/metube_bak
    fi
    mv /opt/metube /opt/metube_bak
    msg_ok "Backup created"

    fetch_and_deploy_gh_release "metube" "alexta69/metube" "tarball" "latest"

    msg_info "正在构建 Frontend"
    cd /opt/metube/ui
    if command -v corepack >/dev/null 2>&1; then
      $STD corepack enable
      $STD corepack prepare pnpm --activate || true
    fi
    $STD pnpm install --frozen-lockfile
    $STD pnpm run build
    msg_ok "已构建 Frontend"

    PYTHON_VERSION="3.13" setup_uv

    msg_info "正在安装 Backend Requirements"
    cd /opt/metube
    $STD uv sync
    msg_ok "已安装 Backend"

    msg_info "正在恢复 .env"
    if [[ -f /opt/metube_bak/.env ]]; then
      cp /opt/metube_bak/.env /opt/metube/.env
    fi
    rm -rf /opt/metube_bak
    msg_ok "已恢复 .env"

    if grep -q 'pipenv' /etc/systemd/system/metube.service; then
      msg_info "Patching systemd Service"
      cat <<EOF >/etc/systemd/system/metube.service
[Unit]
Description=Metube - YouTube Downloader
After=network.target
[Service]
Type=simple
WorkingDirectory=/opt/metube
EnvironmentFile=/opt/metube/.env
ExecStart=/opt/metube/.venv/bin/python3 app/main.py
Restart=always
User=root
[Install]
WantedBy=multi-user.target
EOF
      msg_ok "Patched systemd Service"
    fi
    $STD systemctl daemon-reload
    msg_ok "Service Updated"

    msg_info "正在启动 Service"
    systemctl start metube
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8081${CL}"
