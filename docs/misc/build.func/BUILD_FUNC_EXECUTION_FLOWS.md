# build.func 执行流程

## 概述

本文档详细介绍 `build.func` 中不同安装模式和场景的执行流程，包括变量优先级、决策树和工作流模式。

## 安装模式

### 1. 默认安装流程

**目的**：使用内置默认值，最少用户交互
**用例**：使用标准设置快速创建容器

```
默认安装流程：
├── start()
│   ├── 检测执行上下文
│   ├── 捕获硬环境变量
│   └── 设置 CT_TYPE="install"
├── install_script()
│   ├── 显示安装模式菜单
│   ├── 用户选择 "Default Install"
│   └── 使用默认值继续
├── variables()
│   ├── base_settings()  # 设置内置默认值
│   ├── 加载 app.vars（如果存在）
│   ├── 加载 default.vars（如果存在）
│   └── 应用变量优先级
├── build_container()
│   ├── validate_settings()
│   ├── check_conflicts()
│   └── create_lxc_container()
└── default_var_settings()
    └── 提供保存为默认值
```

**主要特点**：
- 最少用户提示
- 使用内置默认值
- 快速执行
- 适合标准部署

### 2. 高级安装流程

**目的**：通过 whiptail 菜单进行完整交互式配置
**用例**：完全控制的自定义容器配置

```
高级安装流程：
├── start()
│   ├── 检测执行上下文
│   ├── 捕获硬环境变量
│   └── 设置 CT_TYPE="install"
├── install_script()
│   ├── 显示安装模式菜单
│   ├── 用户选择 "Advanced Install"
│   └── 继续高级配置
├── variables()
│   ├── base_settings()  # 设置内置默认值
│   ├── 加载 app.vars（如果存在）
│   ├── 加载 default.vars（如果存在）
│   └── 应用变量优先级
├── advanced_settings()
│   ├── OS 选择菜单
│   ├── 资源配置菜单
│   ├── 网络配置菜单
│   ├── select_storage()
│   │   ├── resolve_storage_preselect()
│   │   └── choose_and_set_storage_for_file()
│   ├── GPU 配置菜单
│   │   └── detect_gpu_devices()
│   └── 功能标志菜单
├── build_container()
│   ├── validate_settings()
│   ├── check_conflicts()
│   └── create_lxc_container()
└── default_var_settings()
    └── 提供保存为默认值
```

**主要特点**：
- 完整交互式配置
- 所有选项的 Whiptail 菜单
- 完全控制设置
- 适合自定义部署

### 3. 我的默认值流程

**目的**：从全局 default.vars 文件加载设置
**用例**：使用之前保存的全局默认值

```
我的默认值流程：
├── start()
│   ├── 检测执行上下文
│   ├── 捕获硬环境变量
│   └── 设置 CT_TYPE="install"
├── install_script()
│   ├── 显示安装模式菜单
│   ├── 用户选择 "My Defaults"
│   └── 使用加载的默认值继续
├── variables()
│   ├── base_settings()  # 设置内置默认值
│   ├── 加载 app.vars（如果存在）
│   ├── 加载 default.vars  # 加载全局默认值
│   └── 应用变量优先级
├── build_container()
│   ├── validate_settings()
│   ├── check_conflicts()
│   └── create_lxc_container()
└── default_var_settings()
    └── 提供保存为默认值
```

**主要特点**：
- 使用全局 default.vars 文件
- 最少用户交互
- 与之前设置一致
- 适合重复部署

### 4. 应用默认值流程

**目的**：从应用特定的 .vars 文件加载设置
**用例**：使用之前保存的应用特定默认值

```
应用默认值流程：
├── start()
│   ├── 检测执行上下文
│   ├── 捕获硬环境变量
│   └── 设置 CT_TYPE="install"
├── install_script()
│   ├── 显示安装模式菜单
│   ├── 用户选择 "App Defaults"
│   └── 继续应用特定默认值
├── variables()
│   ├── base_settings()  # 设置内置默认值
│   ├── 加载 app.vars  # 加载应用特定默认值
│   ├── 加载 default.vars（如果存在）
│   └── 应用变量优先级
├── build_container()
│   ├── validate_settings()
│   ├── check_conflicts()
│   └── create_lxc_container()
└── default_var_settings()
    └── 提供保存为默认值
```

**主要特点**：
- 使用应用特定的 .vars 文件
- 最少用户交互
- 应用优化设置
- 适合应用特定部署

## 变量优先级链

### 优先级顺序（从高到低）

1. **硬环境变量**：脚本执行前设置
2. **应用特定的 .vars 文件**：`/usr/local/community-scripts/defaults/<app>.vars`
3. **全局 default.vars 文件**：`/usr/local/community-scripts/default.vars`
4. **内置默认值**：在 `base_settings()` 函数中设置

### 变量解析过程

```
变量解析：
├── 在 start() 捕获硬环境变量
├── 在 base_settings() 加载内置默认值
├── 加载全局 default.vars（如果存在）
├── 加载应用特定的 .vars（如果存在）
└── 应用优先级链
    ├── 硬环境变量覆盖所有
    ├── App.vars 覆盖 default.vars 和内置值
    ├── Default.vars 覆盖内置值
    └── 内置值是后备默认值
```

## 存储选择逻辑

### 存储解析流程

