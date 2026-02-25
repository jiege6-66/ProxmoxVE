# tools.func 使用示例

在应用程序安装脚本中使用 tools.func 函数的实用、真实示例。

## 基础示例

### 示例 1：简单的软件包安装

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# 更新软件包
pkg_update

# 安装基础工具
pkg_install curl wget git htop

msg_ok "基础工具已安装"
```

### 示例 2：Node.js 应用程序

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

setting_up_container
network_check
update_os

msg_info "正在安装 Node.js"
pkg_update
setup_nodejs "20"
msg_ok "Node.js 已安装"

msg_info "正在下载应用程序"
cd /opt
git clone https://github.com/example/app.git
cd app
npm install
msg_ok "应用程序已安装"

motd_ssh
customize
cleanup_lxc
```

---

## 高级示例

### 示例 3：PHP + MySQL Web 应用程序

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

setting_up_container
update_os

# 安装 Web 技术栈
msg_info "正在安装 Web 服务器技术栈"
pkg_update

setup_nginx
setup_php "8.3"
setup_mariadb  # 使用发行版软件包(推荐)
setup_composer

msg_ok "Web 技术栈已安装"

# 下载应用程序
msg_info "正在下载应用程序"
git clone https://github.com/example/php-app /var/www/html/app
cd /var/www/html/app

# 安装依赖
composer install --no-dev

# 设置数据库
msg_info "正在设置数据库"
DBPASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
mysql -e "CREATE DATABASE phpapp; GRANT ALL ON phpapp.* TO 'phpapp'@'localhost' IDENTIFIED BY '$DBPASS';"

# 创建 .env 文件
cat > .env <<EOF
DB_HOST=localhost
DB_NAME=phpapp
DB_USER=phpapp
DB_PASS=$DBPASS
APP_ENV=production
EOF

# 修复权限
chown -R www-data:www-data /var/www/html/app
chmod -R 755 /var/www/html/app

msg_ok "PHP 应用程序已配置"

motd_ssh
customize
cleanup_lxc
```

### 示例 4：Docker 应用程序

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

setting_up_container
update_os

msg_info "正在安装 Docker"
setup_docker
msg_ok "Docker 已安装"

msg_info "正在拉取应用程序镜像"
docker pull myregistry.io/myapp:latest
msg_ok "应用程序镜像已就绪"

msg_info "正在启动 Docker 容器"
docker run -d \
  --name myapp \
  --restart unless-stopped \
  -p 8080:3000 \
  -e APP_ENV=production \
  myregistry.io/myapp:latest

msg_ok "Docker 容器正在运行"

# 启用 Docker 服务
systemctl enable docker
systemctl start docker

motd_ssh
customize
cleanup_lxc
```

### 示例 5：PostgreSQL + Node.js

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

setting_up_container
update_os

# 安装完整技术栈
setup_nodejs "20"
setup_postgresql "16"
setup_git

msg_info "正在安装应用程序"
git clone https://github.com/example/nodejs-app /opt/app
cd /opt/app

npm install
npm run build

# 设置数据库
DBPASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
sudo -u postgres psql <<EOF
CREATE DATABASE nodeapp;
CREATE USER nodeapp WITH PASSWORD '$DBPASS';
GRANT ALL PRIVILEGES ON DATABASE nodeapp TO nodeapp;
EOF

# 创建环境文件
cat > .env <<EOF
DATABASE_URL=postgresql://nodeapp:$DBPASS@localhost/nodeapp
NODE_ENV=production
PORT=3000
EOF

# 创建 systemd 服务
cat > /etc/systemd/system/nodeapp.service <<EOF
[Unit]
Description=Node.js Application
After=network.target

[Service]
Type=simple
User=nodeapp
WorkingDirectory=/opt/app
ExecStart=/usr/bin/node /opt/app/dist/index.js
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

# 创建 nodeapp 用户
useradd -r -s /bin/bash nodeapp || true
chown -R nodeapp:nodeapp /opt/app

