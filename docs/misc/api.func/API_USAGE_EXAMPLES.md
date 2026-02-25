# api.func 使用示例

## 概述

本文档提供 `api.func` 函数的实用使用示例，涵盖常见场景、集成模式和最佳实践。

## 基本 API 设置

### 标准 API 初始化

```bash
#!/usr/bin/env bash
# LXC 容器的标准 API 设置

source api.func

# 设置诊断报告
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"

# 设置容器参数
export CT_TYPE=1
export DISK_SIZE=8
export CORE_COUNT=2
export RAM_SIZE=2048
export var_os="debian"
export var_version="12"
export NSAPP="plex"
export METHOD="install"

# 报告安装开始
post_to_api

# 您的安装代码在这里
# ... 安装逻辑 ...

# 报告完成
if [[ $? -eq 0 ]]; then
    post_update_to_api "success" 0
else
    post_update_to_api "failed" $?
fi
```

### VM API 设置

```bash
#!/usr/bin/env bash
# VM 的 API 设置

source api.func

# 为 VM 创建诊断文件
mkdir -p /usr/local/community-scripts
echo "DIAGNOSTICS=yes" > /usr/local/community-scripts/diagnostics

# 设置 VM 参数
export RANDOM_UUID="$(uuidgen)"
export DISK_SIZE="20G"
export CORE_COUNT=4
export RAM_SIZE=4096
export var_os="ubuntu"
export var_version="22.04"
export NSAPP="nextcloud"
export METHOD="install"

# 报告 VM 安装开始
post_to_api_vm

# 您的 VM 安装代码在这里
# ... VM 创建逻辑 ...

# 报告完成
post_update_to_api "success" 0
```

## 错误描述示例

### 基本错误解释

```bash
#!/usr/bin/env bash
source api.func

# 解释常见错误代码
echo "错误 0: '$(get_error_description 0)'"
echo "错误 1: $(get_error_description 1)"
echo "错误 127: $(get_error_description 127)"
echo "错误 200: $(get_error_description 200)"
echo "错误 255: $(get_error_description 255)"
```

### 错误代码测试

```bash
#!/usr/bin/env bash
source api.func

# 测试所有错误代码
test_error_codes() {
    local codes=(0 1 2 127 128 130 137 139 143 200 203 205 255)

    for code in "${codes[@]}"; do
        echo "代码 $code: $(get_error_description $code)"
    done
}

test_error_codes
```

### 带描述的错误处理

```bash
#!/usr/bin/env bash
source api.func

# 带错误处理的函数
run_command_with_error_handling() {
    local command="$1"
    local description="$2"

    echo "运行: $description"

    if $command; then
        echo "成功: $description"
        return 0
    else
        local exit_code=$?
        local error_msg=$(get_error_description $exit_code)
        echo "错误 $exit_code: $error_msg"
        return $exit_code
    fi
}

# 用法
run_command_with_error_handling "apt-get update" "包列表更新"
run_command_with_error_handling "nonexistent_command" "测试命令"
```

## API 通信示例

### LXC 安装报告

```bash
#!/usr/bin/env bash
source api.func

# 带 API 报告的完整 LXC 安装
install_lxc_with_reporting() {
    local app="$1"
    local ctid="$2"

    # 设置 API 报告
    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"
    export CT_TYPE=1
    export DISK_SIZE=10
    export CORE_COUNT=2
    export RAM_SIZE=2048
    export var_os="debian"
    export var_version="12"
    export NSAPP="$app"
    export METHOD="install"

    # 报告安装开始
    post_to_api

    # 安装过程
    echo "安装 $app 容器（ID: $ctid）..."

    # 模拟安装
    sleep 2

    # 检查安装是否成功
    if [[ $? -eq 0 ]]; then
        echo "安装成功完成"
        post_update_to_api "success" 0
        return 0
    else
        echo "安装失败"
        post_update_to_api "failed" $?
        return 1
    fi
}

# 安装多个容器
install_lxc_with_reporting "plex" "100"
install_lxc_with_reporting "nextcloud" "101"
install_lxc_with_reporting "nginx" "102"
```

### VM 安装报告

