# install.func 文档

## 概述

`install.func` 文件为部署在 LXC 容器内的应用程序提供容器安装工作流程编排和基本操作。它处理网络设置、OS 配置、连接性验证和安装机制。

## 目的和用例

- **容器设置**：使用正确的配置初始化新容器
- **网络验证**：验证 IPv4 和 IPv6 连接性
- **OS 配置**：更新 OS，应用系统设置
- **安装工作流程**：编排应用程序安装步骤
- **错误处理**：全面的信号捕获和错误恢复

## 快速参考

### 主要功能组
- **初始化**：`setting_up_container()` - 设置消息和环境
- **网络**：`network_check()`、`verb_ip6()` - 连接性验证
- **OS 配置**：`update_os()` - OS 更新和包管理
- **安装**：`motd_ssh()`、`customize()` - 容器自定义
- **清理**：`cleanup_lxc()` - 最终容器清理

### 依赖项
- **外部**：`curl`、`apt-get`、`ping`、`dns` 实用程序
- **内部**：使用来自 `core.func`、`error_handler.func`、`tools.func` 的函数

### 集成点
- 被使用于：启动时的所有 install/*.sh 脚本
- 使用：来自 build.func 和 core.func 的环境变量
- 提供：容器初始化和管理服务

## 文档文件

### 📊 [INSTALL_FUNC_FLOWCHART.md](./INSTALL_FUNC_FLOWCHART.md)
显示初始化、网络检查和安装工作流程的可视化执行流程。

### 📚 [INSTALL_FUNC_FUNCTIONS_REFERENCE.md](./INSTALL_FUNC_FUNCTIONS_REFERENCE.md)
所有函数的完整字母顺序参考，包含参数、依赖项和使用详情。

### 💡 [INSTALL_FUNC_USAGE_EXAMPLES.md](./INSTALL_FUNC_USAGE_EXAMPLES.md)
展示如何使用安装函数和常见模式的实用示例。

### 🔗 [INSTALL_FUNC_INTEGRATION.md](./INSTALL_FUNC_INTEGRATION.md)
install.func 如何与其他组件集成并提供安装服务。

## 主要特性

### 容器初始化
- **环境设置**：准备容器变量和函数
- **消息系统**：使用彩色输出显示安装进度
- **错误处理程序**：设置信号捕获以进行适当清理

### 网络和连接性
- **IPv4 验证**：Ping 外部主机以验证互联网访问
- **IPv6 支持**：可选的 IPv6 启用和验证
- **DNS 检查**：验证 DNS 解析是否正常工作
- **重试逻辑**：从临时故障中自动恢复

### OS 配置
- **包更新**：安全更新 OS 包列表
- **系统优化**：禁用不必要的服务（wait-online）
- **时区**：验证并设置容器时区
- **SSH 设置**：配置 SSH 守护进程和密钥

### 容器自定义
- **MOTD**：创建自定义登录消息
- **自动登录**：可选的无密码 root 登录
- **更新脚本**：注册应用程序更新函数
- **自定义钩子**：应用程序特定的设置

## 函数分类

### 🔹 核心函数
- `setting_up_container()` - 显示设置消息并设置环境
- `network_check()` - 验证网络连接性
- `update_os()` - 使用重试逻辑更新 OS 包
- `verb_ip6()` - 启用 IPv6（可选）

### 🔹 配置函数
- `motd_ssh()` - 设置 MOTD 和 SSH 配置
- `customize()` - 应用容器自定义
- `cleanup_lxc()` - 完成前的最终清理

### 🔹 实用函数
- `create_update_script()` - 注册应用程序更新函数
- `set_timezone()` - 配置容器时区
- `disable_wait_online()` - 禁用 systemd-networkd-wait-online

## 执行流程

```
容器已启动
    ↓
source $FUNCTIONS_FILE_PATH
    ↓
setting_up_container()           ← 显示 "正在设置容器..."
    ↓
network_check()                  ← 验证互联网连接性
    ↓
update_os()                      ← 更新包列表
    ↓
[应用程序特定安装]
    ↓
motd_ssh()                       ← 配置 SSH/MOTD
customize()                      ← 应用自定义
    ↓
cleanup_lxc()                    ← 最终清理
    ↓
安装完成
```

## 常见使用模式

### 基本容器设置
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
setting_up_container
network_check
update_os

# ... 应用程序安装 ...

motd_ssh
customize
cleanup_lxc
```

### 使用可选 IPv6
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
setting_up_container
verb_ip6  # 启用 IPv6
network_check
update_os

# ... 安装 ...

motd_ssh
customize
cleanup_lxc
```

### 使用自定义更新脚本
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"
setting_up_container
network_check
update_os

# ... 安装 ...

# 注册更新函数
function update_script() {
  # 更新逻辑在这里
}
export -f update_script

motd_ssh
customize
cleanup_lxc
```

## 最佳实践

### ✅ 应该做
- 在开始时调用 `setting_up_container()`
- 在主安装前检查 `network_check()` 输出
- 使用 `$STD` 变量进行静默操作
- 在最后调用 `cleanup_lxc()`
- 在关键操作前测试网络连接性

### ❌ 不应该做
- 跳过网络验证
- 假设互联网可用
- 硬编码容器路径
- 使用 `echo` 而非 `msg_*` 函数
- 忘记在最后调用清理

## 环境变量

### 可用变量
- `$FUNCTIONS_FILE_PATH` - 核心函数路径（由 build.func 设置）
- `$CTID` - 容器 ID 号
- `$NSAPP` - 规范化应用程序名称（小写）
- `$APP` - 应用程序显示名称
- `$STD` - 输出抑制（`silent` 或空）
- `$VERBOSE` - 详细输出模式（`yes` 或 `no`）

### 设置容器变量
```bash
CONTAINER_TIMEZONE="UTC"
CONTAINER_HOSTNAME="myapp-container"
CONTAINER_FQDN="myapp.example.com"
```

## 故障排除

### "网络检查失败"
```bash
# 容器可能没有互联网访问
# 检查：
ping 8.8.8.8           # 外部连接性
nslookup example.com   # DNS 解析
ip route show          # 路由表
```

### "包更新失败"
```bash
# APT 可能被另一个进程锁定
ps aux | grep apt      # 检查正在运行的 apt
# 或等待现有 apt 完成
sleep 30
update_os
```

### "无法引用函数"
```bash
# $FUNCTIONS_FILE_PATH 可能未设置
# 此变量在运行安装脚本前由 build.func 设置
# 如果缺失，安装脚本未正确调用
```

## 相关文档

- **[tools.func/](../tools.func/)** - 包和工具安装
- **[core.func/](../core.func/)** - 实用函数和消息
- **[error_handler.func/](../error_handler.func/)** - 错误处理
- **[alpine-install.func/](../alpine-install.func/)** - Alpine 特定设置
- **[UPDATED_APP-install.md](../../UPDATED_APP-install.md)** - 应用程序脚本指南

## 最近更新

### 版本 2.0（2025 年 12 月）
- ✅ 改进网络连接性检查
- ✅ 增强 OS 更新错误处理
- ✅ 使用 verb_ip6() 添加 IPv6 支持
- ✅ 更好的时区验证
- ✅ 简化清理程序

---

**最后更新**：2025 年 12 月
**维护者**：community-scripts 团队
**许可证**：MIT
