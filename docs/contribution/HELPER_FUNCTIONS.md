# 🛠️ 辅助函数参考

**`tools.func` 中所有可用辅助函数的快速参考**

> 这些函数通过 `$FUNCTIONS_FILE_PATH` 在安装脚本中自动可用

---

## 📋 目录

- [推荐学习的脚本](#推荐学习的脚本)
- [运行时与语言设置](#运行时与语言设置)
- [数据库设置](#数据库设置)
- [GitHub Release 辅助函数](#github-release-辅助函数)
- [工具与实用程序](#工具与实用程序)
- [SSL/TLS](#ssltls)
- [实用函数](#实用函数)
- [包管理](#包管理)

---

## 📚 推荐学习的脚本

**从真实、实现良好的脚本中学习。每个应用需要两个协同工作的文件：**

| 文件               | 位置                     | 用途                                                                  |
| ------------------ | ---------------------------- | ------------------------------------------------------------------------ |
| **CT 脚本**      | `ct/appname.sh`              | 在 **Proxmox 主机**上运行 - 创建容器，包含 `update_script()` |
| **安装脚本** | `install/appname-install.sh` | 在**容器内**运行 - 安装和配置应用              |

> ⚠️ **两个文件都是必需的！** CT 脚本在容器创建期间自动调用安装脚本。

安装脚本**不是**由用户直接运行的；它们由 CT 脚本在容器内调用。

### Node.js + PostgreSQL

**Koel** - 使用 PHP + Node.js + PostgreSQL 的音乐流媒体
| 文件 | 链接 |
| ----------------- | -------------------------------------------------------- |
| CT (更新逻辑) | [ct/koel.sh](../../ct/koel.sh) |
| 安装 | [install/koel-install.sh](../../install/koel-install.sh) |

**Actual Budget** - 使用 npm 全局安装的财务应用
| 文件 | 链接 |
| ----------------- | ------------------------------------------------------------------------ |
| CT (更新逻辑) | [ct/actualbudget.sh](../../ct/actualbudget.sh) |
| 安装 | [install/actualbudget-install.sh](../../install/actualbudget-install.sh) |

### Python + uv

**MeTube** - 使用 Python uv + Node.js + Deno 的 YouTube 下载器
| 文件 | 链接 |
| ----------------- | ------------------------------------------------------------ |
| CT (更新逻辑) | [ct/metube.sh](../../ct/metube.sh) |
| 安装 | [install/metube-install.sh](../../install/metube-install.sh) |

**Endurain** - 使用 Python uv + PostgreSQL/PostGIS 的健身追踪器
| 文件 | 链接 |
| ----------------- | ---------------------------------------------------------------- |
| CT (更新逻辑) | [ct/endurain.sh](../../ct/endurain.sh) |
| 安装 | [install/endurain-install.sh](../../install/endurain-install.sh) |

### Java + Gradle

**BookLore** - 使用 Java 21 + Gradle + MariaDB + Nginx 的图书管理
| 文件 | 链接 |
| ----------------- | -------------------------------------------------------------- |
| CT (更新逻辑) | [ct/booklore.sh](../../ct/booklore.sh) |
| 安装 | [install/booklore-install.sh](../../install/booklore-install.sh) |

### Pnpm + Meilisearch

**KaraKeep** - 使用 Pnpm + Meilisearch + Puppeteer 的书签管理器
| 文件 | 链接 |
| ----------------- | -------------------------------------------------------------- |
| CT (更新逻辑) | [ct/karakeep.sh](../../ct/karakeep.sh) |
| 安装 | [install/karakeep-install.sh](../../install/karakeep-install.sh) |

### PHP + MariaDB/MySQL

**Wallabag** - 使用 PHP + MariaDB + Redis + Nginx 的稍后阅读应用
| 文件 | 链接 |
| ----------------- | ---------------------------------------------------------------- |
| CT (更新逻辑) | [ct/wallabag.sh](../../ct/wallabag.sh) |
| 安装 | [install/wallabag-install.sh](../../install/wallabag-install.sh) |

**InvoiceNinja** - 使用 PHP + MariaDB + Supervisor 的发票系统
| 文件 | 链接 |
| ----------------- | ------------------------------------------------------------------------ |
| CT (更新逻辑) | [ct/invoiceninja.sh](../../ct/invoiceninja.sh) |
| 安装 | [install/invoiceninja-install.sh](../../install/invoiceninja-install.sh) |

**BookStack** - 使用 PHP + MariaDB + Apache 的 Wiki/文档系统
| 文件 | 链接 |
| ----------------- | ------------------------------------------------------------------ |
| CT (更新逻辑) | [ct/bookstack.sh](../../ct/bookstack.sh) |
| 安装 | [install/bookstack-install.sh](../../install/bookstack-install.sh) |

### PHP + SQLite (简单)

**Speedtest Tracker** - 使用 PHP + SQLite + Nginx 的网速测试
| 文件 | 链接 |
| ----------------- | ---------------------------------------------------------------------------------- |
| CT (更新逻辑) | [ct/speedtest-tracker.sh](../../ct/speedtest-tracker.sh) |
| 安装 | [install/speedtest-tracker-install.sh](../../install/speedtest-tracker-install.sh) |

---

## 运行时与语言设置

### `setup_nodejs`

从 NodeSource 仓库安装 Node.js。

```bash
# 默认 (Node.js 24)
setup_nodejs

# 指定版本
NODE_VERSION="20" setup_nodejs
NODE_VERSION="22" setup_nodejs
NODE_VERSION="24" setup_nodejs
```

### `setup_go`

安装 Go 编程语言（最新稳定版）。

```bash
setup_go

# 在脚本中使用
setup_go
cd /opt/myapp
$STD go build -o myapp .
```

### `setup_rust`

通过 rustup 安装 Rust。

```bash
setup_rust

# 在脚本中使用
setup_rust
source "$HOME/.cargo/env"
$STD cargo build --release
```

### `setup_uv`

安装 Python uv 包管理器（快速的 pip/venv 替代品）。

```bash
# 默认
setup_uv

# 安装特定 Python 版本
PYTHON_VERSION="3.12" setup_uv

# 在脚本中使用
setup_uv
cd /opt/myapp
$STD uv sync --locked
```

### `setup_ruby`

从官方仓库安装 Ruby。

```bash
setup_ruby
```

### `setup_php`

安装 PHP，支持可配置的模块和 FPM/Apache。

```bash
# 基础 PHP
setup_php

# 完整配置
PHP_VERSION="8.4" \
PHP_MODULE="mysqli,gd,curl,mbstring,xml,zip,ldap" \
PHP_FPM="YES" \
PHP_APACHE="YES" \
setup_php
```

**环境变量：**
| 变量 | 默认值 | 说明 |
| ------------- | ------- | ------------------------------- |
| `PHP_VERSION` | `8.4` | 要安装的 PHP 版本 |
| `PHP_MODULE` | `""` | 逗号分隔的模块列表 |
| `PHP_FPM` | `NO` | 安装 PHP-FPM |
| `PHP_APACHE` | `NO` | 安装 Apache 模块 |

### `setup_composer`

安装 PHP Composer 包管理器。

```bash
setup_php
setup_composer

# 在脚本中使用
$STD composer install --no-dev
```

### `setup_java`

安装 Java (OpenJDK)。

```bash
# 默认 (Java 21)
setup_java

# 指定版本
JAVA_VERSION="17" setup_java
JAVA_VERSION="21" setup_java
```

---

## 数据库设置

### `setup_mariadb`

安装 MariaDB 服务器。

```bash
setup_mariadb
```

### `setup_mariadb_db`

创建 MariaDB 数据库和用户。设置 `$MARIADB_DB_PASS` 为生成的密码。

```bash
setup_mariadb
MARIADB_DB_NAME="myapp_db" MARIADB_DB_USER="myapp_user" setup_mariadb_db

# 调用后，以下变量可用：
# $MARIADB_DB_NAME - 数据库名称
# $MARIADB_DB_USER - 数据库用户
# $MARIADB_DB_PASS - 生成的密码（保存到 ~/[appname].creds）
```

### `setup_mysql`

安装 MySQL 服务器。

```bash
setup_mysql
```

### `setup_postgresql`

安装 PostgreSQL 服务器。

```bash
# 默认 (PostgreSQL 16)
setup_postgresql

# 指定版本
PG_VERSION="16" setup_postgresql
PG_VERSION="16" setup_postgresql
```

### `setup_postgresql_db`

创建 PostgreSQL 数据库和用户。设置 `$PG_DB_PASS` 为生成的密码。

```bash
PG_VERSION="17" setup_postgresql
PG_DB_NAME="myapp_db" PG_DB_USER="myapp_user" setup_postgresql_db

# 调用后，以下变量可用：
# $PG_DB_NAME - 数据库名称
# $PG_DB_USER - 数据库用户
# $PG_DB_PASS - 生成的密码（保存到 ~/[appname].creds）
```

### `setup_mongodb`

安装 MongoDB 服务器。

```bash
setup_mongodb
```

### `setup_clickhouse`

安装 ClickHouse 分析数据库。

```bash
setup_clickhouse
```

---

## 高级仓库管理

### `setup_deb822_repo`

添加外部仓库的现代标准（Debian 12+）。自动处理 GPG 密钥和源。

```bash
setup_deb822_repo \
  "nodejs" \
  "https://deb.nodesource.com/gpgkey/nodesource.gpg.key" \
  "https://deb.nodesource.com/node_22.x" \
  "bookworm" \
  "main"
```

### `prepare_repository_setup`

高级辅助函数，在添加新仓库前执行三个关键任务：
1. 清理与提供的名称匹配的旧仓库文件。
2. 从所有标准位置删除旧的 GPG 密钥环。
3. 确保 APT 处于工作状态（修复锁定，运行更新）。

```bash
# 在设置前清理旧的 mysql/mariadb 残留
prepare_repository_setup "mariadb" "mysql"
```

### `cleanup_tool_keyrings`

从 `/usr/share/keyrings/`、`/etc/apt/keyrings/` 和 `/etc/apt/trusted.gpg.d/` 强制删除特定工具的 GPG 密钥。

```bash
cleanup_tool_keyrings "docker" "kubernetes"
```

---

## GitHub Release 辅助函数

> **注意**：`fetch_and_deploy_gh_release` 是下载 GitHub releases 的**首选方法**。它自动处理版本跟踪。仅在需要单独获取版本号时使用 `get_latest_github_release`。

### `fetch_and_deploy_gh_release`

下载和解压 GitHub releases 的**主要方法**。自动处理版本跟踪。

```bash
# 基本用法 - 下载 tarball 到 /opt/appname
fetch_and_deploy_gh_release "appname" "owner/repo"

# 使用显式参数
fetch_and_deploy_gh_release "appname" "owner/repo" "tarball" "latest" "/opt/appname"

# 使用特定资源模式的预构建版本
fetch_and_deploy_gh_release "koel" "koel/koel" "prebuild" "latest" "/opt/koel" "koel-*.tar.gz"

# 全新安装（先删除旧目录）- 在 update_script 中使用
CLEAN_INSTALL=1 fetch_and_deploy_gh_release "appname" "owner/repo" "tarball" "latest" "/opt/appname"
```

**参数：**
| 参数 | 默认值 | 说明 |
| --------------- | ------------- | ----------------------------------------------------------------- |
| `name` | 必需 | 应用名称（用于版本跟踪） |
| `repo` | 必需 | GitHub 仓库（`owner/repo`） |
| `type` | `tarball` | Release 类型：`tarball`、`zipball`、`prebuild`、`binary` |
| `version` | `latest` | 版本标签或 `latest` |
| `dest` | `/opt/[name]` | 目标目录 |
| `asset_pattern` | `""` | 对于 `prebuild`：匹配资源的 glob 模式（如 `app-*.tar.gz`） |

**环境变量：**
| 变量 | 说明 |
| ----------------- | ------------------------------------------------------------ |
| `CLEAN_INSTALL=1` | 解压前删除目标目录（用于更新） |

### `check_for_gh_release`

检查是否有新版本可用。如果需要更新返回 0，如果已是最新返回 1。**在 `update_script()` 函数中使用。**

```bash
# 在 ct/appname.sh 的 update_script() 函数中
if check_for_gh_release "appname" "owner/repo"; then
  msg_info "正在更新..."
  # 停止服务、备份、更新、恢复、启动
  CLEAN_INSTALL=1 fetch_and_deploy_gh_release "appname" "owner/repo"
  msg_ok "更新成功！"
fi
```

### `get_latest_github_release`

从 GitHub 仓库获取最新 release 版本。**仅在需要单独获取版本号时使用**（例如，用于手动下载或显示）。

```bash
RELEASE=$(get_latest_github_release "owner/repo")
echo "最新版本：$RELEASE"
```

---

## 工具与实用程序

### `setup_meilisearch`

安装 Meilisearch，一个超快的搜索引擎。

```bash
setup_meilisearch

# 在脚本中使用
$STD php artisan scout:sync-index-settings
```

### `setup_yq`

安装 yq YAML 处理器。

```bash
setup_yq

# 在脚本中使用
yq '.server.port = 8080' -i config.yaml
```

### `setup_ffmpeg`

安装带常用编解码器的 FFmpeg。

```bash
setup_ffmpeg
```

### `setup_hwaccel`

设置 GPU 硬件加速（Intel/AMD/NVIDIA）。

```bash
# 仅在检测到 GPU 直通时运行（/dev/dri、/dev/nvidia0、/dev/kfd）
setup_hwaccel
```

### `setup_imagemagick`

从源代码安装 ImageMagick 7。

```bash
setup_imagemagick
```

### `setup_docker`

安装 Docker Engine。

```bash
setup_docker
```

### `setup_adminer`

安装 Adminer 用于数据库管理。

```bash
setup_mariadb
setup_adminer

# 访问地址 http://IP/adminer
```

---

## SSL/TLS

### `create_self_signed_cert`

创建自签名 SSL 证书。

```bash
create_self_signed_cert

# 在以下位置创建文件：
# /etc/ssl/[appname]/[appname].key
# /etc/ssl/[appname]/[appname].crt
```

---

## 实用函数

### `verify_tool_version`

验证已安装的主版本是否与预期版本匹配。在升级或故障排除时很有用。

```bash
# 验证 Node.js 是否为版本 22
verify_tool_version "nodejs" "22" "$(node -v | grep -oP '^v\K[0-9]+')"
```

### `get_lxc_ip`

设置 `$LOCAL_IP` 变量为容器的 IP 地址。

```bash
get_lxc_ip
echo "容器 IP：$LOCAL_IP"

# 在配置文件中使用
sed -i "s/localhost/$LOCAL_IP/g" /opt/myapp/config.yaml
```

### `ensure_dependencies`

确保包已安装（如果缺失则安装）。

```bash
ensure_dependencies "jq" "unzip" "curl"
```

### `msg_info` / `msg_ok` / `msg_error` / `msg_warn`

显示格式化消息。

```bash
msg_info "正在安装应用..."
# ... 执行工作 ...
msg_ok "安装完成"

msg_warn "可选功能不可用"
msg_error "安装失败"
```

---

## 包管理

### `cleanup_lxc`

最终清理函数 - 在安装脚本末尾调用。

```bash
# 在安装脚本末尾
motd_ssh
customize
cleanup_lxc  # 处理 autoremove、autoclean、缓存清理
```

### `install_packages_with_retry`

安装包，失败时自动重试。

```bash
install_packages_with_retry "package1" "package2" "package3"
```

### `prepare_repository_setup`

准备系统以添加新仓库（清理旧仓库、密钥环）。

```bash
prepare_repository_setup "mariadb" "mysql"
```

---

## 完整示例

### 示例 1：使用 PostgreSQL 的 Node.js 应用（安装脚本）

```bash
#!/usr/bin/env bash

# Copyright (c) 2021-2026 community-scripts ORG
# Author: YourUsername
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/example/myapp

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y nginx
msg_ok "已安装依赖"

# 首先设置运行时和数据库
NODE_VERSION="22" setup_nodejs
PG_VERSION="16" setup_postgresql
PG_DB_NAME="myapp" PG_DB_USER="myapp" setup_postgresql_db
get_lxc_ip

# 使用 fetch_and_deploy 下载应用（处理版本跟踪）
fetch_and_deploy_gh_release "myapp" "example/myapp" "tarball" "latest" "/opt/myapp"

msg_info "正在设置 MyApp"
cd /opt/myapp
$STD npm ci --production
msg_ok "已设置 MyApp"

msg_info "正在配置 MyApp"
cat <<EOF >/opt/myapp/.env
DATABASE_URL=postgresql://${PG_DB_USER}:${PG_DB_PASS}@localhost/${PG_DB_NAME}
HOST=${LOCAL_IP}
PORT=3000
EOF
msg_ok "已配置 MyApp"

msg_info "正在创建服务"
cat <<EOF >/etc/systemd/system/myapp.service
[Unit]
Description=MyApp
After=network.target postgresql.service

[Service]
Type=simple
WorkingDirectory=/opt/myapp
ExecStart=/usr/bin/node /opt/myapp/server.js
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl enable -q --now myapp
msg_ok "已创建服务"

motd_ssh
customize
cleanup_lxc
```

### 示例 2：匹配的容器脚本（ct 脚本）

```bash
#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2026 community-scripts ORG
# Author: YourUsername
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/example/myapp

APP="MyApp"
var_tags="${var_tags:-webapp}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-6}"
var_os="${var_os:-debian}"
var_version="${var_version:-12}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  if [[ ! -d /opt/myapp ]]; then
    msg_error "未找到 ${APP} 安装！"
    exit
  fi

  # check_for_gh_release 在有更新可用时返回 true
  if check_for_gh_release "myapp" "example/myapp"; then
    msg_info "正在停止服务"
    systemctl stop myapp
    msg_ok "已停止服务"

    msg_info "正在创建备份"
    cp /opt/myapp/.env /tmp/myapp_env.bak
    msg_ok "已创建备份"

    # CLEAN_INSTALL=1 在解压前删除旧目录
    CLEAN_INSTALL=1 fetch_and_deploy_gh_release "myapp" "example/myapp" "tarball" "latest" "/opt/myapp"

    msg_info "正在恢复配置并重建"
    cp /tmp/myapp_env.bak /opt/myapp/.env
    rm /tmp/myapp_env.bak
    cd /opt/myapp
    $STD npm ci --production
    msg_ok "已恢复配置并重建"

    msg_info "正在启动服务"
    systemctl start myapp
    msg_ok "已启动服务"

    msg_ok "更新成功！"
  fi
  exit
}

start
build_container
description

msg_ok "成功完成！\n"
echo -e "${CREATING}${GN}${APP} 设置已成功初始化！${CL}"
echo -e "${INFO}${YW} 使用以下 URL 访问：${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:3000${CL}"
```

### 示例 3：使用 MariaDB 的 PHP 应用（安装脚本）

```bash
#!/usr/bin/env bash

source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

msg_info "正在安装依赖"
$STD apt install -y nginx
msg_ok "已安装依赖"

# 带 FPM 和常用模块的 PHP
PHP_VERSION="8.4" PHP_FPM="YES" PHP_MODULE="bcmath,curl,gd,intl,mbstring,mysql,xml,zip" setup_php
setup_composer
setup_mariadb
MARIADB_DB_NAME="myapp" MARIADB_DB_USER="myapp" setup_mariadb_db
get_lxc_ip

# 下载预构建版本（使用资源模式）
fetch_and_deploy_gh_release "myapp" "example/myapp" "prebuild" "latest" "/opt/myapp" "myapp-*.tar.gz"

msg_info "正在配置 MyApp"
cd /opt/myapp
cp .env.example .env
sed -i "s|APP_URL=.*|APP_URL=http://${LOCAL_IP}|" .env
sed -i "s|DB_DATABASE=.*|DB_DATABASE=${MARIADB_DB_NAME}|" .env
sed -i "s|DB_USERNAME=.*|DB_USERNAME=${MARIADB_DB_USER}|" .env
sed -i "s|DB_PASSWORD=.*|DB_PASSWORD=${MARIADB_DB_PASS}|" .env
$STD composer install --no-dev --no-interaction
$STD php artisan key:generate --force
$STD php artisan migrate --force
chown -R www-data:www-data /opt/myapp
msg_ok "已配置 MyApp"

# ... nginx 配置、服务创建 ...

motd_ssh
customize
cleanup_lxc
```
