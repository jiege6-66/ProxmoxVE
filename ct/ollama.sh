#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 tteck
# Author: havardthom | Co-Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ollama.com/

APP="Ollama"
var_tags="${var_tags:-ai}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-40}"
var_os="${var_os:-ubuntu}"
var_version="${var_version:-24.04}"
var_gpu="${var_gpu:-yes}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources
  if [[ ! -d /usr/local/lib/ollama ]]; then
    msg_error "No Ollama 安装已找到！"
    exit
  fi
  RELEASE=$(curl -fsSL https://api.github.com/repos/ollama/ollama/releases/latest | grep "tag_name" | awk -F '"' '{print $4}')
  if [[ ! -f /opt/Ollama_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/Ollama_version.txt)" ]]; then
    if [[ ! -f /opt/Ollama_version.txt ]]; then
      touch /opt/Ollama_version.txt
    fi
    ensure_dependencies zstd
    msg_info "正在停止 Services"
    systemctl stop ollama
    msg_ok "Services 已停止"

    TMP_TAR=$(mktemp --suffix=.tar.zst)
    curl -fL# -C - -o "${TMP_TAR}" "https://github.com/ollama/ollama/releases/download/${RELEASE}/ollama-linux-amd64.tar.zst"
    msg_info "正在更新 Ollama to ${RELEASE}"
    rm -rf /usr/local/lib/ollama
    rm -rf /usr/local/bin/ollama
    mkdir -p /usr/local/lib/ollama
    tar --zstd -xf "${TMP_TAR}" -C /usr/local/lib/ollama
    ln -sf /usr/local/lib/ollama/bin/ollama /usr/local/bin/ollama
    rm -f "${TMP_TAR}"
    echo "${RELEASE}" >/opt/Ollama_version.txt
    msg_ok "Updated Ollama to ${RELEASE}"

    msg_info "正在启动 Services"
    systemctl start ollama
    msg_ok "已启动 Services"
    msg_ok "已成功更新!"
  else
    msg_ok "无需更新。 Ollama is already at ${RELEASE}"
  fi
  exit
}

start
build_container
description

msg_ok "已成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:11434${CL}"
