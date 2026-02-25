# error_handler.func 函数参考

## 概述

本文档提供 `error_handler.func` 中所有函数的全面字母顺序参考，包括参数、依赖关系、使用示例和错误处理。

## 函数分类

### 错误解释函数

#### `explain_exit_code()`
**用途**：将数字退出码转换为人类可读的解释
**参数**：
- `$1` - 要解释的退出码
**返回值**：人类可读的错误解释字符串
**副作用**：无
**依赖关系**：无
**使用的环境变量**：无

**支持的退出码**：
- **通用/Shell**：1, 2, 126, 127, 128, 130, 137, 139, 143
- **包管理器**：100, 101, 255
- **Node.js**：243, 245, 246, 247, 248, 249, 254
- **Python**：210, 211, 212
- **PostgreSQL**：231, 232, 233, 234
- **MySQL/MariaDB**：241, 242, 243, 244
- **MongoDB**：251, 252, 253, 254
- **Proxmox 自定义**：200, 203, 204, 205, 209, 210, 214, 215, 216, 217, 220, 222, 223, 231

**使用示例**：
```bash
explanation=$(explain_exit_code 127)
echo "Error 127: $explanation"
# 输出：Error 127: Command not found
```

**错误码示例**：
```bash
explain_exit_code 1    # "General error / Operation not permitted"
explain_exit_code 126  # "Command invoked cannot execute (permission problem?)"
explain_exit_code 127  # "Command not found"
explain_exit_code 130  # "Terminated by Ctrl+C (SIGINT)"
explain_exit_code 200  # "Custom: Failed to create lock file"
explain_exit_code 999  # "Unknown error"
```

### 错误处理函数

#### `error_handler()`
**用途**：由 ERR trap 触发或手动调用的主错误处理器
**参数**：
- `$1` - 退出码（可选，默认为 $?）
- `$2` - 失败的命令（可选，默认为 BASH_COMMAND）
**返回值**：无（以错误码退出）
**副作用**：
- 显示详细的错误信息
- 如果启用，将错误记录到调试文件
- 如果可用，显示静默日志内容
- 以原始错误码退出
**依赖关系**：`explain_exit_code()`
**使用的环境变量**：`DEBUG_LOGFILE`、`SILENT_LOGFILE`

**使用示例**：
```bash
# 通过 ERR trap 自动错误处理
set -e
trap 'error_handler' ERR

# 手动错误处理
error_handler 127 "command_not_found"
```

**显示的错误信息**：
- 带颜色编码的错误消息
- 发生错误的行号
- 带解释的退出码
- 失败的命令
- 静默日志内容（最后 20 行）
- 调试日志条目（如果启用）

### 信号处理函数

#### `on_interrupt()`
**用途**：优雅地处理 SIGINT（Ctrl+C）信号
**参数**：无
**返回值**：无（以代码 130 退出）
**副作用**：
- 显示中断消息
- 以 SIGINT 代码（130）退出
**依赖关系**：无
**使用的环境变量**：无

**使用示例**：
```bash
# 设置中断处理器
trap on_interrupt INT

# 用户按下 Ctrl+C
# 处理器显示："Interrupted by user (SIGINT)"
# 脚本以代码 130 退出
```

#### `on_terminate()`
**用途**：优雅地处理 SIGTERM 信号
**参数**：无
**返回值**：无（以代码 143 退出）
**副作用**：
- 显示终止消息
- 以 SIGTERM 代码（143）退出
**依赖关系**：无
**使用的环境变量**：无

**使用示例**：
```bash
# 设置终止处理器
trap on_terminate TERM

# 系统发送 SIGTERM
# 处理器显示："Terminated by signal (SIGTERM)"
# 脚本以代码 143 退出
```

### 清理函数

#### `on_exit()`
**用途**：处理脚本退出清理
**参数**：无
**返回值**：无（以原始退出码退出）
**副作用**：
- 如果设置了锁文件则删除
- 以原始退出码退出
**依赖关系**：无
**使用的环境变量**：`lockfile`

**使用示例**：
```bash
# 设置退出处理器
trap on_exit EXIT

# 设置锁文件
lockfile="/tmp/my_script.lock"

# 脚本正常退出或出错退出
# 处理器删除锁文件并退出
```