```bash
#!/usr/bin/env bash
source api.func

# 带 API 报告的完整 VM 安装
install_vm_with_reporting() {
    local app="$1"
    local vmid="$2"

    # 创建诊断文件
    mkdir -p /usr/local/community-scripts
    echo "DIAGNOSTICS=yes" > /usr/local/community-scripts/diagnostics

    # 设置 API 报告
    export RANDOM_UUID="$(uuidgen)"
    export DISK_SIZE="20G"
    export CORE_COUNT=4
    export RAM_SIZE=4096
    export var_os="ubuntu"
    export var_version="22.04"
    export NSAPP="$app"
    export METHOD="install"

    # 报告 VM 安装开始
    post_to_api_vm

    # VM 安装过程
    echo "安装 $app VM（ID: $vmid）..."

    # 模拟 VM 创建
    sleep 3

    # 检查 VM 创建是否成功
    if [[ $? -eq 0 ]]; then
        echo "VM 安装成功完成"
        post_update_to_api "success" 0
        return 0
    else
        echo "VM 安装失败"
        post_update_to_api "failed" $?
        return 1
    fi
}

# 安装多个 VM
install_vm_with_reporting "nextcloud" "200"
install_vm_with_reporting "wordpress" "201"
```

## 状态更新示例

### 成功报告

```bash
#!/usr/bin/env bash
source api.func

# 报告成功安装
report_success() {
    local operation="$1"

    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"

    echo "报告成功的 $operation"
    post_update_to_api "success" 0
}

# 用法
report_success "容器安装"
report_success "包安装"
report_success "服务配置"
```

### 失败报告

```bash
#!/usr/bin/env bash
source api.func

# 报告失败安装
report_failure() {
    local operation="$1"
    local exit_code="$2"

    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"

    local error_msg=$(get_error_description $exit_code)
    echo "报告失败的 $operation: $error_msg"
    post_update_to_api "failed" $exit_code
}

# 用法
report_failure "容器创建" 200
report_failure "包安装" 127
report_failure "服务启动" 1
```

### 条件状态报告

```bash
#!/usr/bin/env bash
source api.func

# 条件状态报告
report_installation_status() {
    local operation="$1"
    local exit_code="$2"

    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"

    if [[ $exit_code -eq 0 ]]; then
        echo "报告成功的 $operation"
        post_update_to_api "success" 0
    else
        local error_msg=$(get_error_description $exit_code)
        echo "报告失败的 $operation: $error_msg"
        post_update_to_api "failed" $exit_code
    fi
}

# 用法
report_installation_status "容器创建" 0
report_installation_status "包安装" 127
```

## 高级使用示例

### 带 API 报告的批量安装

```bash
#!/usr/bin/env bash
source api.func

# 带全面 API 报告的批量安装
batch_install_with_reporting() {
    local apps=("plex" "nextcloud" "nginx" "mysql")
    local ctids=(100 101 102 103)

    # 设置 API 报告
    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"
    export CT_TYPE=1
    export DISK_SIZE=8
    export CORE_COUNT=2
    export RAM_SIZE=2048
    export var_os="debian"
    export var_version="12"
    export METHOD="install"

    local success_count=0
    local failure_count=0

    for i in "${!apps[@]}"; do
        local app="${apps[$i]}"
        local ctid="${ctids[$i]}"

        echo "安装 $app（ID: $ctid）..."

        # 设置应用特定参数
        export NSAPP="$app"

        # 报告安装开始
        post_to_api

        # 模拟安装
        if install_app "$app" "$ctid"; then
            echo "$app 安装成功"
            post_update_to_api "success" 0
            ((success_count++))
        else
            echo "$app 安装失败"
            post_update_to_api "failed" $?
            ((failure_count++))
        fi

        echo "---"
    done

    echo "批量安装完成: $success_count 成功, $failure_count 失败"
}

# 模拟安装函数
install_app() {
    local app="$1"
    local ctid="$2"

    # 模拟安装
    sleep 1

    # 模拟偶尔失败
    if [[ $((RANDOM % 10)) -eq 0 ]]; then
        return 1
    fi

    return 0
}

batch_install_with_reporting
```

### 错误分析和报告

