# api.func 函数参考

## 概述

本文档提供 `api.func` 中所有函数的全面字母顺序参考，包括参数、依赖项、使用示例和错误处理。

## 函数分类

### 错误描述函数

#### `get_error_description()`
**用途**：将数字退出代码转换为人类可读的解释
**参数**：
- `$1` - 要解释的退出代码
**返回**：人类可读的错误解释字符串
**副作用**：无
**依赖项**：无
**使用的环境变量**：无

**支持的退出代码**：
- **一般系统**：0-9、18、22、28、35、56、60、125-128、129-143、152、255
- **LXC 特定**：100-101、200-209
- **Docker**：125

**使用示例**：
```bash
error_msg=$(get_error_description 127)
echo "错误 127: $error_msg"
# 输出：错误 127: Command not found: Incorrect path or missing dependency.
```

**错误代码示例**：
```bash
get_error_description 0     # " "（空格）
get_error_description 1     # "General error: An unspecified error occurred."
get_error_description 127   # "Command not found: Incorrect path or missing dependency."
get_error_description 200   # "LXC creation failed."
get_error_description 255   # "Unknown critical error, often due to missing permissions or broken scripts."
```

### API 通信函数

#### `post_to_api()`
**用途**：向 community-scripts.org API 发送 LXC 容器安装数据
**参数**：无（使用环境变量）
**返回**：无
**副作用**：
- 向 API 发送 HTTP POST 请求
- 将响应存储在 RESPONSE 变量中
- 需要 curl 命令和网络连接
**依赖项**：`curl` 命令
**使用的环境变量**：`DIAGNOSTICS`、`RANDOM_UUID`、`CT_TYPE`、`DISK_SIZE`、`CORE_COUNT`、`RAM_SIZE`、`var_os`、`var_version`、`DISABLEIP6`、`NSAPP`、`METHOD`

**先决条件**：
- `curl` 命令必须可用
- `DIAGNOSTICS` 必须设置为 "yes"
- `RANDOM_UUID` 必须设置且非空

**API 端点**：`https://api.community-scripts.org/dev/upload`

**JSON 负载结构**：
```json
{
    "ct_type": 1,
    "type": "lxc",
    "disk_size": 8,
    "core_count": 2,
    "ram_size": 2048,
    "os_type": "debian",
    "os_version": "12",
    "disableip6": "true",
    "nsapp": "plex",
    "method": "install",
    "pve_version": "8.0",
    "status": "installing",
    "random_id": "uuid-string"
}
```

**使用示例**：
```bash
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"
export CT_TYPE=1
export DISK_SIZE=8
export CORE_COUNT=2
export RAM_SIZE=2048
export var_os="debian"
export var_version="12"
export NSAPP="plex"
export METHOD="install"

post_to_api
```

#### `post_to_api_vm()`
**用途**：向 community-scripts.org API 发送 VM 安装数据
**参数**：无（使用环境变量）
**返回**：无
**副作用**：
- 向 API 发送 HTTP POST 请求
- 将响应存储在 RESPONSE 变量中
- 需要 curl 命令和网络连接
**依赖项**：`curl` 命令、诊断文件
**使用的环境变量**：`DIAGNOSTICS`、`RANDOM_UUID`、`DISK_SIZE`、`CORE_COUNT`、`RAM_SIZE`、`var_os`、`var_version`、`NSAPP`、`METHOD`

**先决条件**：
- `/usr/local/community-scripts/diagnostics` 文件必须存在
- 诊断文件中的 `DIAGNOSTICS` 必须设置为 "yes"
- `curl` 命令必须可用
- `RANDOM_UUID` 必须设置且非空

**API 端点**：`https://api.community-scripts.org/dev/upload`

**JSON 负载结构**：
```json
{
    "ct_type": 2,
    "type": "vm",
    "disk_size": 8,
    "core_count": 2,
    "ram_size": 2048,
    "os_type": "debian",
    "os_version": "12",
    "disableip6": "",
    "nsapp": "plex",
    "method": "install",
    "pve_version": "8.0",
    "status": "installing",
    "random_id": "uuid-string"
}
```

**使用示例**：
```bash
# 创建诊断文件
echo "DIAGNOSTICS=yes" > /usr/local/community-scripts/diagnostics

export RANDOM_UUID="$(uuidgen)"
export DISK_SIZE="8G"
export CORE_COUNT=2
export RAM_SIZE=2048
export var_os="debian"
export var_version="12"
export NSAPP="plex"
export METHOD="install"

post_to_api_vm
```

