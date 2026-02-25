# core.func 文档

## 概述

`core.func` 文件提供基础实用函数和系统检查，构成 Proxmox Community Scripts 项目中所有其他脚本的基础。它处理基本系统操作、用户界面元素、验证和核心基础设施。

## 目的和用例

- **系统验证**：检查 Proxmox VE 兼容性、架构、shell 要求
- **用户界面**：提供彩色输出、图标、旋转器和格式化消息
- **核心实用工具**：所有脚本使用的基本函数
- **错误处理**：带详细错误报告的静默执行
- **系统信息**：OS 检测、详细模式处理、交换管理

## 快速参考

### 主要功能组
- **系统检查**：`pve_check()`、`arch_check()`、`shell_check()`、`root_check()`
- **用户界面**：`msg_info()`、`msg_ok()`、`msg_error()`、`msg_warn()`、`spinner()`
- **核心实用工具**：`silent()`、`is_alpine()`、`is_verbose_mode()`、`get_header()`
- **系统管理**：`check_or_create_swap()`、`ensure_tput()`

### 依赖关系
- **外部**：`curl` 用于下载头部，`tput` 用于终端控制
- **内部**：`error_handler.func` 用于错误说明

### 集成点
- 使用者：所有其他 `.func` 文件和安装脚本
- 使用：`error_handler.func` 用于错误说明
- 提供：为 `build.func`、`tools.func`、`api.func` 提供核心实用工具

## 文档文件

### 📊 [CORE_FLOWCHART.md](./CORE_FLOWCHART.md)
显示核心函数如何交互和系统验证过程的可视化执行流程。

### 📚 [CORE_FUNCTIONS_REFERENCE.md](./CORE_FUNCTIONS_REFERENCE.md)
所有函数的完整字母顺序参考，包含参数、依赖关系和使用详情。

### 💡 [CORE_USAGE_EXAMPLES.md](./CORE_USAGE_EXAMPLES.md)
显示如何在脚本中使用核心函数和常见模式的实用示例。

### 🔗 [CORE_INTEGRATION.md](./CORE_INTEGRATION.md)
core.func 如何与其他组件集成并提供基础服务。

## 主要功能

### 系统验证
- **Proxmox VE 版本检查**：支持 PVE 8.0-8.9 和 9.0
- **架构检查**：确保 AMD64 架构（排除 PiMox）
- **Shell 检查**：验证 Bash shell 使用
- **Root 检查**：确保 root 权限
- **SSH 检查**：警告外部 SSH 使用

### 用户界面
- **彩色输出**：用于样式化终端输出的 ANSI 颜色代码
- **图标**：不同消息类型的符号图标
- **旋转器**：动画进度指示器
- **格式化消息**：脚本间一致的消息格式

### 核心实用工具
- **静默执行**：使用详细错误报告执行命令
- **OS 检测**：Alpine Linux 检测
- **详细模式**：处理详细输出设置
- **头部管理**：下载并显示应用程序头部
- **交换管理**：检查并创建交换文件

## 常见使用模式

### 基本脚本设置
```bash
# 引用核心函数
source core.func

# 运行系统检查
pve_check
arch_check
shell_check
root_check
```

### 消息显示
```bash
# 显示进度
msg_info "正在安装包..."

# 显示成功
msg_ok "包安装成功"

# 显示错误
msg_error "安装失败"

# 显示警告
msg_warn "此操作可能需要一些时间"
```

### 静默命令执行
```bash
# 使用错误处理静默执行命令
silent apt-get update
silent apt-get install -y package-name
```

## 环境变量

### 核心变量
- `VERBOSE`：启用详细输出模式
- `SILENT_LOGFILE`：静默执行日志文件路径
- `APP`：头部显示的应用程序名称
- `APP_TYPE`：头部路径的应用程序类型（ct/vm）

### 内部变量
- `_CORE_FUNC_LOADED`：防止多次加载
- `__FUNCTIONS_LOADED`：防止多次函数加载
- `RETRY_NUM`：重试尝试次数（默认：10）
- `RETRY_EVERY`：重试间隔秒数（默认：3）

## 错误处理

### 静默执行错误
- 通过 `silent()` 执行的命令将输出捕获到日志文件
- 失败时显示错误代码说明
- 显示日志输出的最后 10 行
- 提供查看完整日志的命令

### 系统检查失败
- 每个系统检查函数以适当的错误消息退出
- 清楚指示问题所在以及如何修复
- 优雅退出，延迟以便用户阅读消息

## 最佳实践

### 脚本初始化
1. 首先引用 `core.func`
2. 尽早运行系统检查
3. 设置错误处理
4. 使用适当的消息函数

### 消息使用
1. 使用 `msg_info()` 进行进度更新
2. 使用 `msg_ok()` 表示成功完成
3. 使用 `msg_error()` 表示失败
4. 使用 `msg_warn()` 表示警告

### 静默执行
1. 对可能失败的命令使用 `silent()`
2. 静默执行后检查返回代码
3. 提供有意义的错误消息

## 故障排除

### 常见问题
1. **Proxmox 版本**：确保运行支持的 PVE 版本
2. **架构**：脚本仅在 AMD64 系统上工作
3. **Shell**：必须使用 Bash shell
4. **权限**：必须以 root 身份运行
5. **网络**：外部连接的 SSH 警告

### 调试模式
启用详细输出进行调试：
```bash
export VERBOSE="yes"
source core.func
```

### 日志文件
检查静默执行日志：
```bash
cat /tmp/silent.$$.log
```

## 相关文档

- [build.func](../build.func/) - 主容器创建脚本
- [error_handler.func](../error_handler.func/) - 错误处理实用工具
- [tools.func](../tools.func/) - 扩展实用函数
- [api.func](../api.func/) - Proxmox API 交互

---

*本文档涵盖为所有 Proxmox Community Scripts 提供基础实用工具的 core.func 文件。*
