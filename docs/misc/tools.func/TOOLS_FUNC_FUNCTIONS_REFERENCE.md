# tools.func 函数参考

tools.func 中所有函数的完整字母顺序参考，包含参数、用法和示例。

## 函数索引

### 包管理
- `pkg_install()` - 安全安装包并支持重试
- `pkg_update()` - 更新包列表并支持重试
- `pkg_remove()` - 干净地移除包

### 仓库管理
- `setup_deb822_repo()` - 以现代 deb822 格式添加仓库
- `cleanup_repo_metadata()` - 清理 GPG 密钥和旧仓库
- `check_repository()` - 验证仓库可访问性

### 工具安装函数（30+）

**编程语言**：
- `setup_nodejs(VERSION)` - 安装 Node.js 和 npm
- `setup_php(VERSION)` - 安装 PHP-FPM 和 CLI
- `setup_python(VERSION)` - 安装 Python 3 和 pip
- `setup_uv()` - 安装 Python uv（现代且快速）
- `setup_ruby(VERSION)` - 安装 Ruby 和 gem
- `setup_golang(VERSION)` - 安装 Go 编程语言
- `setup_java(VERSION)` - 安装 OpenJDK (Adoptium)

**数据库**：
- `setup_mariadb()` - 安装 MariaDB 服务器
- `setup_mariadb_db()` - 在 MariaDB 中创建用户/数据库
- `setup_postgresql(VERSION)` - 安装 PostgreSQL
- `setup_postgresql_db()` - 在 PostgreSQL 中创建用户/数据库
- `setup_mongodb(VERSION)` - 安装 MongoDB
- `setup_redis(VERSION)` - 安装 Redis 缓存
- `setup_meilisearch()` - 安装 Meilisearch 引擎

**Web 服务器**：
- `setup_nginx()` - 安装 Nginx
- `setup_apache()` - 安装 Apache HTTP Server
- `setup_caddy()` - 安装 Caddy
- `setup_traefik()` - 安装 Traefik 代理

**容器**：
- `setup_docker()` - 安装 Docker
- `setup_podman()` - 安装 Podman

**开发工具**：
- `setup_git()` - 安装 Git
- `setup_docker_compose()` - 安装 Docker Compose
- `setup_composer()` - 安装 PHP Composer
- `setup_build_tools()` - 安装 build-essential
- `setup_yq()` - 安装 mikefarah/yq 处理器

**监控**：
- `setup_grafana()` - 安装 Grafana
- `setup_prometheus()` - 安装 Prometheus
- `setup_telegraf()` - 安装 Telegraf

**系统**：
- `setup_wireguard()` - 安装 WireGuard VPN
- `setup_netdata()` - 安装 Netdata 监控
- `setup_tailscale()` - 安装 Tailscale
- （更多...）

---

## 核心函数

### install_packages_with_retry()

安全安装一个或多个包，具有自动重试逻辑（3 次尝试）、APT 刷新和锁处理。

**签名**：
```bash
install_packages_with_retry PACKAGE1 [PACKAGE2 ...]
```

**参数**：
- `PACKAGE1, PACKAGE2, ...` - 要安装的包名

**返回值**：
- `0` - 所有包安装成功
- `1` - 所有重试后安装失败

**特性**：
- 自动设置 `DEBIAN_FRONTEND=noninteractive`
- 使用 `dpkg --configure -a` 处理 DPKG 锁错误
- 在临时网络或 APT 故障时重试

**示例**：
```bash
install_packages_with_retry curl wget git
```

---

### upgrade_packages_with_retry()

使用与安装助手相同的强大重试逻辑升级已安装的包。

**签名**：
```bash
upgrade_packages_with_retry
```

**返回值**：
- `0` - 升级成功
- `1` - 升级失败

---

### fetch_and_deploy_gh_release()

从 GitHub Releases 下载和安装软件的主要工具。支持二进制文件、压缩包和 Debian 包。

**签名**：
```bash
fetch_and_deploy_gh_release APPREPO TYPE [VERSION] [DEST] [ASSET_PATTERN]
```

**环境变量**：
- `APPREPO`：GitHub 仓库（例如 `owner/repo`）
- `TYPE`：资源类型（`binary`、`tarball`、`prebuild`、`singlefile`）
- `VERSION`：特定标签或 `latest`（默认：`latest`）
- `DEST`：目标目录（默认：`/opt/$APP`）
- `ASSET_PATTERN`：用于匹配发布资源的正则表达式或字符串模式（`prebuild` 和 `singlefile` 必需）

