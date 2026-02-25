# alpine-tools.func 文档

## 概述

`alpine-tools.func` 文件为 Alpine LXC 容器中的包和服务管理提供 Alpine Linux 特定的工具安装函数。它使用 apk 包管理器，通过 Alpine 特定的实现补充了 `tools.func`。

## 用途和使用场景

- **Alpine 工具安装**：在 Alpine 上使用 apk 安装服务和工具
- **包管理**：带错误处理的安全 apk 操作
- **服务设置**：在 Alpine 上安装和配置常见服务
- **依赖管理**：处理 Alpine 特定的包依赖
- **仓库管理**：设置和管理 Alpine 包仓库

## 快速参考

### 主要函数组
- **包操作**：带错误处理的 Alpine 特定 apk 命令
- **服务安装**：在 Alpine 上安装数据库、Web 服务器、工具
- **仓库设置**：配置 Alpine community 和 testing 仓库
- **工具设置**：安装开发工具和实用程序

### 依赖项
- **外部**：`apk`、`curl`、`wget`
- **内部**：使用来自 `core.func`、`error_handler.func` 的函数

### 集成点
- 被使用于：基于 Alpine 的应用程序安装脚本
- 使用：来自 build.func 的环境变量
- 提供：Alpine 包和工具安装服务

## 文档文件

### 📊 [ALPINE_TOOLS_FUNC_FLOWCHART.md](./ALPINE_TOOLS_FUNC_FLOWCHART.md)
Alpine 上包操作和工具安装的可视化执行流程。

### 📚 [ALPINE_TOOLS_FUNC_FUNCTIONS_REFERENCE.md](./ALPINE_TOOLS_FUNC_FUNCTIONS_REFERENCE.md)
所有 Alpine 工具函数的完整字母顺序参考。

### 💡 [ALPINE_TOOLS_FUNC_USAGE_EXAMPLES.md](./ALPINE_TOOLS_FUNC_USAGE_EXAMPLES.md)
常见 Alpine 安装模式的实用示例。

### 🔗 [ALPINE_TOOLS_FUNC_INTEGRATION.md](./ALPINE_TOOLS_FUNC_INTEGRATION.md)
alpine-tools.func 如何与 Alpine 安装工作流程集成。

## 主要特性

### Alpine 包管理
- **apk Add**：带错误处理的安全包安装
- **apk Update**：带重试逻辑的更新包列表
- **apk Del**：删除包和依赖
- **仓库配置**：添加 community 和 testing 仓库

### Alpine 工具覆盖
- **Web 服务器**：nginx、lighttpd
- **数据库**：mariadb、postgresql、sqlite
- **开发**：gcc、make、git、node.js（通过 apk）
- **服务**：sshd、docker、podman
- **实用程序**：curl、wget、htop、vim

### 错误处理
- **重试逻辑**：从临时故障中自动恢复
- **依赖解析**：处理缺失的依赖
- **锁管理**：等待 apk 锁释放
- **错误报告**：清晰的错误消息

## 函数分类

### 🔹 包管理
- `apk_update()` - 带重试的更新 Alpine 包
- `apk_add()` - 安全安装包
- `apk_del()` - 完全删除包

### 🔹 仓库函数
- `add_community_repo()` - 启用 community 仓库
- `add_testing_repo()` - 启用 testing 仓库
- `setup_apk_repo()` - 配置自定义 apk 仓库

### 🔹 服务安装函数
- `setup_nginx()` - 安装和配置 nginx
- `setup_mariadb()` - 在 Alpine 上安装 MariaDB
- `setup_postgresql()` - 安装 PostgreSQL
- `setup_docker()` - 在 Alpine 上安装 Docker
- `setup_nodejs()` - 从 Alpine 仓库安装 Node.js

### 🔹 开发工具
- `setup_build_tools()` - 安装 gcc、make、build-essential
- `setup_git()` - 安装 git 版本控制
- `setup_python()` - 安装 Python 3 和 pip

## Alpine 与 Debian 包差异

| 包 | Debian | Alpine |
|---------|:---:|:---:|
| nginx | `apt-get install nginx` | `apk add nginx` |
| mariadb | `apt-get install mariadb-server` | `apk add mariadb` |
| PostgreSQL | `apt-get install postgresql` | `apk add postgresql` |
| Node.js | `apt-get install nodejs npm` | `apk add nodejs npm` |
| Docker | 特殊设置 | `apk add docker` |
| Python | `apt-get install python3 python3-pip` | `apk add python3 py3-pip` |

