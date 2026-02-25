# 🤖 ProxmoxVE AI 贡献指南

> **本文档面向所有为本项目做出贡献的 AI 助手（GitHub Copilot、Claude、ChatGPT 等）。**

## 🎯 核心原则

### 1. **最大化使用 `tools.func` 函数**

我们有一个广泛的辅助函数库。当函数已经存在时，**绝不**自己实现解决方案！

### 2. **不要创建无意义的变量**

只在以下情况创建变量：

- 多次使用
- 提高可读性
- 用于配置

### 3. **一致的脚本结构**

所有脚本遵循相同的结构。不接受偏离。

### 4. **裸机安装**

我们的安装脚本**不使用 Docker**。所有应用程序直接安装在系统上。

---

## 📁 脚本类型及其结构

### CT 脚本 (`ct/AppName.sh`)

```bash
#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: AuthorName (GitHubUsername)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://application-url.com

APP="AppName"
var_tags="${var_tags:-tag1;tag2;tag3}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
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

  if [[ ! -d /opt/appname ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  if check_for_gh_release "appname" "YourUsername/YourRepo"; then
    msg_info "Stopping Service"
    systemctl stop appname
    msg_ok "Stopped Service"

    msg_info "Backing up Data"
    cp -r /opt/appname/data /opt/appname_data_backup
    msg_ok "Backed up Data"

    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "appname" "owner/repo" "tarball" "latest" "/opt/appname"

    # 构建步骤...

    msg_info "Restoring Data"
    cp -r /opt/appname_data_backup/. /opt/appname/data
    rm -rf /opt/appname_data_backup
    msg_ok "Restored Data"

    msg_info "Starting Service"
    systemctl start appname
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:PORT${CL}"
```

### 安装脚本 (`install/AppName-install.sh`)

```bash
#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: AuthorName (GitHubUsername)
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://application-url.com

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Dependencies"
$STD apt-get install -y \
  dependency1 \
  dependency2
msg_ok "Installed Dependencies"

# 运行时设置（始终使用我们的函数！）
NODE_VERSION="22" setup_nodejs
# 或
PG_VERSION="16" setup_postgresql
# 或
setup_uv
# 等等

fetch_and_deploy_gh_release "appname" "owner/repo" "tarball" "latest" "/opt/appname"

msg_info "Setting up Application"
cd /opt/appname
# 构建/设置步骤...
msg_ok "Set up Application"

msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/appname.service
[Unit]
Description=AppName Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/appname
ExecStart=/path/to/executable
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now appname
msg_ok "Created Service"

motd_ssh
customize
cleanup_lxc
```

---

## 🔧 可用的辅助函数

### 发布管理

| 函数                          | 描述                  | 示例                                                          |
| ----------------------------- | --------------------- | ------------------------------------------------------------- |
| `fetch_and_deploy_gh_release` | 获取并安装 GitHub 发布 | `fetch_and_deploy_gh_release "app" "owner/repo"`              |
| `check_for_gh_release`        | 检查新版本            | `if check_for_gh_release "app" "YourUsername/YourRepo"; then` |

**`fetch_and_deploy_gh_release` 的模式：**

```bash
# Tarball/源码（标准）
fetch_and_deploy_gh_release "appname" "owner/repo"

# 二进制文件（.deb）
fetch_and_deploy_gh_release "appname" "owner/repo" "binary"

# 预构建归档
fetch_and_deploy_gh_release "appname" "owner/repo" "prebuild" "latest" "/opt/appname" "filename.tar.gz"

# 单个二进制文件
fetch_and_deploy_gh_release "appname" "owner/repo" "singlefile" "latest" "/opt/appname" "binary-linux-amd64"
```

**清洁安装标志：**

```bash
CLEAN_INSTALL=1 fetch_and_deploy_gh_release "appname" "owner/repo"
```

### 运行时/语言设置

| 函数           | 变量                          | 示例                                                 |
| -------------- | ----------------------------- | ---------------------------------------------------- |
| `setup_nodejs` | `NODE_VERSION`, `NODE_MODULE` | `NODE_VERSION="22" setup_nodejs`                     |
| `setup_uv`     | `PYTHON_VERSION`              | `PYTHON_VERSION="3.12" setup_uv`                     |
| `setup_go`     | `GO_VERSION`                  | `GO_VERSION="1.22" setup_go`                         |
| `setup_rust`   | `RUST_VERSION`, `RUST_CRATES` | `RUST_CRATES="monolith" setup_rust`                  |
| `setup_ruby`   | `RUBY_VERSION`                | `RUBY_VERSION="3.3" setup_ruby`                      |
| `setup_java`   | `JAVA_VERSION`                | `JAVA_VERSION="21" setup_java`                       |
| `setup_php`    | `PHP_VERSION`, `PHP_MODULES`  | `PHP_VERSION="8.3" PHP_MODULES="redis,gd" setup_php` |

