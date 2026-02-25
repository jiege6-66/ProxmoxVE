#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/Freika/dawarich

APP="Dawarich"
var_tags="${var_tags:-location;tracking;gps}"
var_cpu="${var_cpu:-4}"
var_ram="${var_ram:-4096}"
var_disk="${var_disk:-15}"
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

  if [[ ! -d /opt/dawarich ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "dawarich" "Freika/dawarich"; then
    msg_info "正在停止 Services"
    systemctl stop dawarich-web dawarich-worker
    msg_ok "已停止 Services"

    msg_info "正在备份 Data"
    cp -r /opt/dawarich/app/storage /opt/dawarich_storage_backup 2>/dev/null || true
    cp /opt/dawarich/app/config/master.key /opt/dawarich_master.key 2>/dev/null || true
    cp /opt/dawarich/app/config/credentials.yml.enc /opt/dawarich_credentials.yml.enc 2>/dev/null || true
    msg_ok "已备份 Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "dawarich" "Freika/dawarich" "tarball" "latest" "/opt/dawarich/app"

    RUBY_VERSION=$(cat /opt/dawarich/app/.ruby-version 2>/dev/null || echo "3.4.6")
    RUBY_VERSION=${RUBY_VERSION} RUBY_INSTALL_RAILS="false" setup_ruby

    msg_info "正在运行 Migrations"
    cd /opt/dawarich/app
    source /root/.profile
    export PATH="/root/.rbenv/shims:/root/.rbenv/bin:$PATH"
    eval "$(/root/.rbenv/bin/rbenv init - bash)"

    set -a && source /opt/dawarich/.env && set +a

    $STD bundle config set --local deployment 'true'
    $STD bundle config set --local without 'development test'
    $STD bundle install

    if [[ -f /opt/dawarich/package.json ]]; then
      cd /opt/dawarich
      $STD npm install
      cd /opt/dawarich/app
    elif [[ -f /opt/dawarich/app/package.json ]]; then
      $STD npm install
    fi

    $STD bundle exec rake assets:precompile
    $STD bundle exec rails db:migrate
    $STD bundle exec rake data:migrate
    msg_ok "Ran Migrations"

    msg_info "正在恢复 Data"
    cp -r /opt/dawarich_storage_backup/. /opt/dawarich/app/storage/ 2>/dev/null || true
    cp /opt/dawarich_master.key /opt/dawarich/app/config/master.key 2>/dev/null || true
    cp /opt/dawarich_credentials.yml.enc /opt/dawarich/app/config/credentials.yml.enc 2>/dev/null || true
    rm -rf /opt/dawarich_storage_backup /opt/dawarich_master.key /opt/dawarich_credentials.yml.enc
    msg_ok "已恢复 Data"

    msg_info "正在启动 Services"
    systemctl start dawarich-web dawarich-worker
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