**支持的操作模式**：
- `tarball`：下载并解压源代码压缩包。
- `binary`：检测主机架构并使用 `apt` 或 `dpkg` 安装 `.deb` 包。
- `prebuild`：下载并解压预构建的二进制归档（支持 `.tar.gz`、`.zip`、`.tgz`、`.txz`）。
- `singlefile`：下载单个二进制文件到目标位置。

**环境变量**：
- `CLEAN_INSTALL=1`：在解压前删除目标目录的所有内容。
- `DPKG_FORCE_CONFOLD=1`：强制 `dpkg` 在包更新期间保留旧配置文件。
- `SYSTEMD_OFFLINE=1`：自动用于 `.deb` 安装，以防止在非特权容器中出现 systemd-tmpfiles 故障。

**示例**：
```bash
fetch_and_deploy_gh_release "muesli/duf" "binary" "latest" "/opt/duf" "duf_.*_linux_amd64.tar.gz"
```

---

### check_for_gh_release()

检查 GitHub 上是否有比已安装版本更新的版本。

**签名**：
```bash
check_for_gh_release APP REPO
```

**示例**：
```bash
if check_for_gh_release "nodejs" "nodesource/distributions"; then
  # 更新逻辑
fi
```

---

### prepare_repository_setup()

通过清理旧文件、密钥环并确保 APT 系统处于工作状态来执行安全的仓库准备。

**签名**：
```bash
prepare_repository_setup REPO_NAME [REPO_NAME2 ...]
```

**示例**：
```bash
prepare_repository_setup "mariadb" "mysql"
```

---

### verify_tool_version()

验证已安装的主版本是否与预期版本匹配。

**签名**：
```bash
verify_tool_version NAME EXPECTED INSTALLED
```

**示例**：
```bash
verify_tool_version "nodejs" "22" "$(node -v | grep -oP '^v\K[0-9]+')"
```

---

### setup_deb822_repo()

以现代 deb822 格式添加仓库。

**签名**：
```bash
setup_deb822_repo NAME GPG_URL REPO_URL SUITE COMPONENT [ARCHITECTURES] [ENABLED]
```

**参数**：
- `NAME` - 仓库名称（例如 "nodejs"）
- `GPG_URL` - GPG 密钥的 URL（例如 https://example.com/key.gpg）
- `REPO_URL` - 主仓库 URL（例如 https://example.com/repo）
- `SUITE` - 仓库套件（例如 "jammy"、"bookworm"）
- `COMPONENT` - 仓库组件（例如 "main"、"testing"）
- `ARCHITECTURES` - 可选，逗号分隔的架构列表（例如 "amd64,arm64"）
- `ENABLED` - 可选，"true" 或 "false"（默认："true"）

**返回值**：
- `0` - 仓库添加成功
- `1` - 仓库设置失败

**示例**：
```bash
setup_deb822_repo \
  "nodejs" \
  "https://deb.nodesource.com/gpgkey/nodesource.gpg.key" \
  "https://deb.nodesource.com/node_20.x" \  
  "jammy" \
  "main"
```

---

### cleanup_repo_metadata()

清理 GPG 密钥和旧仓库配置。

**签名**：
```bash
cleanup_repo_metadata
```

**参数**：无

**返回值**：
- `0` - 清理完成

**示例**：
```bash
cleanup_repo_metadata
```

---

## 工具安装函数

### setup_nodejs()

从官方仓库安装 Node.js 和 npm。自动处理旧版本清理（nvm）。

**签名**：
```bash
setup_nodejs
```

**环境变量**：
- `NODE_VERSION`：要安装的主版本（例如 "20"、"22"、"24"）。默认："24"。
- `NODE_MODULE`：可选，在设置期间全局安装的 npm 包（例如 "pnpm"、"yarn"）。

**示例**：
```bash
NODE_VERSION="22" NODE_MODULE="pnpm" setup_nodejs
```

---

### setup_php()

安装 PHP，支持可配置的扩展和 FPM/Apache 集成。

**签名**：
```bash
setup_php
```

**环境变量**：
- `PHP_VERSION`：要安装的版本（例如 "8.3"、"8.4"）。默认："8.4"。
- `PHP_MODULE`：逗号分隔的附加扩展列表。
- `PHP_FPM`：设置为 "YES" 以安装 php-fpm。
- `PHP_APACHE`：设置为 "YES" 以安装 libapache2-mod-php。

