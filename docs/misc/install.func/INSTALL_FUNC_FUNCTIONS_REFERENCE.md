# install.func 函数参考

install.func 中所有函数的完整参考，包含详细的使用信息。

## 函数索引

- `setting_up_container()` - 初始化容器设置
- `network_check()` - 验证网络连接
- `update_os()` - 更新操作系统软件包
- `verb_ip6()` - 启用 IPv6
- `motd_ssh()` - 配置 SSH 和 MOTD
- `customize()` - 应用容器自定义设置
- `cleanup_lxc()` - 最终容器清理

---

## 核心函数

### setting_up_container()

显示设置消息并初始化容器环境。

**函数签名**:
```bash
setting_up_container
```

**用途**: 宣告容器初始化并设置初始环境

**使用方法**:
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

setting_up_container
# Output: ⏳ Setting up container...
```

---

### network_check()

验证网络连接，带有自动重试逻辑。

**函数签名**:
```bash
network_check
```

**用途**: 在关键操作前确保互联网连接

**行为**:
- Ping 8.8.8.8 (Google DNS)
- 3 次尝试，每次间隔 5 秒
- 如果所有尝试都失败则退出并报错

**使用方法**:
```bash
network_check
# If no internet: Exits with error message
# If internet OK: Continues to next step
```

**错误处理**:
```bash
if ! network_check; then
  msg_error "No internet connection"
  exit 1
fi
```

---

### update_os()

更新操作系统软件包，带有错误处理。

**函数签名**:
```bash
update_os
```

**用途**: 使用最新软件包准备容器

**在 Debian/Ubuntu 上**:
- 运行: `apt-get update && apt-get upgrade -y`

**在 Alpine 上**:
- 运行: `apk update && apk upgrade`

**使用方法**:
```bash
update_os
```

---

### verb_ip6()

在容器中启用 IPv6 支持（可选）。

**函数签名**:
```bash
verb_ip6
```

**用途**: 如果应用程序需要，启用 IPv6

**使用方法**:
```bash
verb_ip6              # Enable IPv6
network_check         # Verify connectivity with IPv6
```

---

### motd_ssh()

为容器访问配置 SSH 守护进程和 MOTD。

**函数签名**:
```bash
motd_ssh
```

**用途**: 设置 SSH 并创建登录消息

**配置内容**:
- SSH 守护进程启动和密钥
- 显示应用程序访问信息的自定义 MOTD
- SSH 端口和安全设置

**使用方法**:
```bash
motd_ssh
# SSH is now configured and application info is in MOTD
```

---

### customize()

应用容器自定义设置和最终设置。

**函数签名**:
```bash
customize
```

**用途**: 应用任何剩余的自定义设置

**使用方法**:
```bash
customize
```

---

### cleanup_lxc()

最终清理并完成安装。

**函数签名**:
```bash
cleanup_lxc
```

**用途**: 删除临时文件并完成安装

**清理内容**:
- 临时安装文件
- 软件包管理器缓存
- 安装过程中的日志文件

**使用方法**:
```bash
cleanup_lxc
# Installation is now complete and ready
```

---

## 常见模式

### 基本安装模式

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

setting_up_container
network_check
update_os

# ... application installation ...

motd_ssh
customize
cleanup_lxc
```

### 带 IPv6 支持

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

setting_up_container
verb_ip6              # Enable IPv6
network_check
update_os

# ... application installation ...
```

### 带错误处理

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

catch_errors          # Setup error trapping
setting_up_container

if ! network_check; then
  msg_error "Network connectivity failed"
  exit 1
fi

update_os
```

---

**最后更新**: 2025年12月
**函数总数**: 7
**维护者**: community-scripts 团队
