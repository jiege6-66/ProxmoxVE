#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: MickLesk (CanbiZ)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/booklore-app/BookLore

APP="BookLore"
var_tags="${var_tags:-books;library}"
var_cpu="${var_cpu:-3}"
var_ram="${var_ram:-3072}"
var_disk="${var_disk:-7}"
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

  if [[ ! -d /opt/booklore ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  if check_for_gh_release "booklore" "booklore-app/BookLore"; then
    JAVA_VERSION="25" setup_java
    NODE_VERSION="22" setup_nodejs
    setup_mariadb
    setup_yq

    msg_info "正在停止 Service"
    systemctl stop booklore
    msg_ok "已停止 Service"

    if grep -qE "^BOOKLORE_(DATA_PATH|BOOKDROP_PATH|BOOKS_PATH|PORT)=" /opt/booklore_storage/.env 2>/dev/null; then
      msg_info "正在迁移 old environment variables"
      sed -i 's/^BOOKLORE_DATA_PATH=/APP_PATH_CONFIG=/g' /opt/booklore_storage/.env
      sed -i 's/^BOOKLORE_BOOKDROP_PATH=/APP_BOOKDROP_FOLDER=/g' /opt/booklore_storage/.env
      sed -i '/^BOOKLORE_BOOKS_PATH=/d' /opt/booklore_storage/.env
      sed -i '/^BOOKLORE_PORT=/d' /opt/booklore_storage/.env
      msg_ok "已迁移 old environment variables"
    fi

    msg_info "正在备份 old installation"
    mv /opt/booklore /opt/booklore_bak
    msg_ok "已备份 old installation"

    fetch_and_deploy_gh_release "booklore" "booklore-app/BookLore" "tarball"

    msg_info "正在构建 Frontend"
    cd /opt/booklore/booklore-ui
    $STD npm install --force
    $STD npm run build --configuration=production
    msg_ok "已构建 Frontend"

    msg_info "Embedding Frontend into Backend"
    mkdir -p /opt/booklore/booklore-api/src/main/resources/static
    cp -r /opt/booklore/booklore-ui/dist/booklore/browser/* /opt/booklore/booklore-api/src/main/resources/static/
    msg_ok "Embedded Frontend into Backend"

    msg_info "正在构建 Backend"
    cd /opt/booklore/booklore-api
    APP_VERSION=$(get_latest_github_release "booklore-app/BookLore")
    yq eval ".app.version = \"${APP_VERSION}\"" -i src/main/resources/application.yaml
    $STD ./gradlew clean build -x test --no-daemon
    mkdir -p /opt/booklore/dist
    JAR_PATH=$(find /opt/booklore/booklore-api/build/libs -maxdepth 1 -type f -name "booklore-api-*.jar" ! -name "*plain*" | head -n1)
    if [[ -z "$JAR_PATH" ]]; then
      msg_error "Backend JAR 未找到"
      exit
    fi
    cp "$JAR_PATH" /opt/booklore/dist/app.jar
    msg_ok "已构建 Backend"

    if systemctl is-active --quiet nginx 2>/dev/null; then
      msg_info "正在移除 Nginx (no longer needed)"
      systemctl disable --now nginx
      $STD apt-get purge -y nginx nginx-common
      msg_ok "已移除 Nginx"
    fi

    if ! grep -q "^SERVER_PORT=" /opt/booklore_storage/.env 2>/dev/null; then
      echo "SERVER_PORT=6060" >>/opt/booklore_storage/.env
    fi

    sed -i 's|ExecStart=/usr/bin/java -jar|ExecStart=/usr/bin/java -XX:+UseG1GC -XX:+UseStringDeduplication -XX:+UseCompactObjectHeaders -jar|' /etc/systemd/system/booklore.service
    systemctl daemon-reload

    msg_info "正在启动 Service"
    systemctl start booklore
    rm -rf /opt/booklore_bak
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
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:6060${CL}"
