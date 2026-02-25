# build.func 文档

## 概述

本目录包含 `build.func` 脚本的完整文档，该脚本是 Community Scripts 项目中用于创建 Proxmox LXC 容器的核心编排脚本。

## 文档文件

### 🎛️ [BUILD_FUNC_ADVANCED_SETTINGS.md](./BUILD_FUNC_ADVANCED_SETTINGS.md)
28 步高级设置向导的完整参考，包括所有可配置选项及其继承行为。

**内容：**
- 所有 28 个向导步骤的说明
- 默认值继承
- 功能矩阵（何时启用各项功能）
- 确认摘要格式
- 使用示例

### 📊 [BUILD_FUNC_FLOWCHART.md](./BUILD_FUNC_FLOWCHART.md)
可视化 ASCII 流程图，展示主要执行流程、决策树和 build.func 脚本中的关键决策点。

**内容：**
- 主执行流程图
- 安装模式选择流程
- 存储选择工作流
- GPU 直通决策逻辑
- 变量优先级链
- 错误处理流程
- 集成点

### 🔧 [BUILD_FUNC_ENVIRONMENT_VARIABLES.md](./BUILD_FUNC_ENVIRONMENT_VARIABLES.md)
build.func 中使用的所有环境变量的完整参考，按类别和使用上下文组织。

**内容：**
- 核心容器变量
- 操作系统变量
- 资源配置变量
- 网络配置变量
- 存储配置变量
- 功能标志
- GPU 直通变量
- API 和诊断变量
- 设置持久化变量
- 变量优先级链
- 非交互式使用的关键变量
- 常见变量组合

### 📚 [BUILD_FUNC_FUNCTIONS_REFERENCE.md](./BUILD_FUNC_FUNCTIONS_REFERENCE.md)
按字母顺序排列的函数参考，包含详细描述、参数、依赖关系和使用信息。

**内容：**
- 初始化函数
- UI 和菜单函数
- 存储函数
- 容器创建函数
- GPU 和硬件函数
- 设置持久化函数
- 实用工具函数
- 函数调用流程
- 函数依赖关系
- 函数使用示例
- 函数错误处理

### 🔄 [BUILD_FUNC_EXECUTION_FLOWS.md](./BUILD_FUNC_EXECUTION_FLOWS.md)
不同安装模式和场景的详细执行流程，包括变量优先级和决策树。

**内容：**
- 默认安装流程
- 高级安装流程
- 我的默认值流程
- 应用默认值流程
- 变量优先级链
- 存储选择逻辑
- GPU 直通流程
- 网络配置流程
- 容器创建流程
- 错误处理流程
- 集成流程
- 性能考虑

### 🏗️ [BUILD_FUNC_ARCHITECTURE.md](./BUILD_FUNC_ARCHITECTURE.md)
高层架构概述，包括模块依赖关系、数据流、集成点和系统架构。

**内容：**
- 高层架构图
- 模块依赖关系
- 数据流架构
- 集成架构
- 系统架构组件
- 用户界面组件
- 安全架构
- 性能架构
- 部署架构
- 维护架构
- 未来架构考虑

### 💡 [BUILD_FUNC_USAGE_EXAMPLES.md](./BUILD_FUNC_USAGE_EXAMPLES.md)
涵盖常见场景、CLI 示例和环境变量组合的实用示例。

**内容：**
- 基本使用示例
- 静默/非交互式示例
- 网络配置示例
- 存储配置示例
- 功能配置示例
- 设置持久化示例
- 错误处理示例
- 集成示例
- 最佳实践

## 快速入门指南

### 新用户
1. 从 [BUILD_FUNC_FLOWCHART.md](./BUILD_FUNC_FLOWCHART.md) 开始了解整体流程
2. 查看 [BUILD_FUNC_ENVIRONMENT_VARIABLES.md](./BUILD_FUNC_ENVIRONMENT_VARIABLES.md) 了解配置选项
3. 参考 [BUILD_FUNC_USAGE_EXAMPLES.md](./BUILD_FUNC_USAGE_EXAMPLES.md) 中的示例

### 开发者
1. 阅读 [BUILD_FUNC_ARCHITECTURE.md](./BUILD_FUNC_ARCHITECTURE.md) 了解系统概述
2. 学习 [BUILD_FUNC_FUNCTIONS_REFERENCE.md](./BUILD_FUNC_FUNCTIONS_REFERENCE.md) 了解函数详情
3. 查看 [BUILD_FUNC_EXECUTION_FLOWS.md](./BUILD_FUNC_EXECUTION_FLOWS.md) 了解实现细节