**示例**：
```bash
PHP_VERSION="8.3" PHP_FPM="YES" PHP_MODULE="mysql,xml,zip" setup_php
```

---

### setup_mariadb_db()

创建新的 MariaDB 数据库和具有所有权限的专用用户。如果未提供密码，则自动生成密码并保存到凭据文件。

**环境变量**：
- `MARIADB_DB_NAME`：数据库名称（必需）
- `MARIADB_DB_USER`：数据库用户名（必需）
- `MARIADB_DB_PASS`：用户密码（可选，如果省略则自动生成）

**示例**：
```bash
MARIADB_DB_NAME="myapp" MARIADB_DB_USER="myapp_user" setup_mariadb_db
```

---

### setup_postgresql_db()

创建新的 PostgreSQL 数据库和具有所有权限的专用用户/角色。如果未提供密码，则自动生成密码并保存到凭据文件。

**环境变量**：
- `PG_DB_NAME`：数据库名称（必需）
- `PG_DB_USER`：数据库用户名（必需）
- `PG_DB_PASS`：用户密码（可选，如果省略则自动生成）

---

### setup_java()

安装 Temurin JDK。

**签名**：
```bash
JAVA_VERSION="21" setup_java
```

**参数**：
- `JAVA_VERSION` - JDK 版本（例如 "17"、"21"）（默认："21"）

**示例**：
```bash
JAVA_VERSION="17" setup_java
```

---

### setup_uv()

安装 `uv`（现代 Python 包管理器）。

**签名**：
```bash
PYTHON_VERSION="3.13" setup_uv
```

**参数**：
- `PYTHON_VERSION` - 可选，通过 uv 预安装的 Python 版本（例如 "3.12"、"3.13"）

**示例**：
```bash
PYTHON_VERSION="3.13" setup_uv
```

---

### setup_go()

安装 Go 编程语言。

**签名**：
```bash
GO_VERSION="1.23" setup_go
```

**参数**：
- `GO_VERSION` - 要安装的 Go 版本（默认："1.23"）

**示例**：
```bash
GO_VERSION="1.24" setup_go
```

---

### setup_yq()

安装 `yq`（YAML 处理器）。

**签名**：
```bash
setup_yq
```

**示例**：
```bash
setup_yq
```

---

### setup_composer()

安装 PHP Composer。

**签名**：
```bash
setup_composer
```

**示例**：
```bash
setup_composer
```

---

### setup_meilisearch()

安装和配置 Meilisearch 搜索引擎。

**环境变量**：
- `MEILISEARCH_BIND`：绑定的地址和端口（默认："127.0.0.1:7700"）
- `MEILISEARCH_ENV`：环境模式（默认："production"）

---

### setup_yq()

安装 `mikefarah/yq` YAML 处理器。删除现有的不兼容版本。

**示例**：
```bash
setup_yq
yq eval '.app.version = "1.0.0"' -i config.yaml
```

---

### setup_composer()

安装或更新 PHP Composer 包管理器。自动处理 `COMPOSER_ALLOW_SUPERUSER` 并在已安装时执行自我更新。

**示例**：
```bash
setup_php
setup_composer
$STD composer install --no-dev
```

---

### setup_build_tools()

安装 `build-essential` 包套件以编译软件。

---

### setup_uv()

安装现代 Python 包管理器 `uv`。pip/venv 的极快替代品。

**环境变量**：
- `PYTHON_VERSION`：确保安装的主.次版本。

**示例**：
```bash
PYTHON_VERSION="3.12" setup_uv
uv sync --locked
```

---

### setup_java()

通过 Adoptium 仓库安装 OpenJDK。

**环境变量**：
- `JAVA_VERSION`：要安装的主版本（例如 "17"、"21"）。默认："21"。

**示例**：
```bash
JAVA_VERSION="21" setup_java
```

---
```bash
setup_nodejs VERSION
```

**参数**：
- `VERSION` - Node.js 版本（例如 "20"、"22"、"lts"）

**返回值**：
- `0` - 安装成功
- `1` - 安装失败

**创建**：
- `/opt/nodejs_version.txt` - 版本文件

**示例**：
```bash
setup_nodejs "20"
```

---

### setup_php(VERSION)

安装 PHP-FPM、CLI 和常用扩展。

**签名**：
```bash
setup_php VERSION
```

