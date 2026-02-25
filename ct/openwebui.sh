#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: tteck | Co-Author: havardthom | Co-Author: Slaviša Arežina (tremor021)
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://openwebui.com/

APP="Open WebUI"
var_tags="${var_tags:-ai;interface}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-8192}"
var_disk="${var_disk:-50}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
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

  if [[ -d /opt/open-webui ]]; then
    msg_warn "Legacy installation detected — migrating to uv based install..."
    msg_info "正在停止 Service"
    systemctl stop open-webui
    msg_ok "已停止 Service"

    msg_info "正在创建 Backup"
    mkdir -p /opt/open-webui-backup
    cp -a /opt/open-webui/backend/data /opt/open-webui-backup/data || true
    cp -a /opt/open-webui/.env /opt/open-webui-backup/.env || true
    msg_ok "已创建 Backup"

    msg_info "正在移除 legacy installation"
    rm -rf /opt/open-webui
    rm -rf /root/.open-webui || true
    msg_ok "已移除 legacy installation"

    msg_info "正在安装 uv-based Open-WebUI"
    PYTHON_VERSION="3.12" setup_uv
    $STD uv tool install --python 3.12 --constraint <(echo "numba>=0.60") open-webui[all]
    msg_ok "已安装 uv-based Open-WebUI"

    msg_info "正在恢复 data"
    mkdir -p /root/.open-webui
    cp -a /opt/open-webui-backup/data/* /root/.open-webui/ || true
    cp -a /opt/open-webui-backup/.env /root/.env || true
    rm -rf /opt/open-webui-backup || true
    msg_ok "已恢复 data"

    msg_info "Recreating Service"
    cat <<EOF >/etc/systemd/system/open-webui.service
[Unit]
Description=Open WebUI Service
After=network.target

[Service]
Type=simple
Environment=DATA_DIR=/root/.open-webui
EnvironmentFile=-/root/.env
ExecStart=/root/.local/bin/open-webui serve
WorkingDirectory=/root
Restart=on-failure
RestartSec=5
User=root

[Install]
WantedBy=multi-user.target
EOF

    $STD systemctl daemon-reload
    systemctl enable -q --now open-webui
    msg_ok "Recreated Service"

    msg_ok "Migration completed"
    exit 0
  fi

  if [[ ! -d /root/.open-webui ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if [ -x "/usr/bin/ollama" ]; then
    msg_info "正在检查 for Ollama Update"
    OLLAMA_VERSION=$(ollama -v | awk '{print $NF}')
    RELEASE=$(curl -s https://api.github.com/repos/ollama/ollama/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4)}')
    if [ "$OLLAMA_VERSION" != "$RELEASE" ]; then
      ensure_dependencies zstd
      msg_info "Ollama update available: v$OLLAMA_VERSION -> v$RELEASE"
      msg_info "正在下载 Ollama v$RELEASE \n"
      curl -fS#LO https://github.com/ollama/ollama/releases/download/v${RELEASE}/ollama-linux-amd64.tar.zst
      msg_ok "Download Complete"

      if [ -f "ollama-linux-amd64.tar.zst" ]; then

        msg_info "正在停止 Ollama Service"
        systemctl stop ollama
        msg_ok "已停止 Service"

        msg_info "正在安装 Ollama"
        rm -rf /usr/lib/ollama
        rm -rf /usr/bin/ollama
        tar --zstd -C /usr -xf ollama-linux-amd64.tar.zst
        rm -rf ollama-linux-amd64.tar.zst
        msg_ok "已安装 Ollama"

        msg_info "正在启动 Ollama Service"
        systemctl start ollama
        msg_ok "已启动 Service"

        msg_ok "Ollama updated to version $RELEASE"
      else
        msg_error "Ollama download failed. Aborting update."
      fi
    else
      msg_ok "Ollama is 已是最新."
    fi
  fi

  msg_info "正在更新 Open WebUI via uv"
  PYTHON_VERSION="3.12" setup_uv
  $STD uv tool install --force --python 3.12 --constraint <(echo "numba>=0.60") open-webui[all]
  systemctl restart open-webui
  msg_ok "Updated Open WebUI"
  msg_ok "已成功更新!"
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
