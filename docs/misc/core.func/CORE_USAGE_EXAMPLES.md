# core.func 使用示例

## 概述

本文档提供 `core.func` 函数的实用示例，涵盖常见场景、集成模式和最佳实践。

## 基本脚本设置

### 标准脚本初始化

```bash
#!/usr/bin/env bash
# 使用 core.func 的标准脚本设置

# 引用核心函数
source core.func

# 运行系统检查
pve_check
arch_check
shell_check
root_check

# 可选：检查 SSH 连接
ssh_check

# 设置错误处理
trap 'stop_spinner' EXIT INT TERM

# 您的脚本逻辑在这里
msg_info "正在启动脚本执行"
# ... 脚本代码 ...
msg_ok "脚本成功完成"
```

### 最小脚本设置

```bash
#!/usr/bin/env bash
# 简单脚本的最小设置

source core.func

# 仅基本检查
pve_check
root_check

# 简单执行
msg_info "正在运行操作"
# ... 您的代码 ...
msg_ok "操作完成"
```

## 消息显示示例

### 进度指示

```bash
#!/usr/bin/env bash
source core.func

# 显示带旋转器的进度
msg_info "正在下载包..."
sleep 2
msg_ok "下载完成"

msg_info "正在安装包..."
sleep 3
msg_ok "安装完成"

msg_info "正在配置服务..."
sleep 1
msg_ok "配置完成"
```

### 错误处理

```bash
#!/usr/bin/env bash
source core.func

# 带错误处理的函数
install_package() {
    local package="$1"

    msg_info "正在安装 $package..."

    if silent apt-get install -y "$package"; then
        msg_ok "$package 安装成功"
        return 0
    else
        msg_error "安装 $package 失败"
        return 1
    fi
}

# 使用
if install_package "nginx"; then
    msg_ok "Nginx 安装完成"
else
    msg_error "Nginx 安装失败"
    exit 1
fi
```

### 警告消息

```bash
#!/usr/bin/env bash
source core.func

# 显示潜在危险操作的警告
msg_warn "这将修改系统配置"
read -p "继续？[y/N]：" confirm

if [[ "$confirm" =~ ^[yY]$ ]]; then
    msg_info "正在进行修改..."
    # ... 危险操作 ...
    msg_ok "修改完成"
else
    msg_info "操作已取消"
fi
```

### 自定义消息

```bash
#!/usr/bin/env bash
source core.func

# 带特定图标和颜色的自定义消息
msg_custom "🚀" "\e[32m" "正在启动应用程序"
msg_custom "⚡" "\e[33m" "高性能模式已启用"
msg_custom "🔒" "\e[31m" "安全模式已激活"
```

### 调试消息

```bash
#!/usr/bin/env bash
source core.func

# 启用调试模式
export var_full_verbose=1

# 调试消息
msg_debug "变量值：$some_variable"
msg_debug "调用的函数：$FUNCNAME"
msg_debug "当前目录：$(pwd)"
```

## 静默执行示例

### 包管理

```bash
#!/usr/bin/env bash
source core.func

# 更新包列表
msg_info "正在更新包列表..."
silent apt-get update

# 安装包
msg_info "正在安装必需的包..."
silent apt-get install -y curl wget git

# 升级包
msg_info "正在升级包..."
silent apt-get upgrade -y

msg_ok "包管理完成"
```

### 文件操作

```bash
#!/usr/bin/env bash
source core.func

# 创建目录
msg_info "正在创建目录结构..."
silent mkdir -p /opt/myapp/{config,logs,data}

# 设置权限
msg_info "正在设置权限..."
silent chmod 755 /opt/myapp
silent chmod 644 /opt/myapp/config/*

# 复制文件
msg_info "正在复制配置文件..."
silent cp config/* /opt/myapp/config/

msg_ok "文件操作完成"
```

### 服务管理

```bash
#!/usr/bin/env bash
source core.func

# 启动服务
msg_info "正在启动服务..."
silent systemctl start myservice

# 启用服务
msg_info "正在启用服务..."
silent systemctl enable myservice

# 检查服务状态
msg_info "正在检查服务状态..."
if silent systemctl is-active --quiet myservice; then
    msg_ok "服务正在运行"
else
    msg_error "服务启动失败"
fi
```

### 网络操作

```bash
#!/usr/bin/env bash
source core.func

# 测试网络连接
msg_info "正在测试网络连接..."
if silent ping -c 1 8.8.8.8; then
    msg_ok "网络连接已确认"
else
    msg_error "网络连接失败"
fi

# 下载文件
msg_info "正在下载配置..."
silent curl -fsSL https://example.com/config -o /tmp/config

# 提取存档
msg_info "正在提取存档..."
silent tar -xzf /tmp/archive.tar.gz -C /opt/
```

