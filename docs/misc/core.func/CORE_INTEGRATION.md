# core.func 集成指南

## 概述

本文档描述 `core.func` 如何与 Proxmox Community Scripts 项目中的其他组件集成，包括依赖关系、数据流和 API 接口。

## 依赖关系

### 外部依赖

#### 必需命令
- **`pveversion`**：Proxmox VE 版本检查
- **`dpkg`**：架构检测
- **`ps`**：进程和 shell 检测
- **`id`**：用户 ID 检查
- **`curl`**：头文件下载
- **`swapon`**：交换状态检查
- **`dd`**：交换文件创建
- **`mkswap`**：交换文件格式化

#### 可选命令
- **`tput`**：终端控制（如缺失则安装）
- **`apk`**：Alpine 包管理器
- **`apt-get`**：Debian 包管理器

### 内部依赖

#### error_handler.func
- **目的**：为静默执行提供错误代码说明
- **使用**：当 `silent()` 遇到错误时自动加载
- **集成**：通过 `explain_exit_code()` 函数调用
- **数据流**：错误代码 → 说明 → 用户显示

## 集成点

### 与 build.func 集成

#### 系统验证
```bash
# build.func 使用 core.func 进行系统检查
source core.func
pve_check
arch_check
shell_check
root_check
```

#### 用户界面
```bash
# build.func 使用 core.func 的 UI 元素
msg_info "正在创建容器..."
msg_ok "容器创建成功"
msg_error "容器创建失败"
```

#### 静默执行
```bash
# build.func 使用 core.func 执行命令
silent pct create "$CTID" "$TEMPLATE" \
    --hostname "$HOSTNAME" \
    --memory "$MEMORY" \
    --cores "$CORES"
```

### 与 tools.func 集成

#### 实用函数
```bash
# tools.func 使用 core.func 实用工具
source core.func

# 系统检查
pve_check
root_check

# UI 元素
msg_info "正在运行维护任务..."
msg_ok "维护完成"
```

#### 错误处理
```bash
# tools.func 使用 core.func 进行错误处理
if silent systemctl restart service; then
    msg_ok "服务已重启"
else
    msg_error "服务重启失败"
fi
```

### 与 api.func 集成

#### 系统验证
```bash
# api.func 使用 core.func 进行系统检查
source core.func
pve_check
root_check
```

#### API 操作
```bash
# api.func 使用 core.func 进行 API 调用
msg_info "正在连接到 Proxmox API..."
if silent curl -k -H "Authorization: PVEAPIToken=$API_TOKEN" \
    "$API_URL/api2/json/nodes/$NODE/lxc"; then
    msg_ok "API 连接成功"
else
    msg_error "API 连接失败"
fi
```

### 与 error_handler.func 集成

#### 错误说明
```bash
# error_handler.func 为 core.func 提供说明
explain_exit_code() {
    local code="$1"
    case "$code" in
        1) echo "一般错误" ;;
        2) echo "shell 内置命令误用" ;;
        126) echo "调用的命令无法执行" ;;
        127) echo "命令未找到" ;;
        128) echo "exit 的参数无效" ;;
        *) echo "未知错误代码" ;;
    esac
}
```

### 与 install.func 集成

#### 安装过程
```bash
# install.func 使用 core.func 进行安装
source core.func

# 系统检查
pve_check
root_check

# 安装步骤
msg_info "正在安装包..."
silent apt-get update
silent apt-get install -y package

msg_ok "安装完成"
```

### 与 alpine-install.func 集成

#### Alpine 特定操作
```bash
# alpine-install.func 使用 core.func 进行 Alpine 操作
source core.func

# Alpine 检测
if is_alpine; then
    msg_info "检测到 Alpine Linux"
    silent apk add --no-cache package
else
    msg_info "检测到基于 Debian 的系统"
    silent apt-get install -y package
fi
```

### 与 alpine-tools.func 集成

#### Alpine 实用工具
```bash
# alpine-tools.func 使用 core.func 的 Alpine 工具
source core.func

# Alpine 特定操作
if is_alpine; then
    msg_info "正在运行 Alpine 特定操作..."
    # Alpine 工具逻辑
    msg_ok "Alpine 操作完成"
fi
```

### 与 passthrough.func 集成

