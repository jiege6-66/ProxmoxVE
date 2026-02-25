# 安装脚本 - 快速参考

> [!WARNING]
> **这是旧版文档。** 请参考 [templates_install/AppName-install.sh](AppName-install.sh) 中的**现代模板**以获取最佳实践。
>
> 当前模板使用：
>
> - `tools.func` 辅助函数（setup_nodejs、setup_uv、setup_postgresql_db 等）
> - 通过 build.func 自动安装依赖项
> - 标准化的环境变量模式

---

## 创建脚本之前

1. **复制现代模板：**

   ```bash
   cp templates_install/AppName-install.sh install/MyApp-install.sh
   # 编辑 install/MyApp-install.sh
   ```

2. **关键模式：**
   - CT 脚本引用 build.func 并调用安装脚本
   - 安装脚本使用引用的 FUNCTIONS_FILE_PATH（通过 build.func）
   - 两个脚本在容器中协同工作

3. **通过 GitHub 测试：**

   ```bash
   # 首先将更改推送到您的分支
   git push origin feature/my-awesome-app

   # 通过 curl 测试 CT 脚本（它将调用安装脚本）
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/ct/MyApp.sh)"
   # ⏱️ 推送后等待 10-30 秒 - GitHub 需要时间更新
   ```

---

## 模板结构

### 头部

```bash
#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/misc/install.func)
# （setup-fork.sh 在开发期间将此 URL 修改为指向您的分支）
```

### 依赖项（仅应用特定）

```bash
# 不要添加：ca-certificates、curl、gnupg、wget、git、jq
# 这些由 build.func 处理
msg_info "Installing dependencies"
$STD apt-get install -y app-specific-deps
msg_ok "Installed dependencies"
```

### 运行时设置

使用 tools.func 辅助函数而不是手动安装：

```bash
# ✅ 新方式（使用 tools.func）：
NODE_VERSION="20"
setup_nodejs
# 或
PYTHON_VERSION="3.12"
setup_uv
# 或
PG_DB_NAME="myapp_db"
PG_DB_USER="myapp"
setup_postgresql_db
```

### 服务配置

```bash
# 创建 .env 文件
msg_info "Configuring MyApp"
cat << EOF > /opt/myapp/.env
DEBUG=false
PORT=8080
DATABASE_URL=postgresql://...
EOF
msg_ok "Configuration complete"

# 创建 systemd 服务
msg_info "Creating systemd service"
cat << EOF > /etc/systemd/system/myapp.service
[Unit]
Description=MyApp
[Service]
ExecStart=/usr/bin/node /opt/myapp/app.js
[Install]
WantedBy=multi-user.target
EOF
msg_ok "Service created"
```

### 最终化

```bash
msg_info "Finalizing MyApp installation"
systemctl enable --now myapp
motd_ssh
customize
msg_ok "MyApp installation complete"
cleanup_lxc
```

---

## 关键模式

### 避免手动版本检查

❌ 旧方式（手动）：

```bash
RELEASE=$(curl -fsSL https://api.github.com/repos/app/repo/releases/latest | grep tag_name)
wget https://github.com/app/repo/releases/download/$RELEASE/app.tar.gz
```

✅ 新方式（通过 CT 脚本的 fetch_and_deploy_gh_release 使用 tools.func）：

```bash
# 在 CT 脚本中，而不是安装脚本：
fetch_and_deploy_gh_release "myapp" "app/repo" "app.tar.gz" "latest" "/opt/myapp"
```

### 数据库设置

```bash
# 使用 setup_postgresql_db、setup_mysql_db 等
PG_DB_NAME="myapp"
PG_DB_USER="myapp"
setup_postgresql_db
```

### Node.js 设置

```bash
NODE_VERSION="20"
setup_nodejs
npm install --no-save
```

---

## 最佳实践

1. **仅添加应用特定的依赖项**
   - 不要添加：ca-certificates、curl、gnupg、wget、git、jq
   - 这些由 build.func 处理

2. **使用 tools.func 辅助函数**
   - setup_nodejs、setup_python、setup_uv、setup_postgresql_db、setup_mysql_db 等

3. **不要在安装脚本中进行版本检查**
   - 版本检查在 CT 脚本的 update_script() 中进行
   - 安装脚本只安装最新版本

4. **结构：**
   - 依赖项
   - 运行时设置（tools.func）
   - 部署（从 CT 脚本获取）
   - 配置文件
   - Systemd 服务
   - 最终化

---

## 参考脚本

查看工作示例：