#### `post_update_to_api()`
**用途**：向 community-scripts.org API 发送安装完成状态
**参数**：
- `$1` - 状态（"success" 或 "failed"，默认："failed"）
- `$2` - 退出代码（默认：1）
**返回**：无
**副作用**：
- 向 API 发送 HTTP POST 请求
- 设置 POST_UPDATE_DONE=true 以防止重复
- 将响应存储在 RESPONSE 变量中
**依赖项**：`curl` 命令、`get_error_description()`
**使用的环境变量**：`DIAGNOSTICS`、`RANDOM_UUID`

**先决条件**：
- `curl` 命令必须可用
- `DIAGNOSTICS` 必须设置为 "yes"
- `RANDOM_UUID` 必须设置且非空
- POST_UPDATE_DONE 必须为 false（防止重复）

**API 端点**：`https://api.community-scripts.org/dev/upload/updatestatus`

**JSON 负载结构**：
```json
{
    "status": "success",
    "error": "来自 get_error_description() 的错误描述",
    "random_id": "uuid-string"
}
```

**使用示例**：
```bash
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"

# 报告成功安装
post_update_to_api "success" 0

# 报告失败安装
post_update_to_api "failed" 127
```

## 函数调用层次结构

### API 通信流程
```
post_to_api()
├── 检查 curl 可用性
├── 检查 DIAGNOSTICS 设置
├── 检查 RANDOM_UUID
├── 获取 PVE 版本
├── 创建 JSON 负载
└── 发送 HTTP POST 请求

post_to_api_vm()
├── 检查诊断文件
├── 检查 curl 可用性
├── 检查 DIAGNOSTICS 设置
├── 检查 RANDOM_UUID
├── 处理磁盘大小
├── 获取 PVE 版本
├── 创建 JSON 负载
└── 发送 HTTP POST 请求

post_update_to_api()
├── 检查 POST_UPDATE_DONE 标志
├── 检查 curl 可用性
├── 检查 DIAGNOSTICS 设置
├── 检查 RANDOM_UUID
├── 确定状态和退出代码
├── 获取错误描述
├── 创建 JSON 负载
├── 发送 HTTP POST 请求
└── 设置 POST_UPDATE_DONE=true
```

### 错误描述流程
```
get_error_description()
├── 匹配退出代码
├── 返回适当的描述
└── 处理未知代码
```

## 错误代码参考

### 一般系统错误
| 代码 | 描述 |
|------|-------------|
| 0 | （空格） |
| 1 | General error: An unspecified error occurred. |
| 2 | Incorrect shell usage or invalid command arguments. |
| 3 | Unexecuted function or invalid shell condition. |
| 4 | Error opening a file or invalid path. |
| 5 | I/O error: An input/output failure occurred. |
| 6 | No such device or address. |
| 7 | Insufficient memory or resource exhaustion. |
| 8 | Non-executable file or invalid file format. |
| 9 | Failed child process execution. |
| 18 | Connection to a remote server failed. |
| 22 | Invalid argument or faulty network connection. |
| 28 | No space left on device. |
| 35 | Timeout while establishing a connection. |
| 56 | Faulty TLS connection. |
| 60 | SSL certificate error. |

### 命令执行错误
| 代码 | 描述 |
|------|-------------|
| 125 | Docker error: Container could not start. |
| 126 | Command not executable: Incorrect permissions or missing dependencies. |
| 127 | Command not found: Incorrect path or missing dependency. |
| 128 | Invalid exit signal, e.g., incorrect Git command. |

### 信号错误
| 代码 | 描述 |
|------|-------------|
| 129 | Signal 1 (SIGHUP): Process terminated due to hangup. |
| 130 | Signal 2 (SIGINT): Manual termination via Ctrl+C. |
| 132 | Signal 4 (SIGILL): Illegal machine instruction. |
| 133 | Signal 5 (SIGTRAP): Debugging error or invalid breakpoint signal. |
| 134 | Signal 6 (SIGABRT): Program aborted itself. |
| 135 | Signal 7 (SIGBUS): Memory error, invalid memory address. |
| 137 | Signal 9 (SIGKILL): Process forcibly terminated (OOM-killer or 'kill -9'). |
| 139 | Signal 11 (SIGSEGV): Segmentation fault, possibly due to invalid pointer access. |
| 141 | Signal 13 (SIGPIPE): Pipe closed unexpectedly. |
| 143 | Signal 15 (SIGTERM): Process terminated normally. |
| 152 | Signal 24 (SIGXCPU): CPU time limit exceeded. |