### 数据库设置

| 函数                  | 变量                                 | 示例                                                        |
| --------------------- | ------------------------------------ | ----------------------------------------------------------- |
| `setup_postgresql`    | `PG_VERSION`, `PG_MODULES`           | `PG_VERSION="16" setup_postgresql`                          |
| `setup_postgresql_db` | `PG_DB_NAME`, `PG_DB_USER`           | `PG_DB_NAME="mydb" PG_DB_USER="myuser" setup_postgresql_db` |
| `setup_mariadb_db`    | `MARIADB_DB_NAME`, `MARIADB_DB_USER` | `MARIADB_DB_NAME="mydb" setup_mariadb_db`                   |
| `setup_mysql`         | `MYSQL_VERSION`                      | `setup_mysql`                                               |
| `setup_mongodb`       | `MONGO_VERSION`                      | `setup_mongodb`                                             |
| `setup_clickhouse`    | -                                    | `setup_clickhouse`                                          |

### 工具和实用程序

| 函数                | 描述                       |
| ------------------- | -------------------------- |
| `setup_adminer`     | 安装 Adminer 用于数据库管理 |
| `setup_composer`    | 安装 PHP Composer          |
| `setup_ffmpeg`      | 安装 FFmpeg                |
| `setup_imagemagick` | 安装 ImageMagick           |
| `setup_gs`          | 安装 Ghostscript           |
| `setup_hwaccel`     | 配置硬件加速               |

### 辅助工具

| 函数                          | 描述                 | 示例                                      |
| ----------------------------- | -------------------- | ----------------------------------------- |
| `import_local_ip`             | 设置 `$LOCAL_IP` 变量 | `import_local_ip`                         |
| `ensure_dependencies`         | 检查/安装依赖        | `ensure_dependencies curl jq`             |
| `install_packages_with_retry` | 带重试的 APT 安装    | `install_packages_with_retry nginx redis` |

---

## ❌ 反模式（绝不使用！）

### 1. 无意义的变量

```bash
# ❌ 错误 - 不必要的变量
APP_NAME="myapp"
APP_DIR="/opt/${APP_NAME}"
APP_USER="root"
APP_PORT="3000"
cd $APP_DIR

# ✅ 正确 - 直接使用
cd /opt/myapp
```

### 2. 自定义下载逻辑

```bash
# ❌ 错误 - 自定义 wget/curl 逻辑
RELEASE=$(curl -s https://api.github.com/repos/YourUsername/YourRepo/releases/latest | jq -r '.tag_name')
wget https://github.com/YourUsername/YourRepo/archive/${RELEASE}.tar.gz
tar -xzf ${RELEASE}.tar.gz
mv repo-${RELEASE} /opt/myapp

# ✅ 正确 - 使用我们的函数
fetch_and_deploy_gh_release "myapp" "YourUsername/YourRepo" "tarball" "latest" "/opt/myapp"
```

### 3. 自定义版本检查逻辑

```bash
# ❌ 错误 - 自定义版本检查
CURRENT=$(cat /opt/myapp/version.txt)
LATEST=$(curl -s https://api.github.com/repos/YourUsername/YourRepo/releases/latest | jq -r '.tag_name')
if [[ "$CURRENT" != "$LATEST" ]]; then
  # 更新...
fi

# ✅ 正确 - 使用我们的函数
if check_for_gh_release "myapp" "YourUsername/YourRepo"; then
  # 更新...
fi
```

### 4. 基于 Docker 的安装

```bash
# ❌ 错误 - 使用 Docker
docker pull myapp/myapp:latest
docker run -d --name myapp myapp/myapp:latest

# ✅ 正确 - 裸机安装
fetch_and_deploy_gh_release "myapp" "YourUsername/YourRepo"
npm install && npm run build
```

### 5. 自定义运行时安装

```bash
# ❌ 错误 - 自定义 Node.js 安装
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt install -y nodejs

# ✅ 正确 - 使用我们的函数
NODE_VERSION="22" setup_nodejs
```

### 6. 冗余的 echo 语句

```bash
# ❌ 错误 - 自定义日志消息
echo "Installing dependencies..."
apt install -y curl
echo "Done!"

# ✅ 正确 - 使用 msg_info/msg_ok
msg_info "Installing Dependencies"
$STD apt install -y curl
msg_ok "Installed Dependencies"
```