```
存储选择：
├── 检查存储是否预选
│   ├── var_template_storage 已设置？→ 验证并使用
│   └── var_container_storage 已设置？→ 验证并使用
├── 计算可用存储选项数量
│   ├── 只有 1 个选项 → 自动选择
│   └── 多个选项 → 提示用户
├── 通过 whiptail 用户选择
│   ├── 模板存储选择
│   └── 容器存储选择
└── 验证选定的存储
    ├── 检查可用性
    ├── 检查内容类型支持
    └── 继续选择
```

### 存储验证

```
存储验证：
├── 检查存储是否存在
├── 检查存储是否在线
├── 检查内容类型支持
│   ├── 模板存储：vztmpl 支持
│   └── 容器存储：rootdir 支持
├── 检查可用空间
└── 验证权限
```

## GPU 直通流程

### GPU 检测和配置

```
GPU 直通流程：
├── detect_gpu_devices()
│   ├── 扫描 Intel GPU
│   │   ├── 检查 i915 驱动
│   │   └── 检测设备
│   ├── 扫描 AMD GPU
│   │   ├── 检查 AMDGPU 驱动
│   │   └── 检测设备
│   └── 扫描 NVIDIA GPU
│       ├── 检查 NVIDIA 驱动
│       ├── 检测设备
│       └── 检查 CUDA 支持
├── 检查 GPU 直通资格
│   ├── 应用是否在 GPU_APPS 列表中？
│   ├── 容器是否为特权模式？
│   └── 如果符合条件则继续
├── GPU 选择逻辑
│   ├── 单个 GPU 类型 → 自动选择
│   └── 多个 GPU 类型 → 提示用户
├── configure_gpu_passthrough()
│   ├── 添加 GPU 设备条目
│   ├── 配置权限
│   └── 更新容器配置
└── fix_gpu_gids()
    ├── 更新 GPU 组 ID
    └── 配置访问权限
```

### GPU 资格检查

```
GPU 资格：
├── 检查应用支持
│   ├── APP 是否在 GPU_APPS 列表中？
│   └── 如果支持则继续
├── 检查容器权限
│   ├── ENABLE_PRIVILEGED="true"？
│   └── 如果为特权则继续
└── 检查硬件可用性
    ├── 是否检测到 GPU？
    └── 如果可用则继续
```

## 网络配置流程

### 网络设置过程

```
网络配置：
├── 基本网络设置
│   ├── var_net（网络接口）
│   ├── var_bridge（桥接接口）
│   └── var_gateway（网关 IP）
├── IP 配置
│   ├── var_ip（IPv4 地址）
│   ├── var_ipv6（IPv6 地址）
│   └── IPV6_METHOD（IPv6 方法）
├── 高级网络设置
│   ├── var_vlan（VLAN ID）
│   ├── var_mtu（MTU 大小）
│   └── var_mac（MAC 地址）
└── 网络验证
    ├── 检查 IP 格式
    ├── 检查网关可达性
    └── 验证网络配置
```

## 容器创建流程

### LXC 容器创建过程

```
容器创建：
├── create_lxc_container()
│   ├── 创建基本容器
│   ├── 配置网络
│   ├── 设置存储
│   ├── 配置功能
│   ├── 设置资源限制
│   ├── 配置启动
│   └── 启动容器
├── 创建后配置
│   ├── 等待网络
│   ├── 配置 GPU（如果启用）
│   ├── 设置 SSH 密钥
│   └── 运行安装后脚本
└── 完成
    ├── 显示容器信息
    ├── 显示访问详情
    └── 提供后续步骤
```

## 错误处理流程

### 验证错误流程

```
验证错误流程：
├── validate_settings()
│   ├── 检查配置有效性
│   └── 如果无效则返回错误
├── check_conflicts()
│   ├── 检查冲突
│   └── 如果发现冲突则返回错误
├── 错误处理
│   ├── 显示错误消息
│   ├── cleanup_on_error()
│   └── 以错误代码退出
└── 用户通知
    ├── 显示错误详情
    └── 建议修复
```

### 存储错误流程

```
存储错误流程：
├── 存储选择失败
├── 重试存储选择
│   ├── 显示可用选项
│   └── 允许用户重试
├── 存储验证失败
│   ├── 显示验证错误
│   └── 允许用户修复
└── 回退到默认存储
    ├── 使用后备存储
    └── 继续创建
```

### GPU 错误流程

```
GPU 错误流程：
├── GPU 检测失败
├── 回退到无 GPU
│   ├── 禁用 GPU 直通
│   └── 继续无 GPU
├── GPU 配置失败
│   ├── 显示配置错误
│   └── 允许用户重试
└── GPU 权限错误
    ├── 修复 GPU 权限
    └── 重试配置
```

## 集成流程

### 与安装脚本集成

```
安装脚本集成：
├── build.func 创建容器
├── 容器成功启动
├── 安装脚本执行
│   ├── 下载并安装应用
│   ├── 配置应用设置
│   └── 设置服务
└── 安装后配置
    ├── 验证安装
    ├── 配置访问
    └── 显示完成信息
```

### 与 Proxmox API 集成

```
Proxmox API 集成：
├── API 身份验证
├── 通过 API 创建容器
├── 通过 API 更新配置
├── 通过 API 监控状态
└── 通过 API 处理错误
```

## 性能考虑

### 执行时间优化

```
性能优化：
├── 尽可能并行操作
├── 默认模式下最少用户交互
├── 高效存储选择
├── 优化 GPU 检测
└── 简化验证
```

### 资源使用

```
资源使用：
├── 最小内存占用
├── 高效磁盘使用
├── 优化网络使用
└── 最小 CPU 开销
```