## 常见使用模式

### 基本 Alpine 工具安装
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# 更新包列表
apk_update

# 安装 nginx
apk_add nginx

# 启动服务
rc-service nginx start
rc-update add nginx
```

### 使用 Community 仓库
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# 启用 community 仓库以获取更多包
add_community_repo

# 更新并安装
apk_update
apk_add postgresql postgresql-client

# 启动服务
rc-service postgresql start
```

### 开发环境
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# 安装构建工具
setup_build_tools
setup_git
setup_nodejs "20"

# 安装应用程序
git clone https://example.com/app
cd app
npm install
```

## 最佳实践

### ✅ 应该做
- 始终使用 `apk add --no-cache` 保持镜像小巧
- 在安装包之前调用 `apk_update()`
- 使用 community 仓库获取更多包（`add_community_repo`）
- 使用重试逻辑优雅地处理 apk 锁
- 使用 `$STD` 变量控制输出
- 在重新安装之前检查工具是否已安装

### ❌ 不应该做
- 使用 `apt-get` 命令（Alpine 没有 apt）
- 安装包时不使用 `--no-cache` 标志
- 硬编码 Alpine 特定路径
- 混合 Alpine 和 Debian 命令
- 忘记使用 `rc-update` 启用服务
- 使用 `systemctl`（Alpine 使用 OpenRC，而非 systemd）

## Alpine 仓库配置

### 默认仓库
Alpine 默认启用 main 仓库。额外的仓库：

```bash
# Community 仓库（apk add php、go、rust 等）
add_community_repo

# Testing 仓库（最新包）
add_testing_repo
```

### 仓库位置
```bash
/etc/apk/repositories      # 主仓库列表
/etc/apk/keys/             # 仓库的 GPG 密钥
/var/cache/apk/            # 包缓存
```

## 包大小优化

Alpine 专为小型容器镜像设计：

```bash
# 不推荐：保留包缓存（增加镜像大小）
apk add nginx

# 推荐：删除缓存以减小大小
apk add --no-cache nginx

# 预期大小：
# Alpine 基础：~5MB
# Alpine + nginx：~10-15MB
# Debian 基础：~75MB
# Debian + nginx：~90-95MB
```

## Alpine 上的服务管理

### 使用 OpenRC
```bash
# 立即启动服务
rc-service nginx start

# 停止服务
rc-service nginx stop

# 重启服务
rc-service nginx restart

# 开机启用
rc-update add nginx

# 开机禁用
rc-update del nginx

# 列出已启用的服务
rc-update show
```

## 故障排除

### "apk: lock is held by PID"
```bash
# Alpine apk 数据库被锁定（另一个进程正在使用 apk）
# 等待一会儿
sleep 5
apk_update

# 或手动：
rm /var/lib/apk/lock 2>/dev/null || true
apk update
```

### "Package not found"
```bash
# 可能在 community 或 testing 仓库中
add_community_repo
apk_update
apk_add package-name
```

### "Repository not responding"
```bash
# Alpine 仓库可能很慢或无法访问
# 使用重试逻辑再次尝试更新
apk_update  # 内置重试逻辑

# 或手动重试
sleep 10
apk update
```

### "Service fails to start"
```bash
# 检查 Alpine 上的服务状态
rc-service nginx status

# 查看日志
tail /var/log/nginx/error.log

# 验证配置
nginx -t
```

## 相关文档

- **[alpine-install.func/](../alpine-install.func/)** - Alpine 安装函数
- **[tools.func/](../tools.func/)** - Debian/标准工具安装
- **[core.func/](../core.func/)** - 实用函数
- **[error_handler.func/](../error_handler.func/)** - 错误处理
- **[UPDATED_APP-install.md](../../UPDATED_APP-install.md)** - 应用程序脚本指南

## 最近更新

### 版本 2.0（2025 年 12 月）
- ✅ 增强 apk 错误处理和重试逻辑
- ✅ 改进仓库管理
- ✅ 使用 OpenRC 更好地管理服务
- ✅ 添加 Alpine 特定优化指南
- ✅ 增强包缓存管理

---

**最后更新**：2025 年 12 月
**维护者**：community-scripts 团队
**许可证**：MIT