## 系统检查示例

### 全面系统验证

```bash
#!/usr/bin/env bash
source core.func

# 完整系统验证
validate_system() {
    msg_info "正在验证系统要求..."

    # 检查 Proxmox 版本
    if pve_check; then
        msg_ok "Proxmox VE 版本受支持"
    fi

    # 检查架构
    if arch_check; then
        msg_ok "系统架构受支持"
    fi

    # 检查 shell
    if shell_check; then
        msg_ok "Shell 环境正确"
    fi

    # 检查权限
    if root_check; then
        msg_ok "以足够权限运行"
    fi

    # 检查 SSH 连接
    ssh_check

    msg_ok "系统验证完成"
}

# 运行验证
validate_system
```

### 条件系统检查

```bash
#!/usr/bin/env bash
source core.func

# 检查是否在容器中运行
if [[ -f /.dockerenv ]] || [[ -f /run/.containerenv ]]; then
    msg_warn "在容器内运行"
    # 跳过某些检查
else
    # 完整系统检查
    pve_check
    arch_check
fi

# 始终检查 shell 和权限
shell_check
root_check
```

## 头部管理示例

### 应用程序头部显示

```bash
#!/usr/bin/env bash
source core.func

# 设置应用程序信息
export APP="plex"
export APP_TYPE="ct"

# 显示头部
header_info

# 继续应用程序设置
msg_info "正在设置 Plex Media Server..."
```

### 自定义头部处理

```bash
#!/usr/bin/env bash
source core.func

# 获取头部内容
export APP="nextcloud"
export APP_TYPE="ct"

header_content=$(get_header)
if [[ -n "$header_content" ]]; then
    echo "找到头部："
    echo "$header_content"
else
    msg_warn "未找到 $APP 的头部"
fi
```

## 交换管理示例

### 交互式交换创建

```bash
#!/usr/bin/env bash
source core.func

# 检查并创建交换
if check_or_create_swap; then
    msg_ok "交换可用"
else
    msg_warn "交换不可用 - 继续无交换"
fi
```

### 自动交换检查

```bash
#!/usr/bin/env bash
source core.func

# 不提示检查交换
check_swap_quiet() {
    if swapon --noheadings --show | grep -q 'swap'; then
        msg_ok "交换处于活动状态"
        return 0
    else
        msg_warn "未检测到活动交换"
        return 1
    fi
}

if check_swap_quiet; then
    msg_info "系统有足够的交换"
else
    msg_warn "考虑添加交换以获得更好的性能"
fi
```

## 旋转器使用示例

### 长时间运行的操作

```bash
#!/usr/bin/env bash
source core.func

# 带旋转器的长时间运行操作
long_operation() {
    msg_info "正在处理大型数据集..."

    # 模拟长操作
    for i in {1..100}; do
        sleep 0.1
        # 定期更新旋转器消息
        if (( i % 20 == 0 )); then
            SPINNER_MSG="正在处理... $i%"
        fi
    done

    msg_ok "数据集处理完成"
}

long_operation
```

### 后台操作

```bash
#!/usr/bin/env bash
source core.func

# 带旋转器的后台操作
background_operation() {
    msg_info "正在启动后台进程..."

    # 启动旋转器
    SPINNER_MSG="正在后台处理..."
    spinner &
    SPINNER_PID=$!

    # 执行后台工作
    sleep 5

    # 停止旋转器
    stop_spinner
    msg_ok "后台进程完成"
}

background_operation
```

## 集成示例

### 与 build.func 集成

```bash
#!/usr/bin/env bash
# 与 build.func 集成

source core.func
source build.func

# 使用核心函数进行系统验证
pve_check
arch_check
root_check

# 使用 build.func 创建容器
export APP="plex"
export CTID="100"
# ... 容器创建 ...
```

### 与 tools.func 集成

```bash
#!/usr/bin/env bash
# 与 tools.func 集成

source core.func
source tools.func

# 使用核心函数的 UI
msg_info "正在启动维护任务..."

# 使用 tools.func 进行维护
update_system
cleanup_logs
optimize_storage

msg_ok "维护完成"
```

### 与 error_handler.func 集成

```bash
#!/usr/bin/env bash
# 与 error_handler.func 集成

source core.func
source error_handler.func

# 使用核心函数执行
msg_info "正在运行操作..."

# 静默执行将使用 error_handler 进行说明
silent apt-get install -y package

msg_ok "操作完成"
```

## 最佳实践示例

### 错误处理模式

