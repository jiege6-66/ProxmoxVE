#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://mealie.io

APP="Mealie"
var_tags="${var_tags:-recipes}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-3072}"
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

  if [[ ! -d /opt/mealie ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi
  if check_for_gh_release "mealie" "mealie-recipes/mealie"; then
    PYTHON_VERSION="3.12" setup_uv
    NODE_MODULE="yarn" NODE_VERSION="24" setup_nodejs

    msg_info "正在停止 Service"
    systemctl stop mealie
    msg_ok "已停止 Service"

    msg_info "正在备份 Configuration"
    cp -f /opt/mealie/mealie.env /opt/mealie.env
    msg_ok "Backup completed"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "mealie" "mealie-recipes/mealie" "tarball" "latest" "/opt/mealie"

    msg_info "正在安装 Python 依赖 with uv"
    cd /opt/mealie
    $STD uv sync --frozen --extra pgsql
    msg_ok "已安装 Python 依赖"

    msg_info "正在构建 Frontend"
    MEALIE_VERSION=$(<$HOME/.mealie)
    $STD sed -i "s|https://github.com/mealie-recipes/mealie/commit/|https://github.com/mealie-recipes/mealie/releases/tag/|g" /opt/mealie/frontend/pages/admin/site-settings.vue
    $STD sed -i "s|value: data.buildId,|value: \"v${MEALIE_VERSION}\",|g" /opt/mealie/frontend/pages/admin/site-settings.vue
    $STD sed -i "s|value: data.production ? i18n.t(\"about.production\") : i18n.t(\"about.development\"),|value: \"bare-metal\",|g" /opt/mealie/frontend/pages/admin/site-settings.vue
    export NUXT_TELEMETRY_DISABLED=1
    cd /opt/mealie/frontend
    $STD yarn install --prefer-offline --frozen-lockfile --non-interactive --production=false --network-timeout 1000000
    $STD yarn generate
    msg_ok "已构建 Frontend"

    msg_info "正在复制 已构建 Frontend"
    mkdir -p /opt/mealie/mealie/frontend
    cp -r /opt/mealie/frontend/dist/* /opt/mealie/mealie/frontend/
    msg_ok "已复制 Frontend"

    msg_info "正在更新 NLTK Data"
    mkdir -p /nltk_data/
    cd /opt/mealie
    $STD uv run python -m nltk.downloader -d /nltk_data averaged_perceptron_tagger_eng
    msg_ok "Updated NLTK Data"

    msg_info "正在恢复 Configuration"
    mv -f /opt/mealie.env /opt/mealie/mealie.env
    cat <<'STARTEOF' >/opt/mealie/start.sh
#!/bin/bash
set -a
source /opt/mealie/mealie.env
set +a
exec uv run mealie
STARTEOF
    chmod +x /opt/mealie/start.sh
    msg_ok "Configuration restored"

    msg_info "正在启动 Service"
    systemctl start mealie
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:9000${CL}"

