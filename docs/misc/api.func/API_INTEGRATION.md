# api.func 集成指南

## 概述

本文档描述 `api.func` 如何与 Proxmox Community Scripts 项目中的其他组件集成，包括依赖项、数据流和 API 接口。

## 依赖项

### 外部依赖

#### 必需命令
- **`curl`**：用于 API 通信的 HTTP 客户端
- **`uuidgen`**：生成唯一标识符（可选，可以使用其他方法）

#### 可选命令
- **无**：没有其他外部命令依赖

### 内部依赖

#### 来自其他脚本的环境变量
- **build.func**：提供容器创建变量
- **vm-core.func**：提供 VM 创建变量
- **core.func**：提供系统信息变量
- **安装脚本**：提供应用程序特定变量

## 集成点

### 与 build.func

#### LXC 容器报告
```bash
# build.func 使用 api.func 进行容器报告
source core.func
source api.func
source build.func

# 设置 API 报告
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"

# 带 API 报告的容器创建
create_container() {
    # 设置容器参数
    export CT_TYPE=1
    export DISK_SIZE="$var_disk"
    export CORE_COUNT="$var_cpu"
    export RAM_SIZE="$var_ram"
    export var_os="$var_os"
    export var_version="$var_version"
    export NSAPP="$APP"
    export METHOD="install"

    # 报告安装开始
    post_to_api

    # 使用 build.func 创建容器
    # ... build.func 容器创建逻辑 ...

    # 报告完成
    if [[ $? -eq 0 ]]; then
        post_update_to_api "success" 0
    else
        post_update_to_api "failed" $?
    fi
}
```

#### 错误报告集成
```bash
# build.func 使用 api.func 进行错误报告
handle_container_error() {
    local exit_code=$1
    local error_msg=$(get_error_description $exit_code)

    echo "容器创建失败: $error_msg"
    post_update_to_api "failed" $exit_code
}
```

### 与 vm-core.func

#### VM 安装报告
```bash
# vm-core.func 使用 api.func 进行 VM 报告
source core.func
source api.func
source vm-core.func

# 设置 VM API 报告
mkdir -p /usr/local/community-scripts
echo "DIAGNOSTICS=yes" > /usr/local/community-scripts/diagnostics

export RANDOM_UUID="$(uuidgen)"

# 带 API 报告的 VM 创建
create_vm() {
    # 设置 VM 参数
    export DISK_SIZE="${var_disk}G"
    export CORE_COUNT="$var_cpu"
    export RAM_SIZE="$var_ram"
    export var_os="$var_os"
    export var_version="$var_version"
    export NSAPP="$APP"
    export METHOD="install"

    # 报告 VM 安装开始
    post_to_api_vm

    # 使用 vm-core.func 创建 VM
    # ... vm-core.func VM 创建逻辑 ...

    # 报告完成
    post_update_to_api "success" 0
}
```

### 与 core.func

#### 系统信息集成
```bash
# core.func 为 api.func 提供系统信息
source core.func
source api.func

# 获取用于 API 报告的系统信息
get_system_info_for_api() {
    # 使用 core.func 实用程序获取 PVE 版本
    local pve_version=$(pveversion | awk -F'[/ ]' '{print $2}')

    # 设置 API 参数
    export var_os="$var_os"
    export var_version="$var_version"

    # 使用 core.func 错误处理和 api.func 报告
    if silent apt-get update; then
        post_update_to_api "success" 0
    else
        post_update_to_api "failed" $?
    fi
}
```

### 与 error_handler.func

#### 错误描述集成
```bash
# error_handler.func 使用 api.func 进行错误描述
source core.func
source error_handler.func
source api.func

# 带 API 报告的增强错误处理器
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
```

### 与 install.func

#### 安装过程报告
```bash
# install.func 使用 api.func 进行安装报告
source core.func
source api.func
source install.func

# 带 API 报告的安装
install_package_with_reporting() {
    local package="$1"

    # 设置 API 报告
    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"
    export NSAPP="$package"
    export METHOD="install"

    # 报告安装开始
    post_to_api

    # 使用 install.func 安装包
    if install_package "$package"; then
        echo "$package 安装成功"
        post_update_to_api "success" 0
        return 0
    else
        local exit_code=$?
        local error_msg=$(get_error_description $exit_code)
        echo "$package 安装失败: $error_msg"
        post_update_to_api "failed" $exit_code
        return $exit_code
    fi
}
```