```bash
#!/usr/bin/env bash
source api.func

# 分析和报告错误
analyze_and_report_errors() {
    local log_file="$1"

    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"

    if [[ ! -f "$log_file" ]]; then
        echo "未找到日志文件: $log_file"
        return 1
    fi

    # 从日志中提取错误代码
    local error_codes=$(grep -o 'exit code [0-9]\+' "$log_file" | grep -o '[0-9]\+' | sort -u)

    if [[ -z "$error_codes" ]]; then
        echo "日志中未找到错误"
        post_update_to_api "success" 0
        return 0
    fi

    echo "找到错误代码: $error_codes"

    # 报告每个唯一错误
    for code in $error_codes; do
        local error_msg=$(get_error_description $code)
        echo "错误 $code: $error_msg"
        post_update_to_api "failed" $code
    done
}

# 用法
analyze_and_report_errors "/var/log/installation.log"
```

### API 健康检查

```bash
#!/usr/bin/env bash
source api.func

# 检查 API 连接性和功能
check_api_health() {
    echo "检查 API 健康状况..."

    # 测试先决条件
    if ! command -v curl >/dev/null 2>&1; then
        echo "错误: curl 不可用"
        return 1
    fi

    # 测试错误描述函数
    local test_error=$(get_error_description 127)
    if [[ -z "$test_error" ]]; then
        echo "错误: 错误描述函数不工作"
        return 1
    fi

    echo "错误描述测试: $test_error"

    # 测试 API 连接性（不发送数据）
    local api_url="https://api.community-scripts.org/dev/upload"
    if curl -s --head "$api_url" >/dev/null 2>&1; then
        echo "API 端点可访问"
    else
        echo "警告: API 端点不可访问"
    fi

    echo "API 健康检查完成"
}

check_api_health
```

## 集成示例

### 与 build.func

```bash
#!/usr/bin/env bash
# 与 build.func 集成

source core.func
source api.func
source build.func

# 设置 API 报告
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"

# 带 API 报告的容器创建
create_container_with_reporting() {
    local app="$1"
    local ctid="$2"

    # 设置容器参数
    export APP="$app"
    export CTID="$ctid"
    export var_hostname="${app}-server"
    export var_os="debian"
    export var_version="12"
    export var_cpu="2"
    export var_ram="2048"
    export var_disk="10"
    export var_net="vmbr0"
    export var_gateway="192.168.1.1"
    export var_ip="192.168.1.$ctid"
    export var_template_storage="local"
    export var_container_storage="local"

    # 报告安装开始
    post_to_api

    # 使用 build.func 创建容器
    if source build.func; then
        echo "容器 $app 创建成功"
        post_update_to_api "success" 0
        return 0
    else
        echo "容器 $app 创建失败"
        post_update_to_api "failed" $?
        return 1
    fi
}

# 创建容器
create_container_with_reporting "plex" "100"
create_container_with_reporting "nextcloud" "101"
```

### 与 vm-core.func

```bash
#!/usr/bin/env bash
# 与 vm-core.func 集成

source core.func
source api.func
source vm-core.func

# 设置 VM API 报告
mkdir -p /usr/local/community-scripts
echo "DIAGNOSTICS=yes" > /usr/local/community-scripts/diagnostics

export RANDOM_UUID="$(uuidgen)"

# 带 API 报告的 VM 创建
create_vm_with_reporting() {
    local app="$1"
    local vmid="$2"

    # 设置 VM 参数
    export APP="$app"
    export VMID="$vmid"
    export var_hostname="${app}-vm"
    export var_os="ubuntu"
    export var_version="22.04"
    export var_cpu="4"
    export var_ram="4096"
    export var_disk="20"

    # 报告 VM 安装开始
    post_to_api_vm

    # 使用 vm-core.func 创建 VM
    if source vm-core.func; then
        echo "VM $app 创建成功"
        post_update_to_api "success" 0
        return 0
    else
        echo "VM $app 创建失败"
        post_update_to_api "failed" $?
        return 1
    fi
}

# 创建 VM
create_vm_with_reporting "nextcloud" "200"
create_vm_with_reporting "wordpress" "201"
```

### 与 error_handler.func