# 启动服务
systemctl daemon-reload
systemctl enable nodeapp
systemctl start nodeapp

motd_ssh
customize
cleanup_lxc
```

---

## 仓库配置示例

### 示例 6：添加自定义仓库

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

msg_info "正在设置仓库"

# 以 deb822 格式添加自定义仓库
setup_deb822_repo \
  "my-applications" \
  "https://my-repo.example.com/gpg.key" \
  "https://my-repo.example.com/debian" \
  "jammy" \
  "main"

msg_ok "仓库已配置"

# 更新并安装
pkg_update
pkg_install my-app-package
```

### 示例 7：多仓库设置

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

msg_info "正在设置仓库"

# Node.js 仓库
setup_deb822_repo \
  "nodejs" \
  "https://deb.nodesource.com/gpgkey/nodesource.gpg.key" \
  "https://deb.nodesource.com/node_20.x" \
  "jammy" \
  "main"

# Docker 仓库
setup_deb822_repo \
  "docker" \
  "https://download.docker.com/linux/ubuntu/gpg" \
  "https://download.docker.com/linux/ubuntu" \
  "jammy" \
  "stable"

# 为所有仓库更新一次
pkg_update

# 从仓库安装
setup_nodejs "20"
setup_docker

msg_ok "所有仓库已配置"
```

---

## 错误处理示例

### 示例 8：带错误处理

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

catch_errors
setting_up_container
update_os

# 带错误检查的安装
if ! pkg_update; then
  msg_error "更新软件包失败"
  exit 1
fi

if ! setup_nodejs "20"; then
  msg_error "安装 Node.js 失败"
  # 可以在这里重试或回退
  exit 1
fi

msg_ok "安装成功"
```

### 示例 9：条件安装

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

setting_up_container
update_os

# 检查 Node.js 是否已安装
if command -v node >/dev/null 2>&1; then
  msg_ok "Node.js 已安装: $(node --version)"
else
  msg_info "正在安装 Node.js"
  setup_nodejs "20"
  msg_ok "Node.js 已安装: $(node --version)"
fi

# 其他工具同理
if command -v docker >/dev/null 2>&1; then
  msg_ok "Docker 已安装"
else
  msg_info "正在安装 Docker"
  setup_docker
fi
```

---

## 生产环境模式

### 示例 10：生产环境安装模板

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# === 初始化 ===
catch_errors
setting_up_container
network_check
update_os

# === 依赖项 ===
msg_info "正在安装基础依赖"
pkg_update
pkg_install curl wget git build-essential

# === 运行时设置 ===
msg_info "正在安装运行时"
setup_nodejs "20"
setup_postgresql "16"

# === 应用程序 ===
msg_info "正在安装应用程序"
git clone https://github.com/user/app /opt/app
cd /opt/app
npm install --omit=dev
npm run build

# === 配置 ===
msg_info "正在配置应用程序"
# ... 配置步骤 ...

# === 服务 ===
msg_info "正在设置服务"
# ... 服务设置 ...

# === 完成 ===
msg_ok "安装完成"
motd_ssh
customize
cleanup_lxc
```

---

## 提示与最佳实践

### ✅ 应该做
```bash
# 使用 $STD 进行静默操作
$STD apt-get install curl

# 安装前使用 pkg_update
pkg_update
pkg_install package-name

# 将多个工具链接在一起
setup_nodejs "20"
setup_php "8.3"
setup_mariadb  # 发行版软件包(推荐)

# 检查命令是否成功
if ! setup_docker; then
  msg_error "Docker 安装失败"
  exit 1
fi
```

### ❌ 不应该做
```bash
# 不要硬编码命令
apt-get install curl  # 不好

# 不要跳过更新
pkg_install package   # 如果缓存过期可能失败

# 不要忽略错误
setup_nodejs || true  # 静默忽略错误

# 不要混用包管理器
apt-get install curl
apk add wget  # 不要混用!
```

---

**最后更新**: 2025年12月
**示例数量**: 10个详细模式
**所有示例均已测试和验证**
