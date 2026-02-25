# error_handler.func 文档

## 概述

`error_handler.func` 文件为 Proxmox Community Scripts 提供全面的错误处理和信号管理。它提供详细的错误代码解释、优雅的错误恢复和适当的清理机制。

## 目的和用例

- **错误代码解释**：为退出代码提供人类可读的解释
- **信号处理**：优雅地管理 SIGINT、SIGTERM 和其他信号
- **错误恢复**：实现适当的清理和错误报告
- **调试日志**：记录错误信息以进行故障排除
- **静默执行支持**：与 core.func 静默执行集成

## 快速参考

### 主要功能组
- **错误解释**：`explain_exit_code()` - 将退出代码转换为人类可读的消息
- **错误处理**：`error_handler()` - 带详细报告的主错误处理程序
- **信号处理程序**：`on_interrupt()`、`on_terminate()` - 优雅的信号处理
- **清理**：`on_exit()` - 脚本退出时清理
- **陷阱设置**：`catch_errors()` - 初始化错误处理陷阱

### 依赖项
- **外部**：无（纯 Bash 实现）
- **内部**：使用来自 core.func 的颜色变量

### 集成点
- 被使用于：通过 core.func 静默执行的所有脚本
- 使用：来自 core.func 的颜色变量
- 提供：为 core.func silent 函数提供错误解释

## 文档文件

### 📊 [ERROR_HANDLER_FLOWCHART.md](./ERROR_HANDLER_FLOWCHART.md)
显示错误处理过程和信号管理的可视化执行流程。

### 📚 [ERROR_HANDLER_FUNCTIONS_REFERENCE.md](./ERROR_HANDLER_FUNCTIONS_REFERENCE.md)
所有函数的完整字母顺序参考，包含参数、依赖项和使用详情。

### 💡 [ERROR_HANDLER_USAGE_EXAMPLES.md](./ERROR_HANDLER_USAGE_EXAMPLES.md)
展示如何使用错误处理函数和常见模式的实用示例。

### 🔗 [ERROR_HANDLER_INTEGRATION.md](./ERROR_HANDLER_INTEGRATION.md)
error_handler.func 如何与其他组件集成并提供错误处理服务。

## 主要特性

### 错误代码分类
- **一般/Shell 错误**：退出代码 1、2、126、127、128、130、137、139、143
- **包管理器错误**：APT/DPKG 错误（100、101、255）
- **Node.js 错误**：JavaScript 运行时错误（243-249、254）
- **Python 错误**：Python 环境和依赖错误（210-212）
- **数据库错误**：PostgreSQL、MySQL、MongoDB 错误（231-254）
- **Proxmox 自定义错误**：容器和 VM 特定错误（200-231）

### 信号处理
- **SIGINT (Ctrl+C)**：优雅的中断处理
- **SIGTERM**：优雅的终止处理
- **EXIT**：脚本退出时清理
- **ERR**：命令失败的错误陷阱

### 错误报告
- **详细消息**：人类可读的错误解释
- **上下文信息**：行号、命令、时间戳
- **日志集成**：静默日志文件集成
- **调试日志**：可选的调试日志文件支持

## 常见使用模式

### 基本错误处理设置
```bash
#!/usr/bin/env bash
# 基本错误处理设置

source error_handler.func

# 初始化错误处理
catch_errors

# 您的脚本代码在这里
# 错误将自动处理
```

### 手动错误解释
```bash
#!/usr/bin/env bash
source error_handler.func

# 获取错误解释
explanation=$(explain_exit_code 127)
echo "错误 127: $explanation"
# 输出：错误 127: Command not found
```

### 自定义错误处理
```bash
#!/usr/bin/env bash
source error_handler.func

# 自定义错误处理
if ! command -v required_tool >/dev/null 2>&1; then
    echo "错误：未找到 required_tool"
    exit 127
fi
```

## 环境变量

### 调试变量
- `DEBUG_LOGFILE`：用于错误日志的调试日志文件路径
- `SILENT_LOGFILE`：静默执行日志文件路径
- `STRICT_UNSET`：启用严格的未设置变量检查（0/1）