### 系统管理员
1. 重点关注 [BUILD_FUNC_USAGE_EXAMPLES.md](./BUILD_FUNC_USAGE_EXAMPLES.md) 了解部署场景
2. 查看 [BUILD_FUNC_ENVIRONMENT_VARIABLES.md](./BUILD_FUNC_ENVIRONMENT_VARIABLES.md) 了解配置管理
3. 检查 [BUILD_FUNC_ARCHITECTURE.md](./BUILD_FUNC_ARCHITECTURE.md) 了解安全和性能考虑

## 核心概念

### 变量优先级
变量按以下顺序解析（从高到低优先级）：
1. 硬环境变量（脚本执行前设置）
2. 应用特定的 .vars 文件（`/usr/local/community-scripts/defaults/<app>.vars`）
3. 全局 default.vars 文件（`/usr/local/community-scripts/default.vars`）
4. 内置默认值（在 `base_settings()` 函数中设置）

### 安装模式
- **默认安装**：使用内置默认值，最少提示
- **高级安装**：通过 whiptail 进行完整交互式配置
- **我的默认值**：从全局 default.vars 文件加载
- **应用默认值**：从应用特定的 .vars 文件加载

### 存储选择逻辑
1. 如果内容类型只有 1 个存储 → 自动选择
2. 如果通过环境变量预选 → 验证并使用
3. 否则 → 通过 whiptail 提示用户

### GPU 直通流程
1. 检测硬件（Intel/AMD/NVIDIA）
2. 检查应用是否在 GPU_APPS 列表中或容器是否为特权模式
3. 如果只有单个 GPU 类型则自动选择，如果有多个则提示
4. 使用适当的设备条目配置 `/etc/pve/lxc/<ctid>.conf`
5. 创建后修复 GID 以匹配容器的 video/render 组

## 常见用例

### 基本容器创建
```bash
export APP="plex"
export CTID="100"
export var_hostname="plex-server"
export var_os="debian"
export var_version="12"
export var_cpu="4"
export var_ram="4096"
export var_disk="20"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.100"
export var_template_storage="local"
export var_container_storage="local"

source build.func
```

### GPU 直通
```bash
export APP="jellyfin"
export CTID="101"
export var_hostname="jellyfin-server"
export var_os="debian"
export var_version="12"
export var_cpu="8"
export var_ram="16384"
export var_disk="30"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.101"
export var_template_storage="local"
export var_container_storage="local"
export GPU_APPS="jellyfin"
export var_gpu="nvidia"
export ENABLE_PRIVILEGED="true"

source build.func
```

### 静默/非交互式部署
```bash
#!/bin/bash
# 自动化部署
export APP="nginx"
export CTID="102"
export var_hostname="nginx-proxy"
export var_os="alpine"
export var_version="3.18"
export var_cpu="1"
export var_ram="512"
export var_disk="2"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.102"
export var_template_storage="local"
export var_container_storage="local"
export ENABLE_UNPRIVILEGED="true"

source build.func
```

## 故障排除

### 常见问题
1. **容器创建失败**：检查资源可用性和配置有效性
2. **存储错误**：验证存储是否存在并支持所需的内容类型
3. **网络错误**：验证网络配置和 IP 地址可用性
4. **GPU 直通问题**：检查硬件检测和容器权限
5. **权限错误**：验证用户权限和容器权限

### 调试模式
启用详细输出进行调试：
```bash
export VERBOSE="true"
export DIAGNOSTICS="true"
source build.func
```

### 日志文件
检查系统日志以获取详细的错误信息：
- `/var/log/syslog`
- `/var/log/pve/lxc/<ctid>.log`
- 容器特定日志

## 贡献

为 build.func 文档做贡献时：
1. 更新相关文档文件
2. 为新功能添加示例
3. 如需要更新架构图
4. 提交前测试所有示例
5. 遵循现有文档风格

## 相关文档

- [主 README](../../README.md) - 项目概述
- [安装指南](../../install/) - 安装脚本
- [容器模板](../../ct/) - 容器模板
- [工具](../../tools/) - 附加工具和实用程序

## 支持

如有问题和疑问：
1. 首先查看本文档
2. 查看[故障排除部分](#故障排除)
3. 检查项目仓库中的现有问题
4. 创建包含详细信息的新问题

---

*最后更新：$(date)*
*文档版本：1.0*