### 7. 缺少 $STD 使用

```bash
# ❌ 错误 - apt 不带 $STD
apt install -y nginx

# ✅ 正确 - 使用 $STD 实现静默输出
$STD apt install -y nginx
```

### 8. 在 msg 块中包装 `tools.func` 函数

```bash
# ❌ 错误 - tools.func 函数有自己的 msg_info/msg_ok！
msg_info "Installing Node.js"
NODE_VERSION="22" setup_nodejs
msg_ok "Installed Node.js"

msg_info "Updating Application"
CLEAN_INSTALL=1 fetch_and_deploy_gh_release "appname" "owner/repo" "tarball" "latest" "/opt/appname"
msg_ok "Updated Application"

# ✅ 正确 - 直接调用，不使用 msg 包装
NODE_VERSION="22" setup_nodejs

CLEAN_INSTALL=1 fetch_and_deploy_gh_release "appname" "owner/repo" "tarball" "latest" "/opt/appname"
```

**带有内置消息的函数（绝不在 msg 块中包装）：**

- `fetch_and_deploy_gh_release`
- `check_for_gh_release`
- `setup_nodejs`
- `setup_postgresql` / `setup_postgresql_db`
- `setup_mariadb` / `setup_mariadb_db`
- `setup_mongodb`
- `setup_mysql`
- `setup_ruby`
- `setup_go`
- `setup_java`
- `setup_php`
- `setup_uv`
- `setup_rust`
- `setup_composer`
- `setup_ffmpeg`
- `setup_imagemagick`
- `setup_gs`
- `setup_adminer`
- `setup_hwaccel`

### 9. 创建不必要的系统用户

```bash
# ❌ 错误 - LXC 容器以 root 运行，不需要单独的用户
useradd -m -s /usr/bin/bash appuser
chown -R appuser:appuser /opt/appname
sudo -u appuser npm install

# ✅ 正确 - 直接以 root 运行
cd /opt/appname
$STD npm install
```

### 10. 在 .env 文件中使用 `export`

```bash
# ❌ 错误 - export 在 .env 文件中是不必要的
cat <<EOF >/opt/appname/.env
export DATABASE_URL=postgres://...
export SECRET_KEY=abc123
export NODE_ENV=production
EOF

# ✅ 正确 - 简单的 KEY=VALUE 格式（文件使用 set -a 加载）
cat <<EOF >/opt/appname/.env
DATABASE_URL=postgres://...
SECRET_KEY=abc123
NODE_ENV=production
EOF
```

### 11. 使用外部 Shell 脚本

```bash
# ❌ 错误 - 执行外部脚本
cat <<'EOF' >/opt/appname/install_script.sh
#!/bin/bash
cd /opt/appname
npm install
npm run build
EOF
chmod +x /opt/appname/install_script.sh
$STD bash /opt/appname/install_script.sh
rm -f /opt/appname/install_script.sh

# ✅ 正确 - 直接运行命令
cd /opt/appname
$STD npm install
$STD npm run build
```

### 12. 在 LXC 容器中使用 `sudo`

```bash
# ❌ 错误 - sudo 在 LXC 中是不必要的（已经是 root）
sudo -u postgres psql -c "CREATE DATABASE mydb;"
sudo -u appuser npm install

# ✅ 正确 - 使用函数或直接以 root 运行
PG_DB_NAME="mydb" PG_DB_USER="myuser" setup_postgresql_db

cd /opt/appname
$STD npm install
```

### 13. 不必要的 `systemctl daemon-reload`

```bash
# ❌ 错误 - daemon-reload 仅在修改现有服务时需要
cat <<EOF >/etc/systemd/system/appname.service
# ... 服务配置 ...
EOF
systemctl daemon-reload  # 新服务不需要！
systemctl enable -q --now appname

# ✅ 正确 - 新服务不需要 daemon-reload
cat <<EOF >/etc/systemd/system/appname.service
# ... 服务配置 ...
EOF
systemctl enable -q --now appname
```

### 14. 创建自定义凭据文件

```bash
# ❌ 错误 - 自定义凭据文件不是标准模板的一部分
msg_info "Saving Credentials"
cat <<EOF >~/appname.creds
Database User: ${DB_USER}
Database Pass: ${DB_PASS}
EOF
msg_ok "Saved Credentials"

# ✅ 正确 - 凭据存储在 .env 中或仅在最终消息中显示
# 如果使用 setup_postgresql_db / setup_mariadb_db，会自动创建标准的 ~/[appname].creds
```

