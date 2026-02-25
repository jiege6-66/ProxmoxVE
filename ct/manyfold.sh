#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: bvdberg01 | Co-Author: SunFlowerOwl
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/manyfold3d/manyfold

APP="Manyfold"
var_tags="${var_tags:-3d}"
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
  if [[ ! -d /opt/manyfold ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "manyfold" "manyfold3d/manyfold"; then
    msg_info "正在停止 Services"
    systemctl stop manyfold.target manyfold-rails.1 manyfold-default_worker.1 manyfold-performance_worker.1
    msg_ok "已停止 Services"

    msg_info "正在备份 Data"
    CURRENT_VERSION=$(grep -oP 'APP_VERSION=\K[^ ]+' /opt/manyfold/.env || echo "unknown")
    cp -r /opt/manyfold/app/storage /opt/manyfold_storage_backup 2>/dev/null || true
    cp -r /opt/manyfold/app/tmp /opt/manyfold_tmp_backup 2>/dev/null || true
    cp /opt/manyfold/app/config/credentials.yml.enc /opt/manyfold_credentials.yml.enc 2>/dev/null || true
    cp /opt/manyfold/app/config/master.key /opt/manyfold_master.key 2>/dev/null || true
    $STD tar -czf "/opt/manyfold_${CURRENT_VERSION}_backup.tar.gz" -C /opt/manyfold app
    msg_ok "已备份 Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "manyfold" "manyfold3d/manyfold" "tarball" "latest" "/opt/manyfold/app"

    msg_info "正在配置 Manyfold"
    RUBY_INSTALL_VERSION=$(cat /opt/manyfold/app/.ruby-version)
    YARN_VERSION=$(grep '"packageManager":' /opt/manyfold/app/package.json | sed -E 's/.*"(yarn@[0-9\.]+)".*/\1/')
    RELEASE=$(get_latest_github_release "manyfold3d/manyfold")
    sed -i "s/^export APP_VERSION=.*/export APP_VERSION=$RELEASE/" "/opt/manyfold/.env"
    msg_ok "已配置 Manyfold"

    RUBY_VERSION=${RUBY_INSTALL_VERSION} RUBY_INSTALL_RAILS="true" HOME=/home/manyfold setup_ruby

    msg_info "正在安装 Manyfold"
    chown -R manyfold:manyfold {/home/manyfold,/opt/manyfold}
    chown -R manyfold:manyfold /opt/manyfold

    sudo -u manyfold bash -c '
            source /opt/manyfold/.env
            export PATH="/home/manyfold/.rbenv/bin:$PATH"
            eval "$(/home/manyfold/.rbenv/bin/rbenv init - bash)"
            cd /opt/manyfold/app
            gem install bundler sidekiq foreman
            bundle install
            corepack enable yarn
            corepack prepare '"$YARN_VERSION"' --activate
            corepack use '"$YARN_VERSION"'
            bin/rails db:migrate
            bin/rails assets:precompile
        '
    msg_ok "已安装 Manyfold"

    msg_info "正在恢复 Data"
    rm -rf /opt/manyfold/app/{storage,tmp,config/credentials.yml.enc,config/master.key}
    cp -r /opt/manyfold_storage_backup /opt/manyfold/app/storage 2>/dev/null || true
    cp -r /opt/manyfold_tmp_backup /opt/manyfold/app/tmp 2>/dev/null || true
    cp /opt/manyfold_credentials.yml.enc /opt/manyfold/app/config/credentials.yml.enc 2>/dev/null || true
    cp /opt/manyfold_master.key /opt/manyfold/app/config/master.key 2>/dev/null || true
    chown -R manyfold:manyfold /opt/manyfold/app/storage /opt/manyfold/app/tmp /opt/manyfold/app/config
    rm -rf /opt/manyfold_storage_backup /opt/manyfold_tmp_backup /opt/manyfold_credentials.yml.enc /opt/manyfold_master.key
    msg_ok "已恢复 Data"

    msg_info "正在重启 Services"
    source /opt/manyfold/.env
    export PATH="/home/manyfold/.rbenv/shims:/home/manyfold/.rbenv/bin:$PATH"
    $STD foreman export systemd /etc/systemd/system -a manyfold -u manyfold -f /opt/manyfold/app/Procfile
    for f in /etc/systemd/system/manyfold-*.service; do
      sed -i "s|/bin/bash -lc '|/bin/bash -lc 'source /opt/manyfold/.env \&\& |" "$f"
    done
    systemctl daemon-reload
    systemctl enable -q --now manyfold.target manyfold-rails.1 manyfold-default_worker.1 manyfold-performance_worker.1
    msg_ok "已重启 Services"
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