### 与 alpine-install.func

#### Alpine 安装报告
```bash
# alpine-install.func 使用 api.func 进行 Alpine 报告
source core.func
source api.func
source alpine-install.func

# 带 API 报告的 Alpine 安装
install_alpine_with_reporting() {
    local app="$1"

    # 设置 API 报告
    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"
    export NSAPP="$app"
    export METHOD="install"
    export var_os="alpine"

    # 报告 Alpine 安装开始
    post_to_api

    # 使用 alpine-install.func 安装 Alpine 应用
    if install_alpine_app "$app"; then
        echo "Alpine $app 安装成功"
        post_update_to_api "success" 0
        return 0
    else
        local exit_code=$?
        local error_msg=$(get_error_description $exit_code)
        echo "Alpine $app 安装失败: $error_msg"
        post_update_to_api "failed" $exit_code
        return $exit_code
    fi
}
```

### 与 alpine-tools.func

#### Alpine 工具报告
```bash
# alpine-tools.func 使用 api.func 进行 Alpine 工具报告
source core.func
source api.func
source alpine-tools.func

# 带 API 报告的 Alpine 工具
run_alpine_tool_with_reporting() {
    local tool="$1"

    # 设置 API 报告
    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"
    export NSAPP="alpine-tools"
    export METHOD="tool"

    # 报告工具执行开始
    post_to_api

    # 使用 alpine-tools.func 运行 Alpine 工具
    if run_alpine_tool "$tool"; then
        echo "Alpine 工具 $tool 执行成功"
        post_update_to_api "success" 0
        return 0
    else
        local exit_code=$?
        local error_msg=$(get_error_description $exit_code)
        echo "Alpine 工具 $tool 失败: $error_msg"
        post_update_to_api "failed" $exit_code
        return $exit_code
    fi
}
```

### 与 passthrough.func

#### 硬件直通报告
```bash
# passthrough.func 使用 api.func 进行硬件报告
source core.func
source api.func
source passthrough.func

# 带 API 报告的硬件直通
configure_passthrough_with_reporting() {
    local hardware_type="$1"

    # 设置 API 报告
    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"
    export NSAPP="passthrough"
    export METHOD="hardware"

    # 报告直通配置开始
    post_to_api

    # 使用 passthrough.func 配置直通
    if configure_passthrough "$hardware_type"; then
        echo "硬件直通配置成功"
        post_update_to_api "success" 0
        return 0
    else
        local exit_code=$?
        local error_msg=$(get_error_description $exit_code)
        echo "硬件直通失败: $error_msg"
        post_update_to_api "failed" $exit_code
        return $exit_code
    fi
}
```

### 与 tools.func

#### 维护操作报告
```bash
# tools.func 使用 api.func 进行维护报告
source core.func
source api.func
source tools.func

# 带 API 报告的维护操作
run_maintenance_with_reporting() {
    local operation="$1"

    # 设置 API 报告
    export DIAGNOSTICS="yes"
    export RANDOM_UUID="$(uuidgen)"
    export NSAPP="maintenance"
    export METHOD="tool"

    # 报告维护开始
    post_to_api

    # 使用 tools.func 运行维护
    if run_maintenance_operation "$operation"; then
        echo "维护操作 $operation 成功完成"
        post_update_to_api "success" 0
        return 0
    else
        local exit_code=$?
        local error_msg=$(get_error_description $exit_code)
        echo "维护操作 $operation 失败: $error_msg"
        post_update_to_api "failed" $exit_code
        return $exit_code
    fi
}
```

## 数据流

### 输入数据

