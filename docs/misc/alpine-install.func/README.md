# alpine-install.func 文档

## 概述

`alpine-install.func` 文件为 LXC 容器提供 Alpine Linux 特定的安装和配置函数。它使用 apk 包管理器而非 apt，补充了标准的 `install.func` 功能，提供 Alpine 特定的操作。

## 用途和使用场景

- **Alpine 容器设置**：使用正确的配置初始化 Alpine Linux 容器
- **IPv6 管理**：在 Alpine 中启用或禁用 IPv6 并持久化配置
- **网络验证**：验证 Alpine 环境中的连接性
- **SSH 配置**：在 Alpine 上设置 SSH 守护进程
- **自动登录设置**：为 Alpine 容器配置无密码 root 登录
- **包管理**：带错误处理的安全 apk 操作

## 快速参考

### 主要函数组
- **初始化**：`setting_up_container()` - Alpine 设置消息
- **网络**：`verb_ip6()`、`network_check()` - IPv6 和连接性
- **操作系统配置**：`update_os()` - Alpine 包更新
- **SSH/MOTD**：`motd_ssh()` - SSH 和登录消息设置
- **容器自定义**：`customize()`、`cleanup_lxc()` - 最终设置

### 依赖项
- **外部**：`apk`、`curl`、`wget`、`ping`
- **内部**：使用来自 `core.func`、`error_handler.func` 的函数

### 集成点
- 被使用于：基于 Alpine 的安装脚本（alpine.sh、alpine-ntfy.sh 等）
- 使用：来自 build.func 的环境变量
- 提供：Alpine 特定的安装和管理服务

## 文档文件

### 📊 [ALPINE_INSTALL_FUNC_FLOWCHART.md](./ALPINE_INSTALL_FUNC_FLOWCHART.md)
显示 Alpine 容器初始化和设置工作流程的可视化执行流程。

### 📚 [ALPINE_INSTALL_FUNC_FUNCTIONS_REFERENCE.md](./ALPINE_INSTALL_FUNC_FUNCTIONS_REFERENCE.md)
所有函数的完整字母顺序参考，包含参数和使用详情。

### 💡 [ALPINE_INSTALL_FUNC_USAGE_EXAMPLES.md](./ALPINE_INSTALL_FUNC_USAGE_EXAMPLES.md)
展示如何使用 Alpine 安装函数的实用示例。

### 🔗 [ALPINE_INSTALL_FUNC_INTEGRATION.md](./ALPINE_INSTALL_FUNC_INTEGRATION.md)
alpine-install.func 如何与标准安装工作流程集成。

## 主要特性

### Alpine 特定函数
- **apk 包管理器**：Alpine 包操作（而非 apt-get）
- **OpenRC 支持**：Alpine 使用 OpenRC init 而非 systemd
- **轻量级设置**：适合 Alpine 的最小依赖
- **IPv6 配置**：通过 `/etc/network/interfaces` 持久化 IPv6 设置

### 网络和连接性
- **IPv6 切换**：启用/禁用并持久化配置
- **连接性检查**：验证 Alpine 中的互联网访问
- **DNS 验证**：正确解析域名
- **重试逻辑**：从临时故障中自动恢复

### SSH 和自动登录
- **SSH 守护进程**：在 Alpine 上设置并启动 sshd
- **Root 密钥**：配置 root SSH 访问
- **自动登录**：可选的无密码自动登录
- **MOTD**：Alpine 上的自定义登录消息

## 函数分类

### 🔹 核心函数
- `setting_up_container()` - Alpine 容器设置消息
- `update_os()` - 通过 apk 更新 Alpine 包
- `verb_ip6()` - 持久化启用/禁用 IPv6
- `network_check()` - 验证网络连接性

### 🔹 SSH 和配置函数
- `motd_ssh()` - 在 Alpine 上配置 SSH 守护进程
- `customize()` - 应用 Alpine 特定的自定义
- `cleanup_lxc()` - 最终清理

### 🔹 服务管理（OpenRC）
- `rc-update` - 为 Alpine 启用/禁用服务
- `rc-service` - 在 Alpine 上启动/停止服务
- 服务配置文件位于 `/etc/init.d/`

## 与 Debian 安装的差异

| 特性 | Debian (install.func) | Alpine (alpine-install.func) |
|---------|:---:|:---:|
| 包管理器 | apt-get | apk |
| Init 系统 | systemd | OpenRC |
| SSH 服务 | systemctl | rc-service |
| 配置文件 | /etc/systemd/ | /etc/init.d/ |
| 网络配置 | /etc/network/ 或 Netplan | /etc/network/interfaces |
| IPv6 设置 | netplan 文件 | /etc/network/interfaces |
| 自动登录 | getty 覆盖 | `/etc/inittab` 或 shell 配置 |
| 大小 | ~200MB | ~100MB |