### 15. 错误的页脚模式

```bash
# ❌ 错误 - 旧的清理模式带 msg 块
motd_ssh
customize

msg_info "Cleaning up"
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"

# ✅ 正确 - 使用 cleanup_lxc 函数
motd_ssh
customize
cleanup_lxc
```

### 16. 手动创建数据库而不是使用函数

```bash
# ❌ 错误 - 手动创建数据库
DB_USER="myuser"
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | cut -c1-13)
$STD sudo -u postgres psql -c "CREATE ROLE $DB_USER WITH LOGIN PASSWORD '$DB_PASS';"
$STD sudo -u postgres psql -c "CREATE DATABASE mydb WITH OWNER $DB_USER;"
$STD sudo -u postgres psql -d mydb -c "CREATE EXTENSION IF NOT EXISTS postgis;"

# ✅ 正确 - 使用 setup_postgresql_db 函数
# 这会自动设置 PG_DB_USER、PG_DB_PASS、PG_DB_NAME
PG_DB_NAME="mydb" PG_DB_USER="myuser" PG_DB_EXTENSIONS="postgis" setup_postgresql_db
```

### 17. 不使用 Heredoc 写入文件

```bash
# ❌ 错误 - echo / printf / tee
echo "# Config" > /opt/app/config.yml
echo "port: 3000" >> /opt/app/config.yml

printf "# Config\nport: 3000\n" > /opt/app/config.yml
cat config.yml | tee /opt/app/config.yml
```

```bash
# ✅ 正确 - 始终使用单个 heredoc
cat <<EOF >/opt/app/config.yml
# Config
port: 3000
EOF
```

---

## 📝 重要规则

### 变量声明（CT 脚本）

```bash
# 标准声明（始终存在）
APP="AppName"
var_tags="${var_tags:-tag1;tag2}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"
```

### 更新脚本模式

```bash
function update_script() {
  header_info
  check_container_storage
  check_container_resources

  # 1. 检查安装是否存在
  if [[ ! -d /opt/appname ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # 2. 检查更新
  if check_for_gh_release "appname" "YourUsername/YourRepo"; then
    # 3. 停止服务
    msg_info "Stopping Service"
    systemctl stop appname
    msg_ok "Stopped Service"

    # 4. 备份数据（如果存在）
    msg_info "Backing up Data"
    cp -r /opt/appname/data /opt/appname_data_backup
    msg_ok "Backed up Data"

    # 5. 执行清洁安装
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "appname" "owner/repo" "tarball" "latest" "/opt/appname"

    # 6. 重新构建（如果需要）
    cd /opt/appname
    $STD npm install
    $STD npm run build

    # 7. 恢复数据
    msg_info "Restoring Data"
    cp -r /opt/appname_data_backup/. /opt/appname/data
    rm -rf /opt/appname_data_backup
    msg_ok "Restored Data"

    # 8. 启动服务
    msg_info "Starting Service"
    systemctl start appname
    msg_ok "Started Service"
    msg_ok "Updated successfully!"
  fi
  exit  # 重要：始终以 exit 结束！
}
```

### Systemd 服务模式

```bash
msg_info "Creating Service"
cat <<EOF >/etc/systemd/system/appname.service
[Unit]
Description=AppName Service
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/opt/appname
Environment=NODE_ENV=production
ExecStart=/usr/bin/node /opt/appname/server.js
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now appname
msg_ok "Created Service"
```

### 安装脚本页脚

```bash
# 始终在安装脚本末尾：
motd_ssh
customize
cleanup_lxc
```

---

## 📖 参考：良好的示例脚本

查看这些最近实现良好的应用程序作为参考：

### 容器脚本（最新 10 个）

- [ct/thingsboard.sh](../ct/thingsboard.sh) - 带有正确 update_script 的物联网平台
- [ct/unifi-os-server.sh](../ct/unifi-os-server.sh) - 使用 podman 的复杂设置
- [ct/trip.sh](../ct/trip.sh) - 简单的 Ruby 应用
- [ct/fladder.sh](../ct/fladder.sh) - 带数据库的媒体应用
- [ct/qui.sh](../ct/qui.sh) - 轻量级实用程序
- [ct/kutt.sh](../ct/kutt.sh) - 带 PostgreSQL 的 Node.js
- [ct/flatnotes.sh](../ct/flatnotes.sh) - Python 笔记应用
- [ct/investbrain.sh](../ct/investbrain.sh) - 财务应用
- [ct/gwn-manager.sh](../ct/gwn-manager.sh) - 网络管理
- [ct/sportarr.sh](../ct/sportarr.sh) - 专门的 \*Arr 变体