```bash
#!/usr/bin/env bash
# 与 error_handler.func 集成

source core.func
source error_handler.func
source api.func

# 带 API 报告的增强错误处理
enhanced_error_handler() {
    local exit_code=${1:-$?}
    local command=${2:-${BASH_COMMAND:-unknown}}

    # 从 api.func 获取错误描述
    local error_msg=$(get_error_description $exit_code)

    # 显示错误信息
    echo "错误 $exit_code: $error_msg"
    echo "命令: $command"

    # 向 API 报告错误
    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"
    post_update_to_api "failed" $exit_code

    # 使用标准错误处理器
    error_handler $exit_code $command
}

# 设置增强错误处理
trap 'enhanced_error_handler' ERR

# 测试增强错误处理
nonexistent_command
```

## 最佳实践示例

### 全面的 API 集成

```bash
#!/usr/bin/env bash
# 全面的 API 集成示例

source core.func
source api.func

# 设置全面的 API 报告
setup_api_reporting() {
    # 启用诊断
    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"

    # 设置通用参数
    export CT_TYPE=1
    export DISK_SIZE=8
    export CORE_COUNT=2
    export RAM_SIZE=2048
    export var_os="debian"
    export var_version="12"
    export METHOD="install"

    echo "API 报告已配置"
}

# 带全面报告的安装
install_with_comprehensive_reporting() {
    local app="$1"
    local ctid="$2"

    # 设置 API 报告
    setup_api_reporting
    export NSAPP="$app"

    # 报告安装开始
    post_to_api

    # 安装过程
    echo "安装 $app..."

    # 模拟安装步骤
    local steps=("下载" "安装" "配置" "启动")
    for step in "${steps[@]}"; do
        echo "$step $app..."
        sleep 1
    done

    # 检查安装结果
    if [[ $? -eq 0 ]]; then
        echo "$app 安装成功完成"
        post_update_to_api "success" 0
        return 0
    else
        echo "$app 安装失败"
        post_update_to_api "failed" $?
        return 1
    fi
}

# 安装多个应用程序
apps=("plex" "nextcloud" "nginx" "mysql")
ctids=(100 101 102 103)

for i in "${!apps[@]}"; do
    install_with_comprehensive_reporting "${apps[$i]}" "${ctids[$i]}"
    echo "---"
done
```

### 带 API 报告的错误恢复

```bash
#!/usr/bin/env bash
source api.func

# 带 API 报告的错误恢复
retry_with_api_reporting() {
    local operation="$1"
    local max_attempts=3
    local attempt=1

    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"

    while [[ $attempt -le $max_attempts ]]; do
        echo "尝试 $attempt / $max_attempts: $operation"

        if $operation; then
            echo "操作在尝试 $attempt 时成功"
            post_update_to_api "success" 0
            return 0
        else
            local exit_code=$?
            local error_msg=$(get_error_description $exit_code)
            echo "尝试 $attempt 失败: $error_msg"

            post_update_to_api "failed" $exit_code

            ((attempt++))

            if [[ $attempt -le $max_attempts ]]; then
                echo "5 秒后重试..."
                sleep 5
            fi
        fi
    done

    echo "操作在 $max_attempts 次尝试后失败"
    return 1
}

# 用法
retry_with_api_reporting "apt-get update"
retry_with_api_reporting "apt-get install -y package"
```

### 带日志记录的 API 报告

```bash
#!/usr/bin/env bash
source api.func

# 带详细日志记录和 API 的安装
install_with_logging_and_api() {
    local app="$1"
    local log_file="/var/log/${app}_installation.log"

    # 设置 API 报告
    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"
    export NSAPP="$app"

    # 开始日志记录
    exec > >(tee -a "$log_file")
    exec 2>&1

    echo "在 $(date) 开始 $app 安装"

    # 报告安装开始
    post_to_api

    # 安装过程
    echo "安装 $app..."

    # 模拟安装
    if install_app "$app"; then
        echo "$app 安装在 $(date) 成功完成"
        post_update_to_api "success" 0
        return 0
    else
        local exit_code=$?
        local error_msg=$(get_error_description $exit_code)
        echo "$app 安装在 $(date) 失败: $error_msg"
        post_update_to_api "failed" $exit_code
        return $exit_code
    fi
}

# 模拟安装函数
install_app() {
    local app="$1"
    echo "安装 $app..."
    sleep 2
    return 0
}

# 带日志记录和 API 报告的安装
install_with_logging_and_api "plex"
```
