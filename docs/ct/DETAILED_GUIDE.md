# 🚀 **应用容器脚本 (ct/AppName.sh)**

**创建 LXC 容器安装脚本的现代指南**

> **更新时间**: 2025年12月
> **上下文**: 完全集成 build.func、advanced_settings 向导和默认系统
> **示例**: `/ct/pihole.sh`、`/ct/docker.sh`

---

## 📋 目录

- [概述](#概述)
- [架构与流程](#架构与流程)
- [文件结构](#文件结构)
- [完整脚本模板](#完整脚本模板)
- [函数参考](#函数参考)
- [高级功能](#高级功能)
- [实际示例](#实际示例)
- [故障排除](#故障排除)
- [贡献检查清单](#贡献检查清单)

---

## 概述

### 目的

容器脚本（`ct/AppName.sh`）是**创建预装特定应用程序的 LXC 容器的入口点**。它们：

1. 定义容器默认值（CPU、RAM、磁盘、操作系统）
2. 调用主构建编排器（`build.func`）
3. 实现应用程序特定的更新机制
4. 提供面向用户的成功消息

### 执行上下文

```
Proxmox 主机
    ↓
ct/AppName.sh sourced（以 root 身份在主机上运行）
    ↓
build.func: 创建 LXC 容器 + 在内部运行安装脚本
    ↓
install/AppName-install.sh（在容器内运行）
    ↓
容器就绪，应用已安装
```

### 关键集成点

- **build.func** - 主编排器（容器创建、存储、变量管理）
- **install.func** - 容器特定设置（操作系统更新、包管理）
- **tools.func** - 工具安装助手（仓库、GitHub 发布）
- **core.func** - UI/消息传递函数（颜色、旋转器、验证）
- **error_handler.func** - 错误处理和信号管理

---

## 架构与流程

### 容器创建流程

```
开始: bash ct/pihole.sh
  ↓
[1] 设置 APP、var_*、默认值
  ↓
[2] header_info() → 显示 ASCII 艺术
  ↓
[3] variables() → 解析参数并加载 build.func
  ↓
[4] color() → 设置 ANSI 代码
  ↓
[5] catch_errors() → 设置陷阱处理程序
  ↓
[6] install_script() → 显示模式菜单（5个选项）
  ↓
  ├─ INSTALL_MODE="0"（默认）
  ├─ INSTALL_MODE="1"（高级 - 19步向导）
  ├─ INSTALL_MODE="2"（用户默认值）
  ├─ INSTALL_MODE="3"（应用默认值）
  └─ INSTALL_MODE="4"（设置菜单）
  ↓
[7] advanced_settings() → 收集用户配置（如果 mode=1）
  ↓
[8] start() → 确认或重新编辑设置
  ↓
[9] build_container() → 创建 LXC + 执行安装脚本
  ↓
[10] description() → 设置容器描述
  ↓
[11] 成功 → 显示访问 URL
  ↓
结束
```

### 默认值优先级

```
优先级 1（最高）: 环境变量（var_cpu、var_ram 等）
优先级 2: 应用特定默认值（/defaults/AppName.vars）
优先级 3: 用户全局默认值（/default.vars）
优先级 4（最低）: 内置默认值（在 build.func 中）
```

---

## 文件结构

### 最小 ct/AppName.sh 模板

```
#!/usr/bin/env bash                          # [1] Shebang
                                             # [2] 版权/许可证
source <(curl -s .../misc/build.func)        # [3] 导入函数
                                             # [4] APP 元数据
APP="AppName"                                # [5] 默认值
var_tags="tag1;tag2"
var_cpu="2"
var_ram="2048"
...

header_info "$APP"                           # [6] 显示标题
variables                                    # [7] 处理参数
color                                        # [8] 设置颜色
catch_errors                                 # [9] 设置错误处理

function update_script() { ... }             # [10] 更新函数（可选）

start                                        # [11] 启动容器创建
build_container
description
msg_ok "Completed successfully!\n"
```

---

## 完整脚本模板

### 1. 文件头和导入

```bash
#!/usr/bin/env bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: YourUsername
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://github.com/example/project

# 导入主编排器
source <(curl -fsSL https://git.community-scripts.org/community-scripts/ProxmoxVE/raw/branch/main/misc/build.func)
```

> **⚠️ 重要**: 在打开 PR 之前，将 URL 更改为 `community-scripts` 仓库！

### 2. 应用程序元数据

```bash
# 应用程序配置
APP="ApplicationName"
var_tags="tag1;tag2;tag3"      # 最多 3-4 个标签，无空格，分号分隔

# 容器资源
var_cpu="2"                    # CPU 核心数
var_ram="2048"                 # RAM（MB）
var_disk="10"                  # 磁盘（GB）

# 容器类型和操作系统
var_os="debian"                # 选项: alpine、debian、ubuntu
var_version="12"               # Alpine: 3.20+、Debian: 11-13、Ubuntu: 20.04+
var_unprivileged="1"           # 1=非特权（安全）、0=特权（很少需要）
```

**变量命名约定**:
- 向用户公开的变量: `var_*`（例如 `var_cpu`、`var_hostname`、`var_ssh`）
- 内部变量: 小写（例如 `container_id`、`app_version`）

### 3. 显示和初始化

```bash
# 显示标题 ASCII 艺术
header_info "$APP"

# 处理命令行参数并加载配置
variables

# 设置 ANSI 颜色代码和格式
color

# 初始化错误处理（trap ERR、EXIT、INT、TERM）
catch_errors
```

### 4. 更新函数（强烈推荐）

```bash
function update_script() {
  header_info

  # 始终从这些检查开始
  check_container_storage
  check_container_resources

  # 验证应用已安装
  if [[ ! -d /opt/appname ]]; then
    msg_error "No ${APP} Installation Found!"
    exit
  fi

  # 从 GitHub 获取最新版本
  RELEASE=$(curl -fsSL https://api.github.com/repos/user/repo/releases/latest | \
    grep "tag_name" | awk '{print substr($2, 2, length($2)-3)}')

  # 与保存的版本比较
  if [[ ! -f /opt/${APP}_version.txt ]] || [[ "${RELEASE}" != "$(cat /opt/${APP}_version.txt)" ]]; then
    msg_info "Updating ${APP} to v${RELEASE}"

    # 备份用户数据
    cp -r /opt/appname /opt/appname-backup

    # 执行更新
    cd /opt
    wget -q "https://github.com/user/repo/releases/download/v${RELEASE}/app-${RELEASE}.tar.gz"
    tar -xzf app-${RELEASE}.tar.gz

    # 恢复用户数据
    cp /opt/appname-backup/config/* /opt/appname/config/

    # 清理
    rm -rf app-${RELEASE}.tar.gz /opt/appname-backup

    # 保存新版本
    echo "${RELEASE}" > /opt/${APP}_version.txt

    msg_ok "Updated ${APP} to v${RELEASE}"
  else
    msg_ok "No update required. ${APP} is already at v${RELEASE}."
  fi

  exit
}
```

### 5. 脚本启动

```bash
# 启动容器创建工作流
start

# 使用选定的配置构建容器
build_container

# 在 Proxmox UI 中设置容器描述/注释
description

# 显示成功消息
msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}:8080${CL}"
```

---

## 函数参考

### 核心函数（来自 build.func）

#### `variables()`

**目的**: 初始化容器变量，加载用户参数，设置编排

**触发方式**: 在脚本启动时自动调用

**行为**:
1. 解析命令行参数（如果有）
2. 生成用于会话跟踪的随机 UUID
3. 从 Proxmox 加载容器存储
4. 初始化应用程序特定的默认值
5. 设置 SSH/环境配置

#### `start()`

**目的**: 启动具有 5 种安装模式的容器创建菜单

**菜单选项**:
```
1. 默认安装（快速设置，预定义设置）
2. 高级安装（19步向导，完全控制）
3. 用户默认值（加载 ~/.community-scripts/default.vars）
4. 应用默认值（加载 /defaults/AppName.vars）
5. 设置菜单（交互式模式选择）
```

#### `build_container()`

**目的**: LXC 容器创建的主编排器

**操作**:
1. 验证所有变量
2. 通过 `pct create` 创建 LXC 容器
3. 在容器内执行 `install/AppName-install.sh`
4. 监控安装进度
5. 处理错误并在失败时回滚

#### `description()`

**目的**: 设置 Proxmox UI 中可见的容器描述/注释

---

## 高级功能

### 1. 自定义配置菜单

如果您的应用程序除了标准变量之外还有其他设置：

```bash
custom_app_settings() {
  CONFIGURE_DB=$(whiptail --title "Database Setup" \
    --yesno "Would you like to configure a custom database?" 8 60)

  if [[ $? -eq 0 ]]; then
    DB_HOST=$(whiptail --inputbox "Database Host:" 8 60 3>&1 1>&2 2>&3)
    DB_PORT=$(whiptail --inputbox "Database Port:" 8 60 "3306" 3>&1 1>&2 2>&3)
  fi
}

custom_app_settings
```

### 2. 更新函数模式

保存已安装的版本以进行更新检查

### 3. 健康检查函数

添加自定义验证：

```bash
function health_check() {
  header_info

  if [[ ! -d /opt/appname ]]; then
    msg_error "Application not found!"
    exit 1
  fi

  if ! systemctl is-active --quiet appname; then
    msg_error "Application service not running"
    exit 1
  fi

  msg_ok "Health check passed"
}
```

---

## 实际示例

### 示例 1: 简单的 Web 应用（基于 Debian）

```bash
#!/usr/bin/env bash
source <(curl -fsSL https://git.community-scripts.org/community-scripts/ProxmoxVE/raw/branch/main/misc/build.func)

APP="Homarr"
var_tags="dashboard;homepage"
var_cpu="2"
var_ram="1024"
var_disk="5"
var_os="debian"
var_version="12"
var_unprivileged="1"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  # 更新逻辑在这里
}

start
build_container
description
msg_ok "Completed successfully!\n"
```

---

## 故障排除

### 容器创建失败

**症状**: `pct create` 以错误代码 209 退出

**解决方案**:
```bash
# 检查现有容器
pct list | grep CTID

# 删除冲突的容器
pct destroy CTID

# 重试 ct/AppName.sh
```

### 更新函数未检测到新版本

**调试**:
```bash
# 检查版本文件
cat /opt/AppName_version.txt

# 测试 GitHub API
curl -fsSL https://api.github.com/repos/user/repo/releases/latest | grep tag_name
```

---

## 贡献检查清单

在提交 PR 之前：

### 脚本结构
- [ ] Shebang 是 `#!/usr/bin/env bash`
- [ ] 从 community-scripts 仓库导入 `build.func`
- [ ] 带有作者和源 URL 的版权标题
- [ ] APP 变量与文件名匹配
- [ ] `var_tags` 是分号分隔的（无空格）

### 默认值
- [ ] `var_cpu` 设置适当（大多数应用为 2-4）
- [ ] `var_ram` 设置适当（最少 1024-4096 MB）
- [ ] `var_disk` 足够用于应用 + 数据（5-20 GB）
- [ ] `var_os` 是现实的

### 函数
- [ ] 实现了 `update_script()`
- [ ] 更新函数检查应用是否已安装
- [ ] 使用 `msg_error` 进行适当的错误处理

### 测试
- [ ] 使用默认安装测试脚本
- [ ] 使用高级（19步）安装测试脚本
- [ ] 在现有安装上测试更新函数

---

## 最佳实践

### ✅ 应该做的:

1. **使用有意义的默认值**
2. **实现版本跟踪**
3. **处理边缘情况**
4. **使用 msg_info/msg_ok/msg_error 进行适当的消息传递**

### ❌ 不应该做的:

1. **硬编码版本**
2. **使用自定义颜色代码**（使用内置变量）
3. **忘记错误处理**
4. **留下临时文件**

---

**最后更新**: 2025年12月
**兼容性**: ProxmoxVE with build.func v3+