## Alpine 执行流程

```
Alpine 容器启动
    ↓
source $FUNCTIONS_FILE_PATH
    ↓
setting_up_container()           ← Alpine 设置消息
    ↓
update_os()                      ← apk 更新
    ↓
verb_ip6()                       ← IPv6 配置（可选）
    ↓
network_check()                  ← 验证连接性
    ↓
[应用程序特定安装]
    ↓
motd_ssh()                       ← 配置 SSH/MOTD
customize()                      ← 应用自定义
    ↓
cleanup_lxc()                    ← 最终清理
    ↓
Alpine 安装完成
```

## 常见使用模式

### 基本 Alpine 设置
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
setting_up_container
update_os

# 安装 Alpine 特定包
apk add --no-cache curl wget git

# ... 应用程序安装 ...

motd_ssh
customize
cleanup_lxc
```

### 启用 IPv6
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
setting_up_container
verb_ip6
update_os
network_check

# ... 应用程序安装 ...

motd_ssh
customize
cleanup_lxc
```

### 安装服务
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
setting_up_container
update_os

# 通过 apk 安装
apk add --no-cache nginx

# 在 Alpine 上启用并启动服务
rc-update add nginx
rc-service nginx start

motd_ssh
customize
cleanup_lxc
```

## 最佳实践

### ✅ 应该做
- 使用 `apk add --no-cache` 减小镜像大小
- 如果应用程序需要，启用 IPv6（`verb_ip6`）
- 在 Alpine 上使用 `rc-service` 进行服务管理
- 检查 `/etc/network/interfaces` 以确保 IPv6 持久化
- 在关键操作前测试网络连接性
- 在生产环境中使用 `$STD` 抑制输出

### ❌ 不应该做
- 使用 `apt-get` 命令（Alpine 没有 apt）
- 使用 `systemctl`（Alpine 使用 OpenRC，而非 systemd）
- 使用 `service` 命令（Alpine 上可能不存在）
- 假设 Alpine 上存在 systemd
- 忘记在 `apk add` 中添加 `--no-cache` 标志
- 硬编码 Debian 的路径（Alpine 上不同）

## Alpine 特定注意事项

### 包名称
某些包在 Alpine 上有不同的名称：
```bash
# Debian        → Alpine
# curl          → curl（相同）
# wget          → wget（相同）
# python3       → python3（相同）
# libpq5        → postgresql-client
# libmariadb3   → mariadb-client
```

### 服务管理
```bash
# Debian (systemd)      → Alpine (OpenRC)
systemctl start nginx   → rc-service nginx start
systemctl enable nginx  → rc-update add nginx
systemctl status nginx  → rc-service nginx status
```

### 网络配置
```bash
# Debian (Netplan)                → Alpine (/etc/network/interfaces)
/etc/netplan/01-*.yaml            → /etc/network/interfaces
netplan apply                      → 直接在 interfaces 中配置

# 在 Alpine 上持久化启用 IPv6：
# 添加到 /etc/network/interfaces：
# iface eth0 inet6 static
#     address <IPv6_ADDRESS>
```

## 故障排除

### "apk command not found"
- 这是 Alpine Linux，而非 Debian
- 使用 `apk add` 而非 `apt-get install` 安装包
- 示例：`apk add --no-cache curl wget`

### "IPv6 重启后未持久化"
- IPv6 必须在 `/etc/network/interfaces` 中配置
- `verb_ip6()` 函数会自动处理此问题
- 验证：`cat /etc/network/interfaces`

### "服务在 Alpine 上无法启动"
- Alpine 使用 OpenRC，而非 systemd
- 使用 `rc-service nginx start` 而非 `systemctl start nginx`
- 启用服务：`rc-update add nginx`
- 检查日志：`/var/log/` 或 `rc-service nginx status`

### "容器过大"
- Alpine 应该比 Debian 小得多
- 验证使用 `apk add --no-cache`（删除包缓存）
- 示例：`apk add --no-cache nginx`（而非 `apk add nginx`）

## 相关文档

- **[alpine-tools.func/](../alpine-tools.func/)** - Alpine 工具安装
- **[install.func/](../install.func/)** - 标准安装函数
- **[core.func/](../core.func/)** - 实用函数
- **[error_handler.func/](../error_handler.func/)** - 错误处理
- **[UPDATED_APP-install.md](../../UPDATED_APP-install.md)** - 应用程序脚本指南

## 最近更新

### 版本 2.0（2025 年 12 月）
- ✅ 增强 IPv6 持久化配置
- ✅ 改进 OpenRC 服务管理
- ✅ 更好的 apk 错误处理
- ✅ 添加 Alpine 特定最佳实践文档
- ✅ 简化 Alpine 的 SSH 设置

---

**最后更新**：2025 年 12 月
**维护者**：community-scripts 团队
**许可证**：MIT