#### 来自其他脚本的环境变量
- **`CT_TYPE`**：容器类型（1 表示 LXC，2 表示 VM）
- **`DISK_SIZE`**：磁盘大小（GB）
- **`CORE_COUNT`**：CPU 核心数
- **`RAM_SIZE`**：RAM 大小（MB）
- **`var_os`**：操作系统类型
- **`var_version`**：操作系统版本
- **`DISABLEIP6`**：IPv6 禁用设置
- **`NSAPP`**：命名空间应用程序名称
- **`METHOD`**：安装方法
- **`DIAGNOSTICS`**：启用/禁用诊断报告
- **`RANDOM_UUID`**：用于跟踪的唯一标识符

#### 函数参数
- **退出代码**：传递给 `get_error_description()` 和 `post_update_to_api()`
- **状态信息**：传递给 `post_update_to_api()`
- **API 端点**：在函数中硬编码

#### 系统信息
- **PVE 版本**：从 `pveversion` 命令检索
- **磁盘大小处理**：为 VM API 处理（删除 'G' 后缀）
- **错误代码**：从命令退出代码检索

### 处理数据

#### API 请求准备
- **JSON 负载创建**：格式化数据供 API 使用
- **数据验证**：确保必需字段存在
- **错误处理**：处理缺失或无效数据
- **内容类型设置**：设置适当的 HTTP 标头

#### 错误处理
- **错误代码映射**：将数字代码映射到描述
- **错误消息格式化**：格式化错误描述
- **未知错误处理**：处理无法识别的错误代码
- **后备消息**：提供默认错误消息

#### API 通信
- **HTTP 请求准备**：准备 curl 命令
- **响应处理**：捕获 HTTP 响应代码
- **错误处理**：处理网络和 API 错误
- **重复防止**：防止重复状态更新

### 输出数据

#### API 通信
- **HTTP 请求**：发送到 community-scripts.org API
- **响应代码**：从 API 响应捕获
- **错误信息**：报告给 API
- **状态更新**：发送到 API

#### 错误信息
- **错误描述**：人类可读的错误消息
- **错误代码**：映射到描述
- **上下文信息**：错误上下文和详情
- **后备消息**：默认错误消息

#### 系统状态
- **POST_UPDATE_DONE**：防止重复更新
- **RESPONSE**：存储 API 响应
- **JSON_PAYLOAD**：存储格式化的 API 数据
- **API_URL**：存储 API 端点

## API 接口

### 公共函数

#### 错误描述
- **`get_error_description()`**：将退出代码转换为解释
- **参数**：要解释的退出代码
- **返回**：人类可读的解释字符串
- **用途**：被其他函数和脚本调用

#### API 通信
- **`post_to_api()`**：发送 LXC 安装数据
- **`post_to_api_vm()`**：发送 VM 安装数据
- **`post_update_to_api()`**：发送状态更新
- **参数**：状态和退出代码（用于更新）
- **返回**：无
- **用途**：被安装脚本调用

### 内部函数

#### 无
- api.func 中的所有函数都是公共的
- 没有内部辅助函数
- 所有功能的直接实现

### 全局变量

#### 配置变量
- **`DIAGNOSTICS`**：诊断报告设置
- **`RANDOM_UUID`**：唯一跟踪标识符
- **`POST_UPDATE_DONE`**：重复更新防止

#### 数据变量
- **`CT_TYPE`**：容器类型
- **`DISK_SIZE`**：磁盘大小
- **`CORE_COUNT`**：CPU 核心数
- **`RAM_SIZE`**：RAM 大小
- **`var_os`**：操作系统
- **`var_version`**：操作系统版本
- **`DISABLEIP6`**：IPv6 设置
- **`NSAPP`**：应用程序命名空间
- **`METHOD`**：安装方法

#### 内部变量
- **`API_URL`**：API 端点 URL
- **`JSON_PAYLOAD`**：API 请求负载
- **`RESPONSE`**：API 响应
- **`DISK_SIZE_API`**：VM API 的处理后磁盘大小

## 集成模式

### 标准集成模式