#### 硬件直通
```bash
# passthrough.func 使用 core.func 进行硬件操作
source core.func

# 系统检查
pve_check
root_check

# 硬件操作
msg_info "正在配置 GPU 直通..."
if silent lspci | grep -i nvidia; then
    msg_ok "检测到 NVIDIA GPU"
else
    msg_warn "未找到 NVIDIA GPU"
fi
```

### 与 vm-core.func 集成

#### VM 操作
```bash
# vm-core.func 使用 core.func 进行 VM 管理
source core.func

# 系统检查
pve_check
root_check

# VM 操作
msg_info "正在创建虚拟机..."
silent qm create "$VMID" \
    --name "$VMNAME" \
    --memory "$MEMORY" \
    --cores "$CORES"

msg_ok "虚拟机已创建"
```

## 数据流

### 输入数据

#### 环境变量
- **`APP`**：头部显示的应用程序名称
- **`APP_TYPE`**：头部路径的应用程序类型（ct/vm）
- **`VERBOSE`**：详细模式设置
- **`var_os`**：Alpine 检测的 OS 类型
- **`PCT_OSTYPE`**：替代 OS 类型变量
- **`var_verbose`**：替代详细设置
- **`var_full_verbose`**：调试模式设置

#### 命令参数
- **函数参数**：传递给各个函数
- **命令参数**：传递给 `silent()` 函数
- **用户输入**：通过 `read` 命令收集

### 处理数据

#### 系统信息
- **Proxmox 版本**：从 `pveversion` 输出解析
- **架构**：从 `dpkg --print-architecture` 获取
- **Shell 类型**：从进程信息检测
- **用户 ID**：从 `id -u` 获取
- **SSH 连接**：从 `SSH_CLIENT` 环境检测

#### UI 状态
- **消息跟踪**：`MSG_INFO_SHOWN` 关联数组
- **旋转器状态**：`SPINNER_PID` 和 `SPINNER_MSG` 变量
- **终端状态**：光标位置和显示模式

#### 错误信息
- **退出代码**：从命令执行捕获
- **日志输出**：重定向到临时日志文件
- **错误说明**：从 error_handler.func 获取

### 输出数据

#### 用户界面
- **彩色消息**：终端输出的 ANSI 颜色代码
- **图标**：不同消息类型的符号表示
- **旋转器**：动画进度指示器
- **格式化文本**：一致的消息格式

#### 系统状态
- **退出代码**：从函数返回
- **日志文件**：为静默执行创建
- **配置**：修改的系统设置
- **进程状态**：旋转器进程和清理

## API 接口

### 公共函数

#### 系统验证
- **`pve_check()`**：Proxmox VE 版本验证
- **`arch_check()`**：架构验证
- **`shell_check()`**：Shell 验证
- **`root_check()`**：权限验证
- **`ssh_check()`**：SSH 连接警告

#### 用户界面
- **`msg_info()`**：信息消息
- **`msg_ok()`**：成功消息
- **`msg_error()`**：错误消息
- **`msg_warn()`**：警告消息
- **`msg_custom()`**：自定义消息
- **`msg_debug()`**：调试消息

#### 旋转器控制
- **`spinner()`**：启动旋转器动画
- **`stop_spinner()`**：停止旋转器并清理
- **`clear_line()`**：清除当前终端行

#### 静默执行
- **`silent()`**：使用错误处理执行命令

#### 实用函数
- **`is_alpine()`**：Alpine Linux 检测
- **`is_verbose_mode()`**：详细模式检测
- **`fatal()`**：致命错误处理
- **`ensure_tput()`**：终端控制设置

#### 头部管理
- **`get_header()`**：下载应用程序头部
- **`header_info()`**：显示头部信息

#### 系统管理
- **`check_or_create_swap()`**：交换文件管理

### 内部函数

#### 初始化
- **`load_functions()`**：函数加载器
- **`color()`**：颜色设置
- **`formatting()`**：格式化设置
- **`icons()`**：图标设置
- **`default_vars()`**：默认变量
- **`set_std_mode()`**：标准模式设置

#### 颜色管理
- **`color_spinner()`**：旋转器颜色

### 全局变量

#### 颜色变量
- **`YW`**、**`YWB`**、**`BL`**、**`RD`**、**`BGN`**、**`GN`**、**`DGN`**、**`CL`**：颜色代码
- **`CS_YW`**、**`CS_YWB`**、**`CS_CL`**：旋转器颜色

#### 格式化变量
- **`BFR`**、**`BOLD`**、**`HOLD`**、**`TAB`**、**`TAB3`**：格式化助手

