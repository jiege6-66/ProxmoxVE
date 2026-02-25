# error_handler.func 使用示例

## 概述

本文档提供 `error_handler.func` 函数的实际使用示例，涵盖常见场景、集成模式和最佳实践。

## 基本错误处理设置

### 标准脚本初始化

```bash
#!/usr/bin/env bash
# 标准错误处理设置

# 引入错误处理器
source error_handler.func

# 初始化错误处理
catch_errors

# 你的脚本代码
# 所有错误将被自动捕获和处理
echo "Script running..."
apt-get update
apt-get install -y package
echo "Script completed successfully"
```

### 最小化错误处理

```bash
#!/usr/bin/env bash
# 最小化错误处理设置

source error_handler.func
catch_errors

# 带错误处理的简单脚本
echo "Starting operation..."
command_that_might_fail
echo "Operation completed"
```

## 错误码说明示例

### 基本错误说明

```bash
#!/usr/bin/env bash
source error_handler.func

# 说明常见错误码
echo "Error 1: $(explain_exit_code 1)"
echo "Error 127: $(explain_exit_code 127)"
echo "Error 130: $(explain_exit_code 130)"
echo "Error 200: $(explain_exit_code 200)"
```

### 错误码测试

```bash
#!/usr/bin/env bash
source error_handler.func

# 测试所有错误码
test_error_codes() {
    local codes=(1 2 126 127 128 130 137 139 143 100 101 255 200 203 204 205)

    for code in "${codes[@]}"; do
        echo "Code $code: $(explain_exit_code $code)"
    done
}

test_error_codes
```

### 自定义错误码使用

```bash
#!/usr/bin/env bash
source error_handler.func

# 使用自定义错误码
check_requirements() {
    if [[ ! -f /required/file ]]; then
        echo "Error: Required file missing"
        exit 200  # 自定义错误码
    fi

    if [[ -z "$CTID" ]]; then
        echo "Error: CTID not set"
        exit 203  # 自定义错误码
    fi

    if [[ $CTID -lt 100 ]]; then
        echo "Error: Invalid CTID"
        exit 205  # 自定义错误码
    fi
}

check_requirements
```

## 信号处理示例

### 中断处理

```bash
#!/usr/bin/env bash
source error_handler.func

# 设置中断处理器
trap on_interrupt INT

echo "Script running... Press Ctrl+C to interrupt"
sleep 10
echo "Script completed normally"
```

### 终止处理

```bash
#!/usr/bin/env bash
source error_handler.func

# 设置终止处理器
trap on_terminate TERM

echo "Script running... Send SIGTERM to terminate"
sleep 10
echo "Script completed normally"
```

### 完整信号处理

```bash
#!/usr/bin/env bash
source error_handler.func

# 设置所有信号处理器
trap on_interrupt INT
trap on_terminate TERM
trap on_exit EXIT

echo "Script running with full signal handling"
sleep 10
echo "Script completed normally"
```

## 清理示例

### 锁文件清理

```bash
#!/usr/bin/env bash
source error_handler.func

# 设置锁文件
lockfile="/tmp/my_script.lock"
touch "$lockfile"

# 设置退出处理器
trap on_exit EXIT

echo "Script running with lock file..."
sleep 5
echo "Script completed - lock file will be removed"
```

### 临时文件清理

```bash
#!/usr/bin/env bash
source error_handler.func

# 创建临时文件
temp_file1="/tmp/temp1.$$"
temp_file2="/tmp/temp2.$$"
touch "$temp_file1" "$temp_file2"

# 设置清理
cleanup() {
    rm -f "$temp_file1" "$temp_file2"
    echo "Temporary files cleaned up"
}

trap cleanup EXIT

echo "Script running with temporary files..."
sleep 5
echo "Script completed - temporary files will be cleaned up"
```

## 调试日志示例

### 基本调试日志

```bash
#!/usr/bin/env bash
source error_handler.func

# 启用调试日志
export DEBUG_LOGFILE="/tmp/debug.log"
catch_errors

echo "Script with debug logging"
apt-get update
apt-get install -y package
```

### 调试日志分析