### 初始化函数

#### `catch_errors()`
**用途**：初始化错误处理 trap 和严格模式
**参数**：无
**返回值**：无
**副作用**：
- 设置严格错误处理模式
- 设置错误 trap
- 设置信号 trap
- 设置退出 trap
**依赖关系**：无
**使用的环境变量**：`STRICT_UNSET`

**严格模式设置**：
- `-E`：命令失败时退出
- `-e`：任何错误时退出
- `-o pipefail`：管道失败时退出
- `-u`：未设置变量时退出（如果 STRICT_UNSET=1）

**Trap 设置**：
- `ERR`：命令失败时调用 `error_handler`
- `EXIT`：脚本退出时调用 `on_exit`
- `INT`：SIGINT 时调用 `on_interrupt`
- `TERM`：SIGTERM 时调用 `on_terminate`

**使用示例**：
```bash
# 初始化错误处理
catch_errors

# 脚本现在具有完整的错误处理
# 所有错误都将被捕获和处理
```

## 函数调用层次结构

### 错误处理流程
```
命令失败
├── ERR trap 触发
├── 调用 error_handler()
│   ├── 获取退出码
│   ├── 获取命令信息
│   ├── 获取行号
│   ├── explain_exit_code()
│   ├── 显示错误信息
│   ├── 记录到调试文件
│   ├── 显示静默日志
│   └── 以错误码退出
```

### 信号处理流程
```
接收到信号
├── 信号 trap 触发
├── 调用相应的处理器
│   ├── SIGINT 调用 on_interrupt()
│   ├── SIGTERM 调用 on_terminate()
│   └── EXIT 调用 on_exit()
└── 以信号代码退出
```

### 初始化流程
```
catch_errors()
├── 设置严格模式
│   ├── -E（失败时退出）
│   ├── -e（错误时退出）
│   ├── -o pipefail（管道失败）
│   └── -u（未设置变量，如果启用）
└── 设置 trap
    ├── ERR → error_handler
    ├── EXIT → on_exit
    ├── INT → on_interrupt
    └── TERM → on_terminate
```

## 错误码参考

### 通用/Shell 错误
| 代码 | 描述 |
|------|-------------|
| 1 | 一般错误 / 操作不允许 |
| 2 | Shell 内置命令误用（例如语法错误）|
| 126 | 调用的命令无法执行（权限问题？）|
| 127 | 命令未找到 |
| 128 | exit 的参数无效 |
| 130 | 被 Ctrl+C 终止（SIGINT）|
| 137 | 被杀死（SIGKILL / 内存不足？）|
| 139 | 段错误（核心已转储）|
| 143 | 被终止（SIGTERM）|

### 包管理器错误
| 代码 | 描述 |
|------|-------------|
| 100 | APT：包管理器错误（损坏的包 / 依赖问题）|
| 101 | APT：配置错误（错误的 sources.list，格式错误的配置）|
| 255 | DPKG：致命内部错误 |

### Node.js 错误
| 代码 | 描述 |
|------|-------------|
| 243 | Node.js：内存不足（JavaScript 堆内存不足）|
| 245 | Node.js：无效的命令行选项 |
| 246 | Node.js：内部 JavaScript 解析错误 |
| 247 | Node.js：致命内部错误 |
| 248 | Node.js：无效的 C++ 插件 / N-API 失败 |
| 249 | Node.js：检查器错误 |
| 254 | npm/pnpm/yarn：未知致命错误 |

### Python 错误
| 代码 | 描述 |
|------|-------------|
| 210 | Python：虚拟环境 / uv 环境缺失或损坏 |
| 211 | Python：依赖解析失败 |
| 212 | Python：安装中止（权限或 EXTERNALLY-MANAGED）|

### 数据库错误
| 代码 | 描述 |
|------|-------------|
| 231 | PostgreSQL：连接失败（服务器未运行 / 错误的套接字）|
| 232 | PostgreSQL：认证失败（错误的用户名/密码）|
| 233 | PostgreSQL：数据库不存在 |
| 234 | PostgreSQL：查询中的致命错误 / 语法错误 |
| 241 | MySQL/MariaDB：连接失败（服务器未运行 / 错误的套接字）|
| 242 | MySQL/MariaDB：认证失败（错误的用户名/密码）|
| 243 | MySQL/MariaDB：数据库不存在 |
| 244 | MySQL/MariaDB：查询中的致命错误 / 语法错误 |
| 251 | MongoDB：连接失败（服务器未运行）|
| 252 | MongoDB：认证失败（错误的用户名/密码）|
| 253 | MongoDB：数据库未找到 |
| 254 | MongoDB：致命查询错误 |