#### 图标变量
- **`CM`**、**`CROSS`**、**`INFO`**、**`OS`**、**`OSVERSION`** 等：消息图标

#### 配置变量
- **`RETRY_NUM`**、**`RETRY_EVERY`**：重试设置
- **`STD`**：标准模式设置
- **`SILENT_LOGFILE`**：日志文件路径

#### 状态变量
- **`_CORE_FUNC_LOADED`**：加载防止
- **`__FUNCTIONS_LOADED`**：函数加载防止
- **`SPINNER_PID`**、**`SPINNER_MSG`**：旋转器状态
- **`MSG_INFO_SHOWN`**：消息跟踪

## 集成模式

### 标准集成模式

```bash
#!/usr/bin/env bash
# 标准集成模式

# 1. 首先引用 core.func
source core.func

# 2. 运行系统检查
pve_check
arch_check
shell_check
root_check

# 3. 设置错误处理
trap 'stop_spinner' EXIT INT TERM

# 4. 使用 UI 函数
msg_info "正在启动操作..."

# 5. 使用静默执行
silent command

# 6. 显示完成
msg_ok "操作完成"
```

### 最小集成模式

```bash
#!/usr/bin/env bash
# 最小集成模式

source core.func
pve_check
root_check

msg_info "正在运行操作..."
silent command
msg_ok "操作完成"
```

### 高级集成模式

```bash
#!/usr/bin/env bash
# 高级集成模式

source core.func

# 系统验证
pve_check
arch_check
shell_check
root_check
ssh_check

# 错误处理
trap 'stop_spinner' EXIT INT TERM

# 详细模式处理
if is_verbose_mode; then
    msg_info "详细模式已启用"
fi

# OS 特定操作
if is_alpine; then
    msg_info "检测到 Alpine Linux"
    # Alpine 特定逻辑
else
    msg_info "检测到基于 Debian 的系统"
    # Debian 特定逻辑
fi

# 操作执行
msg_info "正在启动操作..."
if silent command; then
    msg_ok "操作成功"
else
    msg_error "操作失败"
    exit 1
fi
```

## 错误处理集成

### 静默执行错误流程

```
silent() 命令
├── 执行命令
├── 捕获输出到日志
├── 检查退出代码
├── 如果错误：
│   ├── 加载 error_handler.func
│   ├── 获取错误说明
│   ├── 显示错误详情
│   ├── 显示日志摘录
│   └── 以错误代码退出
└── 如果成功：继续
```

### 系统检查错误流程

```
系统检查函数
├── 检查系统状态
├── 如果有效：返回 0
└── 如果无效：
    ├── 显示错误消息
    ├── 显示修复说明
    ├── 休眠以便用户阅读
    └── 以错误代码退出
```

## 性能考虑

### 加载优化
- **单次加载**：`_CORE_FUNC_LOADED` 防止多次加载
- **函数加载**：`__FUNCTIONS_LOADED` 防止多次函数加载
- **延迟加载**：仅在需要时加载函数

### 内存使用
- **最小占用**：核心函数使用最少内存
- **变量重用**：全局变量在函数间重用
- **清理**：退出时清理旋转器进程

### 执行速度
- **快速检查**：系统检查针对速度优化
- **高效旋转器**：旋转器动画使用最少 CPU
- **快速消息**：消息函数针对性能优化

## 安全考虑

### 权限提升
- **Root 检查**：确保脚本以足够权限运行
- **Shell 检查**：验证 shell 环境
- **进程验证**：检查父进程的 sudo 使用

### 输入验证
- **参数检查**：函数验证输入参数
- **错误处理**：适当的错误处理防止崩溃
- **安全执行**：使用适当错误处理的静默执行

### 系统保护
- **版本验证**：确保兼容的 Proxmox 版本
- **架构检查**：防止在不支持的系统上执行
- **SSH 警告**：警告外部 SSH 使用

## 未来集成考虑

### 可扩展性
- **函数组**：易于添加新函数组
- **消息类型**：易于添加新消息类型
- **系统检查**：易于添加新系统检查

### 兼容性
- **版本支持**：易于添加新 Proxmox 版本
- **OS 支持**：易于添加新操作系统
- **架构支持**：易于添加新架构

### 性能
- **优化**：函数可以优化以获得更好的性能
- **缓存**：结果可以缓存以进行重复操作
- **并行化**：操作可以在适当的地方并行化