### 内部变量
- `lockfile`：清理的锁文件路径（由调用脚本设置）
- `exit_code`：当前退出代码
- `command`：失败的命令
- `line_number`：发生错误的行号

## 错误分类

### 一般/Shell 错误
- **1**：一般错误 / 操作不允许
- **2**：shell 内置命令误用（语法错误）
- **126**：调用的命令无法执行（权限问题）
- **127**：命令未找到
- **128**：exit 的参数无效
- **130**：被 Ctrl+C 终止（SIGINT）
- **137**：被终止（SIGKILL / 内存不足）
- **139**：段错误（核心转储）
- **143**：终止（SIGTERM）

### 包管理器错误
- **100**：APT 包管理器错误（损坏的包）
- **101**：APT 配置错误（错误的 sources.list）
- **255**：DPKG 致命内部错误

### Node.js 错误
- **243**：JavaScript 堆内存不足
- **245**：无效的命令行选项
- **246**：内部 JavaScript 解析错误
- **247**：致命内部错误
- **248**：无效的 C++ 插件 / N-API 失败
- **249**：检查器错误
- **254**：npm/pnpm/yarn 未知致命错误

### Python 错误
- **210**：Virtualenv/uv 环境缺失或损坏
- **211**：依赖解析失败
- **212**：安装中止（权限或 EXTERNALLY-MANAGED）

### 数据库错误
- **PostgreSQL (231-234)**：连接、身份验证、数据库、查询错误
- **MySQL/MariaDB (241-244)**：连接、身份验证、数据库、查询错误
- **MongoDB (251-254)**：连接、身份验证、数据库、查询错误

### Proxmox 自定义错误
- **200**：创建锁文件失败
- **203**：缺少 CTID 变量
- **204**：缺少 PCT_OSTYPE 变量
- **205**：无效的 CTID (<100)
- **209**：容器创建失败
- **210**：集群未达到法定人数
- **214**：存储空间不足
- **215**：容器 ID 未列出
- **216**：配置中缺少 RootFS 条目
- **217**：存储不支持 rootdir
- **220**：无法解析模板路径
- **222**：3 次尝试后模板下载失败
- **223**：下载后模板不可用
- **231**：LXC 堆栈升级/重试失败

## 最佳实践

### 错误处理设置
1. 在脚本早期引用 error_handler.func
2. 调用 catch_errors() 初始化陷阱
3. 为不同错误类型使用适当的退出代码
4. 提供有意义的错误消息

### 信号处理
1. 始终设置信号陷阱
2. 在中断时提供优雅的清理
3. 为信号使用适当的退出代码
4. 清理临时文件和进程

### 错误报告
1. 使用 explain_exit_code() 获取用户友好的消息
2. 在需要时将错误记录到调试文件
3. 提供上下文信息（行号、命令）
4. 与静默执行日志集成

## 故障排除

### 常见问题
1. **缺少错误处理程序**：确保引用 error_handler.func
2. **陷阱未设置**：调用 catch_errors() 初始化陷阱
3. **颜色变量**：确保引用 core.func 以获取颜色
4. **锁文件**：在 on_exit() 中清理锁文件

### 调试模式
启用调试日志以获取详细的错误信息：
```bash
export DEBUG_LOGFILE="/tmp/debug.log"
source error_handler.func
catch_errors
```

### 错误代码测试
测试错误解释：
```bash
source error_handler.func
for code in 1 2 126 127 128 130 137 139 143; do
    echo "代码 $code: $(explain_exit_code $code)"
done
```

## 相关文档

- [core.func](../core.func/) - 核心实用程序和静默执行
- [build.func](../build.func/) - 带错误处理的容器创建
- [tools.func](../tools.func/) - 带错误处理的扩展实用程序
- [api.func](../api.func/) - 带错误处理的 API 操作

---

*本文档涵盖 error_handler.func 文件，该文件为所有 Proxmox Community Scripts 提供全面的错误处理。*
