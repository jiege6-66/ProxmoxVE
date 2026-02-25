# tools.func 文档

## 概述

`tools.func` 文件为基于 Debian/Ubuntu 的系统提供了一套全面的辅助函数集合，用于强大的包管理、仓库管理和工具安装。它是在容器中安装服务、数据库、编程语言和开发工具的中心枢纽。

## 目的和用例

- **包管理**：带重试逻辑的强大 APT/DPKG 操作
- **仓库设置**：安全地准备和配置包仓库
- **工具安装**：安装 30+ 种工具（Node.js、PHP、数据库等）
- **依赖处理**：管理复杂的安装工作流程
- **错误恢复**：从网络故障中自动恢复

## 快速参考

### 主要功能组
- **包助手**：`pkg_install()`、`pkg_update()`、`pkg_remove()` - 带重试的 APT 操作
- **仓库设置**：`setup_deb822_repo()` - 现代仓库配置
- **工具安装**：`setup_nodejs()`、`setup_php()`、`setup_mariadb()` 等 - 30+ 种工具函数
- **系统实用程序**：`disable_wait_online()`、`customize()` - 系统优化
- **容器设置**：`setting_up_container()`、`motd_ssh()` - 容器初始化

### 依赖项
- **外部**：`curl`、`wget`、`apt-get`、`gpg`
- **内部**：使用来自 `core.func`、`install.func`、`error_handler.func` 的函数

### 集成点
- 被使用于：所有用于依赖安装的安装脚本
- 使用：来自 build.func 和 core.func 的环境变量
- 提供：工具安装、包管理和仓库服务

## 文档文件

### 📊 [TOOLS_FUNC_FLOWCHART.md](./TOOLS_FUNC_FLOWCHART.md)
显示包管理、工具安装和仓库设置工作流程的可视化执行流程。

### 📚 [TOOLS_FUNC_FUNCTIONS_REFERENCE.md](./TOOLS_FUNC_FUNCTIONS_REFERENCE.md)
所有 30+ 个函数的完整字母顺序参考，包含参数、依赖项和使用详情。

### 💡 [TOOLS_FUNC_USAGE_EXAMPLES.md](./TOOLS_FUNC_USAGE_EXAMPLES.md)
展示如何使用工具安装函数和常见模式的实用示例。

### 🔗 [TOOLS_FUNC_INTEGRATION.md](./TOOLS_FUNC_INTEGRATION.md)
tools.func 如何与其他组件集成并提供包/工具服务。

### 🔧 [TOOLS_FUNC_ENVIRONMENT_VARIABLES.md](./TOOLS_FUNC_ENVIRONMENT_VARIABLES.md)
环境变量和配置选项的完整参考。

## 主要特性

### 强大的包管理
- **自动重试逻辑**：对临时故障进行 3 次尝试并退避
- **静默模式**：使用 `$STD` 变量抑制输出
- **错误恢复**：自动清理损坏的包
- **原子操作**：即使失败也确保一致状态

### 工具安装覆盖
- **Node.js 生态系统**：Node.js、npm、yarn、pnpm
- **PHP 栈**：PHP-FPM、PHP-CLI、Composer
- **数据库**：MariaDB、PostgreSQL、MongoDB
- **开发工具**：Git、build-essential、Docker
- **监控**：Grafana、Prometheus、Telegraf
- **以及 20+ 种更多工具...**

### 仓库管理
- **Deb822 格式**：现代标准化仓库格式
- **密钥环处理**：自动 GPG 密钥管理
- **清理**：删除旧仓库和密钥环
- **验证**：使用前验证仓库可访问性

## 常见使用模式

### 安装工具
```bash
setup_nodejs "20"     # 安装 Node.js v20
setup_php "8.2"       # 安装 PHP 8.2
setup_mariadb         # 安装 MariaDB（发行版包）
# MARIADB_VERSION="11.4" setup_mariadb  # 从官方仓库安装特定版本
```

### 安全的包操作
```bash
pkg_update           # 带重试更新包列表
pkg_install curl wget  # 安全安装包
pkg_remove old-tool   # 干净地删除包
```

### 设置仓库
```bash
setup_deb822_repo "ppa:example/ppa" "example-app" "jammy" "http://example.com" "release"
```

## 函数分类

### 🔹 核心包函数
- `pkg_install()` - 带重试逻辑安装包
- `pkg_update()` - 安全更新包列表
- `pkg_remove()` - 完全删除包