- [Trip](https://github.com/jiege6-66/ProxmoxVE/blob/main/install/trip-install.sh)
- [Thingsboard](https://github.com/jiege6-66/ProxmoxVE/blob/main/install/thingsboard-install.sh)
- [UniFi](https://github.com/jiege6-66/ProxmoxVE/blob/main/install/unifi-install.sh)

---

## 需要帮助？

- **[现代模板](AppName-install.sh)** - 从这里开始
- **[CT 模板](../templates_ct/AppName.sh)** - CT 脚本如何工作
- **[README.md](../README.md)** - 完整的贡献工作流
- **[AI.md](../AI.md)** - AI 生成的脚本指南

### 1.2 **注释**

- 为脚本元数据添加清晰的注释，包括作者、版权和许可证信息。
- 使用有意义的内联注释来解释复杂的命令或逻辑。

示例：

```bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: [YourUserName]
# License: MIT | https://github.com/jiege6-66/ProxmoxVE/raw/main/LICENSE
# Source: [SOURCE_URL]
```

> [!NOTE]:
>
> - 添加您的用户名
> - 更新/重做脚本时，添加"| Co-Author [YourUserName]"

### 1.3 **变量和函数导入**

- 此部分添加对所有所需函数和变量的支持。

```bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os
```

---

## 2. **变量命名和管理**

### 2.1 **命名约定**

- 对常量和环境变量使用大写名称。
- 对本地脚本变量使用小写名称。

示例：

```bash
DB_NAME=snipeit_db    # 类似环境的变量（常量）
db_user="snipeit"     # 本地变量
```

---

## 3. **依赖项**

### 3.1 **一次性安装所有**

- 如果可能，使用单个命令安装所有依赖项

示例：

```bash
$STD apt-get install -y \
  curl \
  composer \
  git \
  sudo \
  mc \
  nginx
```

### 3.2 **折叠依赖项**

折叠依赖项以保持代码可读性。

示例：
使用

```bash
php8.2-{bcmath,common,ctype}
```

而不是

```bash
php8.2-bcmath php8.2-common php8.2-ctype
```

---

## 4. **应用程序文件路径**

如果可能，将应用和所有必要文件安装在 `/opt/` 中

---

## 5. **版本管理**

### 5.1 **安装最新版本**

- 始终尝试安装最新版本
- 除非绝对必要，否则不要硬编码任何版本

git 发布的示例：

```bash
RELEASE=$(curl -fsSL https://api.github.com/repos/snipe/snipe-it/releases/latest | grep "tag_name" | awk '{print substr($2, 3, length($2)-4) }')
curl -fsSL "https://github.com/snipe/snipe-it/archive/refs/tags/v${RELEASE}.zip"
```

### 5.2 **保存版本以进行更新检查**

- 将安装的版本写入文件。
- 这用于 **AppName.sh** 中的更新函数，以检查是否需要更新。

示例：

```bash
echo "${RELEASE}" >"/opt/AppName_version.txt"
```

---

## 6. **输入和输出管理**

### 6.1 **用户反馈**

- 使用标准函数如 `msg_info`、`msg_ok` 或 `msg_error` 打印状态消息。
- 每个 `msg_info` 必须在任何其他输出之前跟随 `msg_ok`。
- 在关键阶段显示有意义的进度消息。

示例：

```bash
msg_info "Installing Dependencies"
$STD apt-get install -y ...
msg_ok "Installed Dependencies"
```

### 6.2 **详细程度**

- 使用适当的标志（示例中的 **-q**）来抑制命令的输出
  示例：

```bash
curl -fsSL
unzip -q
```

- 如果命令没有此功能，请使用 `$STD`（自定义标准重定向变量）来管理输出详细程度。

示例：

```bash
$STD apt-get install -y nginx
```

---

## 7. **字符串/文件操作**

### 7.1 **文件操作**

- 使用 `sed` 替换配置文件中的占位符值。

示例：

```bash
sed -i -e "s|^DB_DATABASE=.*|DB_DATABASE=$DB_NAME|" \
       -e "s|^DB_USERNAME=.*|DB_USERNAME=$DB_USER|" \
       -e "s|^DB_PASSWORD=.*|DB_PASSWORD=$DB_PASS|" .env
```

---

## 8. **安全实践**

### 8.1 **密码生成**

- 使用 `openssl` 生成随机密码。
- 仅使用字母数字值以避免引入未知行为。

示例：

```bash
DB_PASS=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
```

### 8.2 **文件权限**

明确设置敏感文件的安全所有权和权限。

示例：

```bash
chown -R www-data: /opt/snipe-it
chmod -R 755 /opt/snipe-it
```

---

## 9. **服务配置**

### 9.1 **配置文件**

使用 `cat <<EOF` 以清晰可读的方式编写配置文件。

示例：

```bash
cat <<EOF >/etc/nginx/conf.d/snipeit.conf
server {
    listen 80;
    root /opt/snipe-it/public;
    index index.php;
}
EOF
```

### 9.2 **凭据管理**

将生成的凭据存储在文件中。

示例：

```bash
USERNAME=username
PASSWORD=$(openssl rand -base64 18 | tr -dc 'a-zA-Z0-9' | head -c13)
{
    echo "Application-Credentials"
    echo "Username: $USERNAME"
    echo "Password: $PASSWORD"
} >> ~/application.creds
```

### 9.3 **环境文件**

使用 `cat <<EOF` 以清晰可读的方式编写环境文件。

示例：

```bash
cat <<EOF >/path/to/.env
VARIABLE="value"
PORT=3000
DB_NAME="${DB_NAME}"
EOF
```

### 9.4 **服务**

配置更改后启用受影响的服务并立即启动它们。

示例：

```bash
systemctl enable -q --now nginx
```

---

## 10. **清理**

### 10.1 **删除临时文件**

使用后删除临时文件和下载。

示例：

```bash
rm -rf /opt/v${RELEASE}.zip
```

### 10.2 **自动删除和自动清理**

删除未使用的依赖项以减少磁盘空间使用。

示例：

```bash
apt-get -y autoremove
apt-get -y autoclean
```

---

## 11. **最佳实践清单**

- [ ] Shebang 设置正确（`#!/usr/bin/env bash`）。
- [ ] 顶部包含元数据（作者、许可证）。
- [ ] 变量遵循命名约定。
- [ ] 敏感值动态生成。
- [ ] 文件和服务具有适当的权限。
- [ ] 脚本清理临时文件。

---

### 示例：高级脚本流程

1. 依赖项安装
2. 数据库设置
3. 下载和配置应用程序
4. 服务配置
5. 最终清理