```bash
#!/usr/bin/env bash
source core.func

# 健壮的错误处理
run_with_error_handling() {
    local operation="$1"
    local description="$2"

    msg_info "$description"

    if silent "$operation"; then
        msg_ok "$description 成功完成"
        return 0
    else
        msg_error "$description 失败"
        return 1
    fi
}

# 使用
run_with_error_handling "apt-get update" "包列表更新"
run_with_error_handling "apt-get install -y nginx" "Nginx 安装"
```

### 详细模式处理

```bash
#!/usr/bin/env bash
source core.func

# 处理详细模式
if is_verbose_mode; then
    msg_info "详细模式已启用 - 显示详细输出"
    # 显示更多信息
else
    msg_info "正常模式 - 显示最少输出"
    # 显示较少信息
fi
```

### Alpine Linux 检测

```bash
#!/usr/bin/env bash
source core.func

# 处理不同的 OS 类型
if is_alpine; then
    msg_info "检测到 Alpine Linux"
    # 使用 Alpine 特定命令
    silent apk add --no-cache package
else
    msg_info "检测到基于 Debian 的系统"
    # 使用 Debian 特定命令
    silent apt-get install -y package
fi
```

### 条件执行

```bash
#!/usr/bin/env bash
source core.func

# 基于系统状态的条件执行
if [[ -f /etc/nginx/nginx.conf ]]; then
    msg_warn "Nginx 配置已存在"
    read -p "覆盖？[y/N]：" overwrite
    if [[ "$overwrite" =~ ^[yY]$ ]]; then
        msg_info "正在覆盖配置..."
        # ... 覆盖逻辑 ...
    else
        msg_info "跳过配置"
    fi
else
    msg_info "正在创建新的 Nginx 配置..."
    # ... 创建逻辑 ...
fi
```

## 高级使用示例

### 自定义旋转器消息

```bash
#!/usr/bin/env bash
source core.func

# 带进度的自定义旋转器
download_with_progress() {
    local url="$1"
    local file="$2"

    msg_info "正在开始下载..."

    # 启动旋转器
    SPINNER_MSG="正在下载..."
    spinner &
    SPINNER_PID=$!

    # 带进度下载
    curl -L "$url" -o "$file" --progress-bar

    # 停止旋转器
    stop_spinner
    msg_ok "下载完成"
}

download_with_progress "https://example.com/file.tar.gz" "/tmp/file.tar.gz"
```

### 消息去重

```bash
#!/usr/bin/env bash
source core.func

# 消息自动去重
for i in {1..5}; do
    msg_info "正在处理项目 $i"
    # 此消息只会显示一次
done

# 不同的消息将分别显示
msg_info "正在启动阶段 1"
msg_info "正在启动阶段 2"
msg_info "正在启动阶段 3"
```

### 终端控制

```bash
#!/usr/bin/env bash
source core.func

# 确保终端控制可用
ensure_tput

# 使用终端控制
clear_line
echo "此行将被清除"
clear_line
echo "新内容"
```

## 故障排除示例

### 调试模式

```bash
#!/usr/bin/env bash
source core.func

# 启用调试模式
export var_full_verbose=1
export VERBOSE="yes"

# 调试信息
msg_debug "脚本已启动"
msg_debug "当前用户：$(whoami)"
msg_debug "当前目录：$(pwd)"
msg_debug "环境变量：$(env | grep -E '^(APP|CTID|VERBOSE)')"
```

### 静默执行调试

```bash
#!/usr/bin/env bash
source core.func

# 调试静默执行
debug_silent() {
    local cmd="$1"
    local log_file="/tmp/debug.$$.log"

    echo "命令：$cmd" > "$log_file"
    echo "时间戳：$(date)" >> "$log_file"
    echo "工作目录：$(pwd)" >> "$log_file"
    echo "环境：" >> "$log_file"
    env >> "$log_file"
    echo "--- 命令输出 ---" >> "$log_file"

    if silent "$cmd"; then
        msg_ok "命令成功"
    else
        msg_error "命令失败 - 检查 $log_file 以获取详细信息"
    fi
}

debug_silent "apt-get update"
```

### 错误恢复

```bash
#!/usr/bin/env bash
source core.func

# 错误恢复模式
retry_operation() {
    local max_attempts=3
    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        msg_info "尝试 $attempt / $max_attempts"

        if silent "$@"; then
            msg_ok "操作在尝试 $attempt 时成功"
            return 0
        else
            msg_warn "尝试 $attempt 失败"
            ((attempt++))

            if [[ $attempt -le $max_attempts ]]; then
                msg_info "5 秒后重试..."
                sleep 5
            fi
        fi
    done

    msg_error "操作在 $max_attempts 次尝试后失败"
    return 1
}

# 使用
retry_operation "apt-get install -y package"
```
