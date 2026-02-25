#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: vhsdream
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://sure.am

APP="Sure"
var_tags="${var_tags:-finance}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
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

  if [[ ! -d /opt/sure ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "Sure" "we-promise/sure"; then
    if [[ ! -f /etc/systemd/system/sure-worker.service ]]; then
      cat <<EOF >/etc/systemd/system/sure-worker.service
[Unit]
Description=Sure Background Worker (Sidekiq)
After=network.target redis-server.service

[Service]
Type=simple
WorkingDirectory=/opt/sure
Environment=RAILS_ENV=production
Environment=BUNDLE_DEPLOYMENT=1
Environment=BUNDLE_WITHOUT=development
Environment=PATH=/root/.rbenv/shims:/root/.rbenv/bin:/usr/bin:/usr/local/bin:/sbin:/bin
EnvironmentFile=/etc/sure/.env
ExecStart=/opt/sure/bin/bundle exec sidekiq -e production
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF
      systemctl enable -q sure-worker
      msg_info "正在停止 Service"
      $STD systemctl stop sure
      msg_ok "已停止 Service"
    else
      msg_info "正在停止 services"
      $STD systemctl stop sure-worker sure
      msg_ok "已停止 services"
    fi

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "Sure" "we-promise/sure" "tarball" "latest" "/opt/sure"
    RUBY_VERSION="$(cat /opt/sure/.ruby-version)" RUBY_INSTALL_RAILS=false setup_ruby

    msg_info "正在更新 Sure"
    source ~/.profile
    cd /opt/sure
    export RAILS_ENV=production
    export BUNDLE_DEPLOYMENT=1
    export BUNDLE_WITHOUT=development
    $STD ./bin/bundle install
    $STD ./bin/bundle exec bootsnap precompile --gemfile -j 0
    $STD ./bin/bundle exec bootsnap precompile -j 0 app/ lib/
    export SECRET_KEY_BASE_DUMMY=1 && $STD ./bin/rails assets:precompile
    unset SECRET_KEY_BASE_DUMMY
    msg_ok "Updated Sure"

    msg_info "正在启动 Services"
    $STD systemctl start sure sure-worker
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