### 🔹 仓库函数
- `setup_deb822_repo()` - 以 deb822 格式添加仓库
- `cleanup_repo_metadata()` - 清理 GPG 密钥和旧仓库
- `check_repository()` - 验证仓库可访问

### 🔹 工具安装函数（30+）
**编程语言**：
- `setup_nodejs()` - 带 npm 的 Node.js
- `setup_php()` - PHP-FPM 和 CLI
- `setup_python()` - 带 pip 的 Python 3
- `setup_ruby()` - 带 gem 的 Ruby
- `setup_golang()` - Go 编程语言

**数据库**：
- `setup_mariadb()` - MariaDB 服务器
- `setup_postgresql()` - PostgreSQL 数据库
- `setup_mongodb()` - MongoDB NoSQL
- `setup_redis()` - Redis 缓存

**Web 服务器和代理**：
- `setup_nginx()` - Nginx Web 服务器
- `setup_apache()` - Apache HTTP 服务器
- `setup_caddy()` - Caddy Web 服务器
- `setup_traefik()` - Traefik 反向代理

**容器和虚拟化**：
- `setup_docker()` - Docker 容器运行时
- `setup_podman()` - Podman 容器运行时

**开发和系统工具**：
- `setup_git()` - Git 版本控制
- `setup_docker_compose()` - Docker Compose
- `setup_composer()` - PHP 依赖管理器
- `setup_build_tools()` - C/C++ 编译工具

**监控和日志**：
- `setup_grafana()` - Grafana 仪表板
- `setup_prometheus()` - Prometheus 监控
- `setup_telegraf()` - Telegraf 指标收集器

### 🔹 系统配置函数
- `setting_up_container()` - 容器初始化消息
- `network_check()` - 验证网络连接性
- `update_os()` - 安全更新 OS 包
- `customize()` - 应用容器自定义
- `motd_ssh()` - 配置 SSH 和 MOTD
- `cleanup_lxc()` - 最终容器清理

## 最佳实践

### ✅ 应该做
- 在生产脚本中使用 `$STD` 抑制输出
- 将多个工具安装链接在一起
- 使用前检查工具可用性
- 在可用时使用版本参数
- 在生产使用前测试新仓库

### ❌ 不应该做
- 混合包管理器（在同一脚本中使用 apt 和 apk）
- 直接硬编码工具版本
- 跳过包操作的错误检查
- 不使用 `$STD` 而使用 `apt-get install -y`
- 安装后留下临时文件

## 最近更新

### 版本 2.0（2025 年 12 月）
- ✅ 为现代仓库格式添加 `setup_deb822_repo()`
- ✅ 改进带自动清理的错误处理
- ✅ 添加 5 个新工具安装函数
- ✅ 增强带退避的包重试逻辑
- ✅ 标准化工具版本处理

## 与其他函数的集成

```
tools.func
    ├── 使用：core.func（消息、颜色）
    ├── 使用：error_handler.func（退出代码、捕获）
    ├── 使用：install.func（network_check、update_os）
    │
    └── 被使用于：所有 install/*.sh 脚本
        ├── 用于：包安装
        ├── 用于：工具设置
        └── 用于：仓库管理
```

## 故障排除

### "包管理器被锁定"
```bash
# 等待 apt 锁释放
sleep 10
pkg_update
```

### "未找到 GPG 密钥"
```bash
# 仓库设置将自动处理此问题
# 如需手动修复：
cleanup_repo_metadata
setup_deb822_repo ...
```

### "工具安装失败"
```bash
# 启用详细输出
export var_verbose="yes"
setup_nodejs "20"
```

## 贡献

添加新工具安装函数时：

1. 遵循 `setup_TOOLNAME()` 命名约定
2. 接受版本作为第一个参数
3. 检查工具是否已安装
4. 使用 `$STD` 抑制输出
5. 设置版本文件：`/opt/TOOLNAME_version.txt`
6. 在 TOOLS_FUNC_FUNCTIONS_REFERENCE.md 中记录

## 相关文档

- **[build.func/](../build.func/)** - 容器创建编排器
- **[core.func/](../core.func/)** - 实用函数和消息
- **[install.func/](../install.func/)** - 安装工作流程管理
- **[error_handler.func/](../error_handler.func/)** - 错误处理和恢复
- **[UPDATED_APP-install.md](../../UPDATED_APP-install.md)** - 应用程序脚本指南

---

**最后更新**：2025 年 12 月
**维护者**：community-scripts 团队
**许可证**：MIT