### 安装脚本（最新）

- [install/unifi-os-server-install.sh](../install/unifi-os-server-install.sh) - 带 API 集成的复杂设置
- [install/trip-install.sh](../install/trip-install.sh) - Rails 应用程序设置
- [install/mail-archiver-install.sh](../install/mail-archiver-install.sh) - 电子邮件相关服务

**需要注意的关键点：**

- 使用 `catch_errors` 进行正确的错误处理
- 使用 `check_for_gh_release` 和 `fetch_and_deploy_gh_release`
- `update_script` 中正确的备份/恢复模式
- 页脚始终以 `motd_ssh`、`customize`、`cleanup_lxc` 结束
- 为每个应用创建 JSON 元数据文件

---

## 📄 JSON 元数据文件

每个应用程序都需要在 `frontend/public/json/<appname>.json` 中有一个 JSON 元数据文件。

### JSON 结构

```json
{
  "name": "AppName",
  "slug": "appname",
  "categories": [1],
  "date_created": "2026-01-16",
  "type": "ct",
  "updateable": true,
  "privileged": false,
  "interface_port": 3000,
  "documentation": "https://docs.appname.com/",
  "website": "https://appname.com/",
  "logo": "https://cdn.jsdelivr.net/gh/selfhst/icons@main/webp/appname.webp",
  "config_path": "/opt/appname/.env",
  "description": "应用程序及其用途的简短描述。",
  "install_methods": [
    {
      "type": "default",
      "script": "ct/appname.sh",
      "resources": {
        "cpu": 2,
        "ram": 2048,
        "hdd": 8,
        "os": "Debian",
        "version": "13"
      }
    }
  ],
  "default_credentials": {
    "username": null,
    "password": null
  },
  "notes": []
}
```

### 必填字段

| 字段                  | 类型    | 描述                                   |
| --------------------- | ------- | -------------------------------------- |
| `name`                | string  | 应用程序的显示名称                     |
| `slug`                | string  | 小写，无空格，用于文件名               |
| `categories`          | array   | 类别 ID - 见下面的类别列表             |
| `date_created`        | string  | 创建日期（YYYY-MM-DD）                 |
| `type`                | string  | `ct` 表示容器，`vm` 表示虚拟机         |
| `updateable`          | boolean | 是否实现了 update_script               |
| `privileged`          | boolean | 容器是否需要特权模式                   |
| `interface_port`      | number  | 主要 Web 界面端口（或 `null`）         |
| `documentation`       | string  | 官方文档链接                           |
| `website`             | string  | 官方网站链接                           |
| `logo`                | string  | 应用程序徽标 URL（最好是 selfhst 图标）|
| `config_path`         | string  | 主配置文件路径（或空字符串）           |
| `description`         | string  | 应用程序的简要描述                     |
| `install_methods`     | array   | 安装配置                               |
| `default_credentials` | object  | 默认用户名/密码（或 null）             |
| `notes`               | array   | 附加说明/警告                          |

### 类别

| ID  | 类别                      |
| --- | ------------------------- |
| 0   | 杂项                      |
| 1   | Proxmox 和虚拟化          |
| 2   | 操作系统                  |
| 3   | 容器和 Docker             |
| 4   | 网络和防火墙              |
| 5   | 广告拦截和 DNS            |
| 6   | 身份验证和安全            |
| 7   | 备份和恢复                |
| 8   | 数据库                    |
| 9   | 监控和分析                |
| 10  | 仪表板和前端              |
| 11  | 文件和下载                |
| 12  | 文档和笔记                |
| 13  | 媒体和流媒体              |
| 14  | \*Arr 套件                |
| 15  | NVR 和摄像头              |
| 16  | 物联网和智能家居          |
| 17  | ZigBee、Z-Wave 和 Matter |
| 18  | MQTT 和消息传递           |
| 19  | 自动化和调度              |
| 20  | AI / 编码和开发工具       |
| 21  | Web 服务器和代理          |
| 22  | 机器人和 ChatOps          |
| 23  | 财务和预算                |
| 24  | 游戏和休闲                |
| 25  | 商业和 ERP                |

### 注释格式

```json
"notes": [
    {
        "text": "首次登录后更改默认密码！",
        "type": "warning"
    },
    {
        "text": "需要至少 4GB RAM 以获得最佳性能。",
        "type": "info"
    }
]
```

**注释类型：** `info`、`warning`、`error`

### 带凭据的示例

```json
"default_credentials": {
    "username": "admin
