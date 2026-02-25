#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: CrazyWolf13
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/lissy93/web-check

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
export DEBIAN_FRONTEND=noninteractive
$STD apt -y install --no-install-recommends \
  git \
  traceroute \
  make \
  g++ \
  traceroute \
  xvfb \
  dbus \
  xorg \
  xvfb \
  gtk2-engines-pixbuf \
  dbus-x11 \
  xfonts-base \
  xfonts-100dpi \
  xfonts-75dpi \
  xfonts-scalable \
  imagemagick \
  x11-apps
msg_ok "已安装依赖"

NODE_VERSION="22" NODE_MODULE="yarn" setup_nodejs

msg_info "设置 Python3"
$STD apt install -y python3
rm -rf /usr/lib/python3.*/EXTERNALLY-MANAGED
msg_ok "设置 Python3"

msg_info "正在安装 Chromium"
curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor -o /usr/share/keyrings/google-chrome-keyring.gpg
cat <<EOF | sudo tee /etc/apt/sources.list.d/google-chrome.sources >/dev/null
Types: deb
URIs: http://dl.google.com/linux/chrome/deb/
Suites: stable
Components: main
Architectures: amd64
Signed-By: /usr/share/keyrings/google-chrome-keyring.gpg
EOF
$STD apt update
$STD apt -y install \
  chromium \
  libxss1 \
  lsb-release
msg_ok "已安装 Chromium"

msg_info "正在设置 Chromium"
/usr/bin/chromium --no-sandbox --version >/etc/chromium-version
chmod 755 /usr/bin/chromium
msg_ok "设置 Chromium"

fetch_and_deploy_gh_release "web-check" "CrazyWolf13/web-check" "tarball"

msg_info "正在安装 Web-Check (Patience)"
cd /opt/web-check
cat <<'EOF' >/opt/web-check/.env
CHROME_PATH=/usr/bin/chromium
PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
HEADLESS=true
GOOGLE_CLOUD_API_KEY=''
REACT_APP_SHODAN_API_KEY=''
REACT_APP_WHO_API_KEY=''
SECURITY_TRAILS_API_KEY=''
CLOUDMERSIVE_API_KEY=''
TRANCO_USERNAME=''
TRANCO_API_KEY=''
URL_SCAN_API_KEY=''
BUILT_WITH_API_KEY=''
TORRENT_IP_API_KEY=''
PORT='3000'
DISABLE_GUI='false'
API_TIMEOUT_LIMIT='10000'
API_CORS_ORIGIN='*'
API_ENABLE_RATE_LIMIT='false'
REACT_APP_API_ENDPOINT='/api'
ENABLE_ANALYTICS='false'
EOF
$STD yarn install --frozen-lockfile --network-timeout 100000
msg_ok "已安装 Web-Check"

msg_info "正在构建 Web-Check"
$STD yarn build --production
msg_ok "已构建 Web-Check"

msg_info "正在创建 Service"
cat <<'EOF' >/opt/run_web-check.sh
#!/bin/bash
SCREEN_RESOLUTION="1280x1024x24"
if ! systemctl is-active --quiet dbus; then
  echo "Warning: dbus service is not running. Some features may not work properly."
fi
[[ -z "${DISPLAY}" ]] && export DISPLAY=":99"
Xvfb "${DISPLAY}" -screen 0 "${SCREEN_RESOLUTION}" &
XVFB_PID=$!
sleep 2
cd /opt/web-check
exec yarn start
EOF
chmod +x /opt/run_web-check.sh
cat <<'EOF' >/etc/systemd/system/web-check.service
[Unit]
Description=Web Check Service
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/web-check
EnvironmentFile=/opt/web-check/.env
ExecStartPre=/bin/bash -c "service dbus start || true"
ExecStartPre=/bin/bash -c "if ! pgrep -f 'Xvfb.*:99' > /dev/null; then Xvfb :99 -screen 0 1280x1024x24 & fi"
ExecStart=/opt/run_web-check.sh
Restart=on-failure
Environment=DISPLAY=:99

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now web-check
msg_ok "已创建 Service"

motd_ssh
customize
cleanup_lxc