### Proxmox 自定义错误
| 代码 | 描述 |
|------|-------------|
| 200 | 自定义：创建锁文件失败 |
| 203 | 自定义：缺少 CTID 变量 |
| 204 | 自定义：缺少 PCT_OSTYPE 变量 |
| 205 | 自定义：无效的 CTID（<100）|
| 209 | 自定义：容器创建失败 |
| 210 | 自定义：集群未达到法定人数 |
| 214 | 自定义：存储空间不足 |
| 215 | 自定义：容器 ID 未列出 |
| 216 | 自定义：配置中缺少 RootFS 条目 |
| 217 | 自定义：存储不支持 rootdir |
| 220 | 自定义：无法解析模板路径 |
| 222 | 自定义：3 次尝试后模板下载失败 |
| 223 | 自定义：下载后模板不可用 |
| 231 | 自定义：LXC 堆栈升级/重试失败 |

## 环境变量依赖

### 必需变量
- **`lockfile`**：用于清理的锁文件路径（由调用脚本设置）

### 可选变量
- **`DEBUG_LOGFILE`**：用于错误记录的调试日志文件路径
- **`SILENT_LOGFILE`**：静默执行日志文件路径
- **`STRICT_UNSET`**：启用严格的未设置变量检查（0/1）

### 内部变量
- **`exit_code`**：当前退出码
- **`command`**：失败的命令
- **`line_number`**：发生错误的行号
- **`explanation`**：错误解释文本

## 错误处理模式

### 自动错误处理
```bash
#!/usr/bin/env bash
source error_handler.func

# 初始化错误处理
catch_errors

# 现在所有命令都被监控
# 错误将被自动捕获和处理
```

### 手动错误处理
```bash
#!/usr/bin/env bash
source error_handler.func

# 手动错误处理
if ! command -v required_tool >/dev/null 2>&1; then
    error_handler 127 "required_tool not found"
fi
```

### 自定义错误码
```bash
#!/usr/bin/env bash
source error_handler.func

# 使用自定义错误码
if [[ ! -f /required/file ]]; then
    echo "错误：缺少必需文件"
    exit 200  # 自定义错误码
fi
```

### 信号处理
```bash
#!/usr/bin/env bash
source error_handler.func

# 设置信号处理
trap on_interrupt INT
trap on_terminate TERM
trap on_exit EXIT

# 脚本优雅地处理信号
```

## 集成示例

### 与 core.func 集成
```bash
#!/usr/bin/env bash
source core.func
source error_handler.func

# 静默执行使用 error_handler 进行解释
silent apt-get install -y package
# 如果命令失败，error_handler 提供解释
```

### 与 build.func 集成
```bash
#!/usr/bin/env bash
source core.func
source error_handler.func
source build.func

# 带错误处理的容器创建
# 错误被捕获并解释
```

### 与 tools.func 集成
```bash
#!/usr/bin/env bash
source core.func
source error_handler.func
source tools.func

# 带错误处理的工具操作
# 所有错误都被正确处理和解释
```

## 最佳实践

### 错误处理设置
1. 在脚本早期引入 error_handler.func
2. 调用 catch_errors() 初始化 trap
3. 为不同的错误类型使用适当的退出码
4. 提供有意义的错误消息

### 信号处理
1. 始终设置信号 trap
2. 在中断时提供优雅的清理
3. 为信号使用适当的退出码
4. 清理临时文件和进程

### 错误报告
1. 使用 explain_exit_code() 提供用户友好的消息
2. 在需要时将错误记录到调试文件
3. 提供上下文信息（行号、命令）
4. 与静默执行日志集成

### 自定义错误码
1. 为容器/虚拟机错误使用 Proxmox 自定义错误码（200-231）
2. 为常见操作使用标准错误码
3. 在脚本注释中记录自定义错误码
4. 为自定义代码提供清晰的错误消息