### LXC 特定错误
| 代码 | 描述 |
|------|-------------|
| 100 | LXC install error: Unexpected error in create_lxc.sh. |
| 101 | LXC install error: No network connection detected. |
| 200 | LXC creation failed. |
| 201 | LXC error: Invalid Storage class. |
| 202 | User aborted menu in create_lxc.sh. |
| 203 | CTID not set in create_lxc.sh. |
| 204 | PCT_OSTYPE not set in create_lxc.sh. |
| 205 | CTID cannot be less than 100 in create_lxc.sh. |
| 206 | CTID already in use in create_lxc.sh. |
| 207 | Template not found in create_lxc.sh. |
| 208 | Error downloading template in create_lxc.sh. |
| 209 | Container creation failed, but template is intact in create_lxc.sh. |

### 其他错误
| 代码 | 描述 |
|------|-------------|
| 255 | Unknown critical error, often due to missing permissions or broken scripts. |
| * | Unknown error code (exit_code). |

## 环境变量依赖

### 必需变量
- **`DIAGNOSTICS`**：启用/禁用诊断报告（"yes"/"no"）
- **`RANDOM_UUID`**：用于跟踪的唯一标识符

### 可选变量
- **`CT_TYPE`**：容器类型（1 表示 LXC，2 表示 VM）
- **`DISK_SIZE`**：磁盘大小（GB）（VM 为带 'G' 后缀的 GB）
- **`CORE_COUNT`**：CPU 核心数
- **`RAM_SIZE`**：RAM 大小（MB）
- **`var_os`**：操作系统类型
- **`var_version`**：操作系统版本
- **`DISABLEIP6`**：IPv6 禁用设置
- **`NSAPP`**：命名空间应用程序名称
- **`METHOD`**：安装方法

### 内部变量
- **`POST_UPDATE_DONE`**：防止重复状态更新
- **`API_URL`**：Community scripts API 端点
- **`JSON_PAYLOAD`**：API 请求负载
- **`RESPONSE`**：API 响应
- **`DISK_SIZE_API`**：VM API 的处理后磁盘大小

## 错误处理模式

### API 通信错误
- 所有 API 函数优雅地处理 curl 失败
- 网络错误不会阻止安装过程
- 缺少先决条件会导致提前返回
- 防止重复更新

### 错误描述错误
- 未知错误代码返回通用消息
- 所有错误代码都使用 case 语句处理
- 后备消息包含实际错误代码

### 先决条件验证
- 在 API 调用前检查 curl 可用性
- 验证 DIAGNOSTICS 设置
- 确保 RANDOM_UUID 已设置
- 检查重复更新

## 集成示例

### 与 build.func
```bash
#!/usr/bin/env bash
source core.func
source api.func
source build.func

# 设置 API 报告
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"

# 报告安装开始
post_to_api

# 容器创建...
# ... build.func 代码 ...

# 报告完成
if [[ $? -eq 0 ]]; then
    post_update_to_api "success" 0
else
    post_update_to_api "failed" $?
fi
```

### 与 vm-core.func
```bash
#!/usr/bin/env bash
source core.func
source api.func
source vm-core.func

# 设置 API 报告
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"

# 报告 VM 安装开始
post_to_api_vm

# VM 创建...
# ... vm-core.func 代码 ...

# 报告完成
post_update_to_api "success" 0
```

### 与 error_handler.func
```bash
#!/usr/bin/env bash
source core.func
source error_handler.func
source api.func

# 使用错误描述
error_code=127
error_msg=$(get_error_description $error_code)
echo "错误 $error_code: $error_msg"

# 向 API 报告错误
post_update_to_api "failed" $error_code
```

## 最佳实践

### API 使用
1. 在 API 调用前始终检查先决条件
2. 使用唯一标识符进行跟踪
3. 优雅地处理 API 失败
4. 不要因 API 失败而阻止安装

### 错误报告
1. 使用适当的错误代码
2. 提供有意义的错误描述
3. 报告成功和失败情况
4. 防止重复状态更新

### 诊断报告
1. 尊重用户隐私设置
2. 仅在启用诊断时发送数据
3. 使用匿名跟踪标识符
4. 包含相关系统信息

### 错误处理
1. 优雅地处理未知错误代码
2. 提供后备错误消息
3. 在未知错误消息中包含错误代码
4. 使用一致的错误消息格式
