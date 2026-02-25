# api.func 文档

## 概述

`api.func` 文件为 Community Scripts 项目提供 Proxmox API 集成和诊断报告功能。它处理 API 通信、错误报告和向 community-scripts.org API 的状态更新。

## 用途和使用场景

- **API 通信**：向 community-scripts.org API 发送安装和状态数据
- **诊断报告**：报告安装进度和错误以进行分析
- **错误描述**：提供详细的错误代码解释
- **状态更新**：跟踪安装成功/失败状态
- **分析**：贡献匿名使用数据以改进项目

## 快速参考

### 主要函数组
- **错误处理**：`get_error_description()` - 将退出代码转换为人类可读的消息
- **API 通信**：`post_to_api()`、`post_to_api_vm()` - 发送安装数据
- **状态更新**：`post_update_to_api()` - 报告安装完成状态

### 依赖项
- **外部**：用于 HTTP 请求的 `curl` 命令
- **内部**：使用来自其他脚本的环境变量

### 集成点
- 被使用于：所有用于诊断报告的安装脚本
- 使用：来自 build.func 和其他脚本的环境变量
- 提供：API 通信和错误报告服务

## 文档文件

### 📊 [API_FLOWCHART.md](./API_FLOWCHART.md)
显示 API 通信过程和错误处理的可视化执行流程。

### 📚 [API_FUNCTIONS_REFERENCE.md](./API_FUNCTIONS_REFERENCE.md)
所有函数的完整字母顺序参考，包含参数、依赖项和使用详情。

### 💡 [API_USAGE_EXAMPLES.md](./API_USAGE_EXAMPLES.md)
展示如何使用 API 函数和常见模式的实用示例。

### 🔗 [API_INTEGRATION.md](./API_INTEGRATION.md)
api.func 如何与其他组件集成并提供 API 服务。

## 主要特性

### 错误代码描述
- **全面覆盖**：50+ 个错误代码及详细解释
- **LXC 特定错误**：容器创建和管理错误
- **系统错误**：一般系统和网络错误
- **信号错误**：进程终止和信号错误

### API 通信
- **LXC 报告**：发送 LXC 容器安装数据
- **VM 报告**：发送 VM 安装数据
- **状态更新**：报告安装成功/失败
- **诊断数据**：匿名使用分析

### 诊断集成
- **可选报告**：仅在启用诊断时发送数据
- **尊重隐私**：尊重用户隐私设置
- **错误跟踪**：跟踪安装错误以进行改进
- **使用分析**：贡献项目统计数据

## 常见使用模式

### 基本 API 设置
```bash
#!/usr/bin/env bash
# 基本 API 设置

source api.func

# 设置诊断报告
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"

# 报告安装开始
post_to_api
```

### 错误报告
```bash
#!/usr/bin/env bash
source api.func

# 获取错误描述
error_msg=$(get_error_description 127)
echo "错误 127: $error_msg"
# 输出：错误 127: Command not found: Incorrect path or missing dependency.
```

### 状态更新
```bash
#!/usr/bin/env bash
source api.func

# 报告成功安装
post_update_to_api "success" 0

# 报告失败安装
post_update_to_api "failed" 127
```

## 环境变量

### 必需变量
- `DIAGNOSTICS`：启用/禁用诊断报告（"yes"/"no"）
- `RANDOM_UUID`：用于跟踪的唯一标识符

### 可选变量
- `CT_TYPE`：容器类型（1 表示 LXC，2 表示 VM）
- `DISK_SIZE`：磁盘大小（GB）
- `CORE_COUNT`：CPU 核心数
- `RAM_SIZE`：RAM 大小（MB）
- `var_os`：操作系统类型
- `var_version`：操作系统版本
- `DISABLEIP6`：IPv6 禁用设置
- `NSAPP`：命名空间应用程序名称
- `METHOD`：安装方法

### 内部变量
- `POST_UPDATE_DONE`：防止重复状态更新
- `API_URL`：Community scripts API 端点
- `JSON_PAYLOAD`：API 请求负载
- `RESPONSE`：API 响应

## 错误代码分类

### 一般系统错误
- **0-9**：基本系统错误
- **18, 22, 28, 35**：网络和 I/O 错误
- **56, 60**：TLS/SSL 错误
- **125-128**：命令执行错误
- **129-143**：信号错误
- **152**：资源限制错误
- **255**：未知严重错误

### LXC 特定错误
- **100-101**：LXC 安装错误
- **200-209**：LXC 创建和管理错误

### Docker 错误
- **125**：Docker 容器启动错误

## 最佳实践

### 诊断报告
1. 始终检查是否启用诊断
2. 尊重用户隐私设置
3. 使用唯一标识符进行跟踪
4. 报告成功和失败情况

### 错误处理
1. 使用适当的错误代码
2. 提供有意义的错误描述
3. 优雅地处理 API 通信失败
4. 不要因 API 失败而阻止安装

### API 使用
1. 检查 curl 可用性
2. 优雅地处理网络故障
3. 使用适当的 HTTP 方法
4. 包含所有必需数据

## 故障排除

### 常见问题
1. **API 通信失败**：检查网络连接和 curl 可用性
2. **诊断不工作**：验证 DIAGNOSTICS 设置和 RANDOM_UUID
3. **缺少错误描述**：检查错误代码覆盖范围
4. **重复更新**：POST_UPDATE_DONE 防止重复

### 调试模式
启用诊断报告进行调试：
```bash
export DIAGNOSTICS="yes"
export RANDOM_UUID="$(uuidgen)"
```

### API 测试
测试 API 通信：
```bash
source api.func
export DIAGNOSTICS="yes"
export RANDOM_UUID="test-$(date +%s)"
post_to_api
```

## 相关文档

- [core.func](../core.func/) - 核心实用程序和错误处理
- [error_handler.func](../error_handler.func/) - 错误处理实用程序
- [build.func](../build.func/) - 带 API 集成的容器创建
- [tools.func](../tools.func/) - 带 API 集成的扩展实用程序

---

*本文档涵盖 api.func 文件，该文件为所有 Proxmox Community Scripts 提供 API 通信和诊断报告。*