```bash
#!/usr/bin/env bash
source error_handler.func

# 启用调试日志
export DEBUG_LOGFILE="/tmp/debug.log"
catch_errors

# 分析调试日志的函数
analyze_debug_log() {
    if [[ -f "$DEBUG_LOGFILE" ]]; then
        echo "Debug log analysis:"
        echo "Total errors: $(grep -c "ERROR" "$DEBUG_LOGFILE")"
        echo "Recent errors:"
        tail -n 5 "$DEBUG_LOGFILE"
    else
        echo "No debug log found"
    fi
}

# 运行脚本
echo "Running script..."
apt-get update

# 分析结果
analyze_debug_log
```

## 静默执行集成

### 与 core.func 静默执行集成

```bash
#!/usr/bin/env bash
source core.func
source error_handler.func

# 带错误处理的静默执行
echo "Installing packages..."
silent apt-get update
silent apt-get install -y nginx

echo "Configuring service..."
silent systemctl enable nginx
silent systemctl start nginx

echo "Installation completed"
```

### 静默执行错误处理

```bash
#!/usr/bin/env bash
source core.func
source error_handler.func

# 带静默执行和错误处理的函数
install_package() {
    local package="$1"

    echo "Installing $package..."
    if silent apt-get install -y "$package"; then
        echo "$package installed successfully"
        return 0
    else
        echo "Failed to install $package"
        return 1
    fi
}

# 安装多个包
packages=("nginx" "apache2" "mysql-server")
for package in "${packages[@]}"; do
    if ! install_package "$package"; then
        echo "Stopping installation due to error"
        exit 1
    fi
done
```

## 高级错误处理示例

### 条件错误处理

```bash
#!/usr/bin/env bash
source error_handler.func

# 基于环境的条件错误处理
setup_error_handling() {
    if [[ "${STRICT_MODE:-0}" == "1" ]]; then
        echo "Enabling strict mode"
        export STRICT_UNSET=1
    fi

    catch_errors
    echo "Error handling configured"
}

setup_error_handling
```

### 错误恢复

```bash
#!/usr/bin/env bash
source error_handler.func

# 错误恢复模式
retry_operation() {
    local max_attempts=3
    local attempt=1

    while [[ $attempt -le $max_attempts ]]; do
        echo "Attempt $attempt of $max_attempts"

        if silent "$@"; then
            echo "Operation succeeded on attempt $attempt"
            return 0
        else
            echo "Attempt $attempt failed"
            ((attempt++))

            if [[ $attempt -le $max_attempts ]]; then
                echo "Retrying in 5 seconds..."
                sleep 5
            fi
        fi
    done

    echo "Operation failed after $max_attempts attempts"
    return 1
}

# 使用重试模式
retry_operation apt-get update
retry_operation apt-get install -y package
```

### 自定义错误处理器

```bash
#!/usr/bin/env bash
source error_handler.func

# 针对特定操作的自定义错误处理器
custom_error_handler() {
    local exit_code=${1:-$?}
    local command=${2:-${BASH_COMMAND:-unknown}}

    case "$exit_code" in
        127)
            echo "Custom handling: Command not found - $command"
            echo "Suggestions:"
            echo "1. Check if the command is installed"
            echo "2. Check if the command is in PATH"
            echo "3. Check spelling"
            ;;
        126)
            echo "Custom handling: Permission denied - $command"
            echo "Suggestions:"
            echo "1. Check file permissions"
            echo "2. Run with appropriate privileges"
            echo "3. Check if file is executable"
            ;;
        *)
            # 使用默认错误处理器
            error_handler "$exit_code" "$command"
            ;;
    esac
}

# 设置自定义错误处理器
trap 'custom_error_handler' ERR

# 测试自定义错误处理
nonexistent_command
```

## 集成示例

### 与 build.func 集成

```bash
#!/usr/bin/env bash
# 与 build.func 集成

source core.func
source error_handler.func
source build.func

# 带错误处理的容器创建
export APP="plex"
export CTID="100"

# 错误将被捕获并说明
# 静默执行将使用 error_handler 进行说明
```

### 与 tools.func 集成

```bash
#!/usr/bin/env bash
# 与 tools.func 集成

source core.func
source error_handler.func
source tools.func

# 带错误处理的工具操作
# 所有错误都被正确处理和说明
```

