# 🛠️ **应用安装脚本 (install/AppName-install.sh)**

**编写容器内安装脚本的现代指南**

> **更新时间**: 2025年12月
> **上下文**: 集成 tools.func、error_handler.func 和 install.func
> **示例**: `/install/pihole-install.sh`、`/install/mealie-install.sh`

---

## 📋 目录

- [概述](#概述)
- [执行上下文](#执行上下文)
- [文件结构](#文件结构)
- [完整脚本模板](#完整脚本模板)
- [安装阶段](#安装阶段)
- [函数参考](#函数参考)
- [最佳实践](#最佳实践)
- [实际示例](#实际示例)
- [故障排除](#故障排除)
- [贡献检查清单](#贡献检查清单)

---

## 概述

### 目的

安装脚本（`install/AppName-install.sh`）**在 LXC 容器内运行**，负责：

1. 设置容器操作系统（更新、包）
2. 安装应用程序依赖项
3. 下载和配置应用程序
4. 设置服务和 systemd 单元
5. 创建用于更新的版本跟踪文件
6. 生成凭据/配置
7. 最终清理和验证

### 执行流程

```
ct/AppName.sh (Proxmox 主机)
       ↓
build_container()
       ↓
pct exec CTID bash -c "$(cat install/AppName-install.sh)"
       ↓
install/AppName-install.sh (容器内部)
       ↓
容器就绪，应用已安装
```

---

## 执行上下文

### 可用的环境变量

```bash
# 来自 Proxmox/容器
CTID                    # 容器 ID（100、101 等）
PCT_OSTYPE             # 操作系统类型（alpine、debian、ubuntu）
HOSTNAME               # 容器主机名

# 来自 build.func
FUNCTIONS_FILE_PATH    # Bash 函数库（core.func + tools.func）
VERBOSE                # 详细模式（yes/no）
STD                    # 标准重定向变量（静默/空）

# 来自 install.func
APP                    # 应用程序名称
NSAPP                  # 规范化的应用名称（小写，无空格）
METHOD                 # 安装方法（ct/install）
RANDOM_UUID            # 用于遥测的会话 UUID
```

---

## 文件结构

### 最小 install/AppName-install.sh 模板

```bash
#!/usr/bin/env bash                          # [1] Shebang

# [2] 版权/元数据
# Copyright (c) 2021-2026 community-scripts ORG
# Author: YourUsername
# License: MIT
# Source: https://example.com

# [3] 加载函数
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# [4] 安装步骤
msg_info "Installing Dependencies"
$STD apt-get install -y package1 package2
msg_ok "Installed Dependencies"

# [5] 最终设置
motd_ssh
customize
cleanup_lxc
```

---

## 完整脚本模板

### 阶段 1: 头部和初始化

```bash
#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: YourUsername
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/application/repo

# 加载所有可用函数（来自 core.func + tools.func）
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# 初始化环境
color                   # 设置 ANSI 颜色和图标
verb_ip6                # 配置 IPv6（如需要）
catch_errors           # 设置错误陷阱
setting_up_container   # 验证操作系统就绪
network_check          # 验证互联网连接
update_os              # 更新包（apk/apt）
```

### 阶段 2: 依赖项安装

```bash
msg_info "Installing Dependencies"
$STD apt-get install -y \
  curl \
  wget \
  git \
  nano \
  build-essential \
  libssl-dev \
  python3-dev
msg_ok "Installed Dependencies"
```

### 阶段 3: 工具设置（使用 tools.func）

```bash
# 设置特定工具版本
NODE_VERSION="22" setup_nodejs
PHP_VERSION="8.4" setup_php
PYTHON_VERSION="3.12" setup_uv
```

### 阶段 4: 应用程序下载和设置

```bash
# 从 GitHub 下载
RELEASE=$(curl -fsSL https://api.github.com/repos/user/repo/releases/latest | \
  grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}')

wget -q "https://github.com/user/repo/releases/download/v${RELEASE}/app-${RELEASE}.tar.gz"
cd /opt
tar -xzf app-${RELEASE}.tar.gz
rm -f app-${RELEASE}.tar.gz
```

### 阶段 5: 配置文件

```bash
# 使用 cat << EOF（多行）
cat <<'EOF' >/etc/nginx/sites-available/appname
server {
    listen 80;
    server_name _;
    root /opt/appname/public;
    index index.php index.html;
}
EOF

# 使用 sed 进行替换
sed -i -e "s|^DB_HOST=.*|DB_HOST=localhost|" \
       -e "s|^DB_USER=.*|DB_USER=appuser|" \
       /opt/appname/.env
```

### 阶段 6: 数据库设置（如需要）

```bash
msg_info "Setting up Database"

DB_NAME="appname_db"
DB_USER="appuser"
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)

# 对于 MySQL/MariaDB
mysql -u root <<EOF
CREATE DATABASE ${DB_NAME};
CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

msg_ok "Database setup complete"
```

### 阶段 7: 权限和所有权

```bash
msg_info "Setting permissions"

# Web 应用程序通常以 www-data 运行
chown -R www-data:www-data /opt/appname
chmod -R 755 /opt/appname
chmod -R 644 /opt/appname/*
chmod 755 /opt/appname/*/.*

msg_ok "Permissions set"
```

### 阶段 8: 服务配置

```bash
# 启用 systemd 服务
systemctl enable -q --now appname

# 或对于 OpenRC（Alpine）
rc-service appname start
rc-update add appname default

# 验证服务正在运行
if systemctl is-active --quiet appname; then
  msg_ok "Service running successfully"
else
  msg_error "Service failed to start"
  journalctl -u appname -n 20
  exit 1
fi
```

### 阶段 9: 版本跟踪

```bash
# 对于更新检测至关重要
echo "${RELEASE}" > /opt/${APP}_version.txt

# 或带有附加元数据
cat > /opt/${APP}_version.txt <<EOF
Version: ${RELEASE}
InstallDate: $(date)
InstallMethod: ${METHOD}
EOF
```

### 阶段 10: 最终设置和清理

```bash
# 显示 MOTD 并启用自动登录
motd_ssh

# 最终自定义
customize

# 清理包管理器缓存
msg_info "Cleaning up"
apt-get -y autoremove
apt-get -y autoclean
msg_ok "Cleaned"

# 或对于 Alpine
apk cache clean
rm -rf /var/cache/apk/*

# 系统清理
cleanup_lxc
```

---

## 安装阶段

### 阶段 1: 容器操作系统设置
- 网络接口启动并配置
- 验证互联网连接
- 更新包列表
- 所有操作系统包升级到最新版本

### 阶段 2: 基础依赖项
```bash
msg_info "Installing Base Dependencies"
$STD apt-get install -y \
  curl wget git nano build-essential
msg_ok "Installed Base Dependencies"
```

### 阶段 3: 工具安装
```bash
NODE_VERSION="22" setup_nodejs
PHP_VERSION="8.4" setup_php
```

### 阶段 4: 应用程序设置
```bash
RELEASE=$(curl -fsSL https://api.github.com/repos/user/repo/releases/latest | \
  grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}')
wget -q "https://github.com/user/repo/releases/download/v${RELEASE}/app.tar.gz"
```

### 阶段 5: 配置
应用程序特定的配置文件和环境设置

### 阶段 6: 服务注册
启用并验证 systemd 服务正在运行

---

## 函数参考

### 核心消息传递函数

#### `msg_info(message)`

显示带有旋转动画的信息消息

```bash
msg_info "Installing application"
# 输出: ⏳ Installing application（带旋转动画）
```

#### `msg_ok(message)`

显示带有复选标记的成功消息

```bash
msg_ok "Installation completed"
# 输出: ✔️ Installation completed
```

#### `msg_error(message)`

显示错误消息并退出

```bash
msg_error "Installation failed"
# 输出: ✖️ Installation failed
```

### 包管理

#### `$STD` 变量

控制输出详细程度

```bash
# 静默模式（遵守 VERBOSE 设置）
$STD apt-get install -y nginx
```

#### `update_os()`

更新操作系统包

```bash
update_os
# 运行: apt update && apt upgrade
```

### 工具安装函数

#### `setup_nodejs()`

安装 Node.js 及可选的全局模块

```bash
NODE_VERSION="22" setup_nodejs
NODE_VERSION="22" NODE_MODULE="yarn,@vue/cli" setup_nodejs
```

#### `setup_php()`

安装 PHP 及可选的扩展

```bash
PHP_VERSION="8.4" PHP_MODULE="bcmath,curl,gd,intl,redis" setup_php
```

#### 其他工具

```bash
setup_mariadb     # MariaDB 数据库
setup_mysql       # MySQL 数据库
setup_postgresql  # PostgreSQL
setup_docker      # Docker Engine
setup_composer    # PHP Composer
setup_python      # Python 3
setup_ruby        # Ruby
setup_rust        # Rust
```

### 清理函数

#### `cleanup_lxc()`

全面的容器清理

- 删除包管理器缓存
- 清理临时文件
- 清除语言包缓存
- 删除 systemd 日志

```bash
cleanup_lxc
# 输出: ⏳ Cleaning up
#       ✔️ Cleaned
```

---

## 最佳实践

### ✅ 应该做的:

1. **始终对命令使用 $STD**
```bash
# ✅ 好: 遵守 VERBOSE 设置
$STD apt-get install -y nginx
```

2. **安全地生成随机密码**
```bash
# ✅ 好: 仅字母数字
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
```

3. **检查命令成功**
```bash
# ✅ 好: 验证成功
if ! wget -q "https://example.com/file.tar.gz"; then
  msg_error "Download failed"
  exit 1
fi
```

4. **设置适当的权限**
```bash
# ✅ 好: 明确的权限
chown -R www-data:www-data /opt/appname
chmod -R 755 /opt/appname
```

5. **保存版本以进行更新检查**
```bash
# ✅ 好: 跟踪版本
echo "${RELEASE}" > /opt/${APP}_version.txt
```

6. **处理 Alpine vs Debian 差异**
```bash
# ✅ 好: 检测操作系统
if grep -qi 'alpine' /etc/os-release; then
  apk add package
else
  apt-get install -y package
fi
```

### ❌ 不应该做的:

1. **硬编码版本**
```bash
# ❌ 坏: 不会自动更新
wget https://example.com/app-1.2.3.tar.gz
```

2. **使用无密码的 Root**
```bash
# ❌ 坏: 安全风险
mysql -u root
```

3. **忘记错误处理**
```bash
# ❌ 坏: 静默失败
wget https://example.com/file
tar -xzf file
```

4. **留下临时文件**
```bash
# ✅ 始终清理
rm -rf /opt/app-${RELEASE}.tar.gz
```

---

## 实际示例

### 示例 1: Node.js 应用程序

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

color
catch_errors
setting_up_container
network_check
update_os

msg_info "Installing Node.js"
NODE_VERSION="22" setup_nodejs
msg_ok "Node.js installed"

msg_info "Installing Application"
cd /opt
RELEASE=$(curl -fsSL https://api.github.com/repos/user/repo/releases/latest | \
  grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}')
wget -q "https://github.com/user/repo/releases/download/v${RELEASE}/app.tar.gz"
tar -xzf app.tar.gz
echo "${RELEASE}" > /opt/app_version.txt
msg_ok "Application installed"

systemctl enable --now app
cleanup_lxc
```

### 示例 2: 带数据库的 PHP 应用程序

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

color
catch_errors
setting_up_container
network_check
update_os

PHP_VERSION="8.4" PHP_MODULE="bcmath,curl,pdo_mysql" setup_php
setup_mariadb  # 使用发行版包（推荐）
# 或对于特定版本: MARIADB_VERSION="11.4" setup_mariadb

# 数据库设置
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
mysql -u root <<EOF
CREATE DATABASE appdb;
CREATE USER 'appuser'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL ON appdb.* TO 'appuser'@'localhost';
FLUSH PRIVILEGES;
EOF

# 应用安装
cd /opt
wget -q https://github.com/user/repo/releases/latest/download/app.tar.gz
tar -xzf app.tar.gz

# 配置
cat > /opt/app/.env <<EOF
DB_HOST=localhost
DB_NAME=appdb
DB_USER=appuser
DB_PASS=${DB_PASS}
EOF

chown -R www-data:www-data /opt/app
systemctl enable --now php-fpm
cleanup_lxc
```

---

## 故障排除

### 安装挂起

**检查互联网连接**:
```bash
ping -c 1 8.8.8.8
```

**启用详细模式**:
```bash
# 在 ct/AppName.sh 中，运行前
VERBOSE="yes" bash install/AppName-install.sh
```

### 找不到包

**更新包列表**:
```bash
apt update
apt-cache search package_name
```

### 服务无法启动

**检查日志**:
```bash
journalctl -u appname -n 50
systemctl status appname
```

---

## 贡献检查清单

在提交 PR 之前：

### 结构
- [ ] Shebang 是 `#!/usr/bin/env bash`
- [ ] 从 `$FUNCTIONS_FILE_PATH` 加载函数
- [ ] 带有作者的版权标题
- [ ] 清晰的阶段注释

### 安装
- [ ] 早期调用 `setting_up_container`
- [ ] 下载前调用 `network_check`
- [ ] 包安装前调用 `update_os`
- [ ] 正确检查所有错误

### 函数
- [ ] 使用 `msg_info/msg_ok/msg_error` 显示状态
- [ ] 使用 `$STD` 静默命令输出
- [ ] 版本保存到 `/opt/${APP}_version.txt`
- [ ] 设置适当的权限

### 清理
- [ ] 调用 `motd_ssh` 进行最终设置
- [ ] 调用 `customize` 进行选项设置
- [ ] 最后调用 `cleanup_lxc`

### 测试
- [ ] 使用默认设置测试
- [ ] 使用高级（19步）模式测试
- [ ] 服务启动并正确运行

---

**最后更新**: 2025年12月
**兼容性**: ProxmoxVE with install.func v3+