```bash
#!/usr/bin/env bash
# 标准集成模式

# 1. 首先 source core.func
source core.func

# 2. Source api.func
source api.func

# 3. 设置 API 报告
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"

# 4. 设置应用程序参数
export NSAPP="$APP"
export METHOD="install"

# 5. 报告安装开始
post_to_api

# 6. 执行安装
# ... 安装逻辑 ...

# 7. 报告完成
post_update_to_api "success" 0
```

### 最小集成模式

```bash
#!/usr/bin/env bash
# 最小集成模式

source api.func

# 基本错误报告
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"

# 报告失败
post_update_to_api "failed" 127
```

### 高级集成模式

```bash
#!/usr/bin/env bash
# 高级集成模式

source core.func
source api.func
source error_handler.func

# 设置全面的 API 报告
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"
export CT_TYPE=1
export DISK_SIZE=8
export CORE_COUNT=2
export RAM_SIZE=2048
export var_os="debian"
export var_version="12"
export METHOD="install"

# 带 API 报告的增强错误处理
enhanced_error_handler() {
    local exit_code=${1:-$?}
    local command=${2:-${BASH_COMMAND:-unknown}}

    local error_msg=$(get_error_description $exit_code)
    echo "错误 $exit_code: $error_msg"

    post_update_to_api "failed" $exit_code
    error_handler $exit_code $command
}

trap 'enhanced_error_handler' ERR

# 带 API 报告的高级操作
post_to_api
# ... 操作 ...
post_update_to_api "success" 0
```

## 错误处理集成

### 自动错误报告
- **错误描述**：提供人类可读的错误消息
- **API 集成**：向 community-scripts.org API 报告错误
- **错误跟踪**：跟踪错误模式以改进项目
- **诊断数据**：贡献匿名使用分析

### 手动错误报告
- **自定义错误代码**：为不同场景使用适当的错误代码
- **错误上下文**：为错误提供上下文信息
- **状态更新**：报告成功和失败情况
- **错误分析**：分析错误模式和趋势

### API 通信错误
- **网络故障**：优雅地处理 API 通信失败
- **缺少先决条件**：在 API 调用前检查先决条件
- **重复防止**：防止重复状态更新
- **错误恢复**：处理 API 错误而不阻止安装

## 性能考虑

### API 通信开销
- **最小影响**：API 调用增加最小开销
- **异步**：API 调用不会阻止安装过程
- **错误处理**：API 失败不影响安装
- **可选**：API 报告是可选的，可以禁用

### 内存使用
- **最小占用**：API 函数使用最小内存
- **变量重用**：全局变量在函数间重用
- **无内存泄漏**：适当的清理防止内存泄漏
- **高效处理**：高效的 JSON 负载创建

### 执行速度
- **快速 API 调用**：快速的 API 通信
- **高效错误处理**：快速的错误代码处理
- **最小延迟**：API 操作中的最小延迟
- **非阻塞**：API 调用不阻止安装

## 安全考虑

### 数据隐私
- **匿名报告**：仅发送匿名数据
- **无敏感数据**：不传输敏感信息
- **用户控制**：用户可以禁用诊断报告
- **数据最小化**：仅发送必要数据

### API 安全
- **HTTPS**：API 通信使用安全协议
- **数据验证**：发送前验证 API 数据
- **错误处理**：安全地处理 API 错误
- **无凭据**：不发送身份验证凭据

### 网络安全
- **安全通信**：使用安全的 HTTP 协议
- **错误处理**：优雅地处理网络错误
- **无数据泄漏**：不泄漏敏感数据
- **安全端点**：使用可信的 API 端点

## 未来集成考虑

### 可扩展性
- **新 API 端点**：易于添加新的 API 端点
- **额外数据**：易于添加新的数据字段
- **错误代码**：易于添加新的错误代码描述
- **API 版本**：易于支持新的 API 版本

### 兼容性
- **API 版本控制**：与不同 API 版本兼容
- **数据格式**：与不同数据格式兼容
- **错误代码**：与不同错误代码系统兼容
- **网络协议**：与不同网络协议兼容

### 性能
- **优化**：可以优化 API 通信
- **缓存**：可以缓存 API 响应
- **批处理操作**：可以批处理多个操作
- **异步处理**：可以使 API 调用异步