### 与 api.func 集成

```bash
#!/usr/bin/env bash
# 与 api.func 集成

source core.func
source error_handler.func
source api.func

# 带错误处理的 API 操作
# 网络错误和 API 错误都被正确处理
```

## 最佳实践示例

### 综合错误处理

```bash
#!/usr/bin/env bash
# 综合错误处理示例

source error_handler.func

# 设置综合错误处理
setup_comprehensive_error_handling() {
    # 启用调试日志
    export DEBUG_LOGFILE="/tmp/script_debug.log"

    # 设置锁文件
    lockfile="/tmp/script.lock"
    touch "$lockfile"

    # 初始化错误处理
    catch_errors

    # 设置信号处理器
    trap on_interrupt INT
    trap on_terminate TERM
    trap on_exit EXIT

    echo "Comprehensive error handling configured"
}

setup_comprehensive_error_handling

# 脚本操作
echo "Starting script operations..."
# ... 脚本代码 ...
echo "Script operations completed"
```

### 不同场景的错误处理

```bash
#!/usr/bin/env bash
source error_handler.func

# 针对不同场景的不同错误处理
handle_package_errors() {
    local exit_code=$1
    case "$exit_code" in
        100)
            echo "Package manager error - trying to fix..."
            apt-get --fix-broken install
            ;;
        101)
            echo "Configuration error - checking sources..."
            apt-get update
            ;;
        *)
            error_handler "$exit_code"
            ;;
    esac
}

handle_network_errors() {
    local exit_code=$1
    case "$exit_code" in
        127)
            echo "Network command not found - checking connectivity..."
            ping -c 1 8.8.8.8
            ;;
        *)
            error_handler "$exit_code"
            ;;
    esac
}

# 使用适当的错误处理器
if [[ "$1" == "package" ]]; then
    trap 'handle_package_errors $?' ERR
elif [[ "$1" == "network" ]]; then
    trap 'handle_network_errors $?' ERR
else
    catch_errors
fi
```

### 带日志的错误处理

```bash
#!/usr/bin/env bash
source error_handler.func

# 带详细日志的错误处理
setup_logging_error_handling() {
    # 创建日志目录
    mkdir -p /var/log/script_errors

    # 设置调试日志
    export DEBUG_LOGFILE="/var/log/script_errors/debug.log"

    # 设置静默日志
    export SILENT_LOGFILE="/var/log/script_errors/silent.log"

    # 初始化错误处理
    catch_errors

    echo "Logging error handling configured"
}

setup_logging_error_handling

# 带日志的脚本操作
echo "Starting logged operations..."
# ... 脚本代码 ...
echo "Logged operations completed"
```

## 故障排除示例

### 调试模式

```bash
#!/usr/bin/env bash
source error_handler.func

# 启用调试模式
export DEBUG_LOGFILE="/tmp/debug.log"
export STRICT_UNSET=1

catch_errors

echo "Debug mode enabled"
# 脚本操作
```

### 错误分析

```bash
#!/usr/bin/env bash
source error_handler.func

# 分析错误的函数
analyze_errors() {
    local log_file="${1:-$DEBUG_LOGFILE}"

    if [[ -f "$log_file" ]]; then
        echo "Error Analysis:"
        echo "Total errors: $(grep -c "ERROR" "$log_file")"
        echo "Error types:"
        grep "ERROR" "$log_file" | awk '{print $NF}' | sort | uniq -c
        echo "Recent errors:"
        tail -n 10 "$log_file"
    else
        echo "No error log found"
    fi
}

# 运行带错误分析的脚本
analyze_errors
```

### 错误恢复测试

```bash
#!/usr/bin/env bash
source error_handler.func

# 测试错误恢复
test_error_recovery() {
    local test_cases=(
        "nonexistent_command"
        "apt-get install nonexistent_package"
        "systemctl start nonexistent_service"
    )

    for test_case in "${test_cases[@]}"; do
        echo "Testing: $test_case"
        if silent $test_case; then
            echo "Unexpected success"
        else
            echo "Expected failure handled"
        fi
    done
}

test_error_recovery
```