**参数**：
- `VERSION` - PHP 版本（例如 "8.2"、"8.3"）

**返回值**：
- `0` - 安装成功
- `1` - 安装失败

**创建**：
- `/opt/php_version.txt` - 版本文件

**示例**：
```bash
setup_php "8.3"
```

---

### setup_mariadb()

安装 MariaDB 服务器和客户端工具。

**签名**：
```bash
setup_mariadb                         # 使用发行版包（推荐）
MARIADB_VERSION="11.4" setup_mariadb  # 使用官方 MariaDB 仓库
```

**变量**：
- `MARIADB_VERSION` - （可选）特定 MariaDB 版本
  - 未设置或 `"latest"`：使用发行版包（最可靠，避免镜像问题）
  - 特定版本（例如 `"11.4"`、`"12.2"`）：使用官方 MariaDB 仓库

**返回值**：
- `0` - 安装成功
- `1` - 安装失败

**创建**：
- `/opt/mariadb_version.txt` - 版本文件

**示例**：
```bash
# 推荐：使用发行版包（稳定，无镜像问题）
setup_mariadb

# 从官方仓库安装特定版本
MARIADB_VERSION="11.4" setup_mariadb
```

---

### setup_postgresql(VERSION)

安装 PostgreSQL 服务器和客户端工具。

**签名**：
```bash
setup_postgresql VERSION
```

**参数**：
- `VERSION` - PostgreSQL 版本（例如 "14"、"15"、"16"）

**返回值**：
- `0` - 安装成功
- `1` - 安装失败

**创建**：
- `/opt/postgresql_version.txt` - 版本文件

**示例**：
```bash
setup_postgresql "16"
```

---

### setup_docker()

安装 Docker 和 Docker CLI。

**签名**：
```bash
setup_docker
```

**参数**：无

**返回值**：
- `0` - 安装成功
- `1` - 安装失败

**创建**：
- `/opt/docker_version.txt` - 版本文件

**示例**：
```bash
setup_docker
```

---

### setup_composer()

安装 PHP Composer（依赖管理器）。

**签名**：
```bash
setup_composer
```

**参数**：无

**返回值**：
- `0` - 安装成功
- `1` - 安装失败

**创建**：
- `/usr/local/bin/composer` - Composer 可执行文件

**示例**：
```bash
setup_composer
```

---

### setup_build_tools()

安装 build-essential 和开发工具（gcc、make 等）。

**签名**：
```bash
setup_build_tools
```

**参数**：无

**返回值**：
- `0` - 安装成功
- `1` - 安装失败

**示例**：
```bash
setup_build_tools
```

---

## 系统配置

### setting_up_container()

显示设置消息并初始化容器环境。

**签名**：
```bash
setting_up_container
```

**示例**：
```bash
setting_up_container
# 输出：⏳ 正在设置容器...
```

---

### motd_ssh()

为容器配置 SSH 守护进程和 MOTD。

**签名**：
```bash
motd_ssh
```

**示例**：
```bash
motd_ssh
# 配置 SSH 并创建 MOTD
```

---

### customize()

应用容器自定义和最终设置。

**签名**：
```bash
customize
```

**示例**：
```bash
customize
```

---

### cleanup_lxc()

最终清理临时文件和日志。

**签名**：
```bash
cleanup_lxc
```

**示例**：
```bash
cleanup_lxc
# 删除临时文件，完成安装
```

---

## 使用模式

### 基本安装序列

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

pkg_update                    # 更新包列表
setup_nodejs "20"             # 安装 Node.js
setup_mariadb                 # 安装 MariaDB（发行版包）

# ... 应用程序安装 ...

motd_ssh                      # 设置 SSH/MOTD
customize                     # 应用自定义
cleanup_lxc                   # 最终清理
```

### 工具链安装

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# 安装完整的 Web 栈
pkg_update
setup_nginx
setup_php "8.3"
setup_mariadb  # 使用发行版包
setup_composer
```

### 使用仓库设置

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

pkg_update

# 添加 Node.js 仓库
setup_deb822_repo \
  "https://deb.nodesource.com/gpgkey/nodesource.gpg.key" \
  "nodejs" \
  "jammy" \
  "https://deb.nodesource.com/node_20.x" \
  "main"

pkg_update
setup_nodejs "20"
```

---

**最后更新**：2025 年 12 月
**函数总数**：30+
**维护者**：community-scripts 团队
