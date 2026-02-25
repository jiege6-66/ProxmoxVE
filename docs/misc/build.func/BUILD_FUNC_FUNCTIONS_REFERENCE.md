# build.func 函数参考

## 概述

本文档提供 `build.func` 中所有函数的完整参考，按字母顺序组织，包含详细描述、参数和使用信息。

## 函数类别

### 初始化函数

#### `start()`

**目的**：引用或执行 build.func 时的主入口点
**参数**：无
**返回**：无
**副作用**：

- 检测执行上下文（Proxmox 主机 vs 容器）
- 捕获硬环境变量
- 根据上下文设置 CT_TYPE
- 路由到适当的工作流（install_script 或 update_script）
**依赖关系**：无
**使用的环境变量**：`CT_TYPE`、`APP`、`CTID`

#### `variables()`

**目的**：使用优先级链加载和解析所有配置变量
**参数**：无
**返回**：无
**副作用**：

- 加载应用特定的 .vars 文件
- 加载全局 default.vars 文件
- 应用变量优先级链
- 设置所有配置变量
**依赖关系**：`base_settings()`
**使用的环境变量**：所有配置变量

#### `base_settings()`

**目的**：为所有配置变量设置内置默认值
**参数**：无
**返回**：无
**副作用**：为所有变量设置默认值
**依赖关系**：无
**使用的环境变量**：所有配置变量

### UI 和菜单函数

#### `install_script()`

**目的**：主安装工作流协调器
**参数**：无
**返回**：无
**副作用**：

- 显示安装模式选择菜单
- 协调整个安装过程
- 处理用户交互和验证
**依赖关系**：`variables()`、`build_container()`、`default_var_settings()`
**使用的环境变量**：`APP`、`CTID`、`var_hostname`

#### `advanced_settings()`

**目的**：通过 whiptail 菜单提供高级配置选项
**参数**：无
**返回**：无
**副作用**：

- 显示配置的 whiptail 菜单
- 根据用户输入更新配置变量
- 验证用户选择
**依赖关系**：`select_storage()`、`detect_gpu_devices()`
**使用的环境变量**：所有配置变量

#### `settings_menu()`

**目的**：显示和处理设置配置菜单
**参数**：无
**返回**：无
**副作用**：更新配置变量
**依赖关系**：`advanced_settings()`
**使用的环境变量**：所有配置变量

### 存储函数

#### `select_storage()`

**目的**：处理模板和容器的存储选择
**参数**：无
**返回**：无
**副作用**：

- 解析存储预选
- 如需要提示用户选择存储
- 验证存储可用性
- 设置 var_template_storage 和 var_container_storage
**依赖关系**：`resolve_storage_preselect()`、`choose_and_set_storage_for_file()`
**使用的环境变量**：`var_template_storage`、`var_container_storage`、`TEMPLATE_STORAGE`、`CONTAINER_STORAGE`

#### `resolve_storage_preselect()`

**目的**：解析预选的存储选项
**参数**：

- `storage_type`：存储类型（template 或 container）
**返回**：如果有效则返回存储名称，如果无效则为空
**副作用**：验证存储可用性
**依赖关系**：无
**使用的环境变量**：`var_template_storage`、`var_container_storage`

#### `choose_and_set_storage_for_file()`

**目的**：通过 whiptail 进行交互式存储选择
**参数**：

- `storage_type`：存储类型（template 或 container）
- `content_type`：内容类型（vztmpl 或 rootdir）
**返回**：无
**副作用**：
- 显示 whiptail 菜单
- 更新存储变量
- 验证选择
**依赖关系**：无
**使用的环境变量**：`var_template_storage`、`var_container_storage`

### 容器创建函数

#### `build_container()`

**目的**：验证设置并准备容器创建
**参数**：无
**返回**：无
**副作用**：

- 验证所有配置
- 检查冲突
- 准备容器配置
- 调用 create_lxc_container()
**依赖关系**：`create_lxc_container()`
**使用的环境变量**：所有配置变量

#### `create_lxc_container()`

**目的**：创建实际的 LXC 容器
**参数**：无
**返回**：无
**副作用**：

- 使用基本配置创建 LXC 容器
- 配置网络设置
- 设置存储和挂载点
- 配置功能（FUSE、TUN 等）
- 设置资源限制
- 配置启动选项
- 启动容器
**依赖关系**：`configure_gpu_passthrough()`、`fix_gpu_gids()`
**使用的环境变量**：所有配置变量

### GPU 和硬件函数

#### `detect_gpu_devices()`

**目的**：检测系统上可用的 GPU 硬件
**参数**：无
**返回**：无
**副作用**：

- 扫描 Intel、AMD 和 NVIDIA GPU
- 更新 var_gpu_type 和 var_gpu_devices
- 确定 GPU 功能
**依赖关系**：无
**使用的环境变量**：`var_gpu_type`、`var_gpu_devices`、`GPU_APPS`

#### `configure_gpu_passthrough()`

**目的**：为容器配置 GPU 直通
**参数**：无
**返回**：无
**副作用**：

- 将 GPU 设备条目添加到容器配置
- 配置适当的设备权限
- 设置设备映射
- 更新 /etc/pve/lxc/<ctid>.conf
**依赖关系**：`detect_gpu_devices()`
**使用的环境变量**：`var_gpu`、`var_gpu_type`、`var_gpu_devices`、`CTID`

#### `fix_gpu_gids()`

**目的**：容器创建后修复 GPU 组 ID
**参数**：无
**返回**：无
**副作用**：

- 更新容器中的 GPU 组 ID
- 确保适当的 GPU 访问权限
- 配置 video 和 render 组
**依赖关系**：`configure_gpu_passthrough()`
**使用的环境变量**：`CTID`、`var_gpu_type`

### SSH 配置函数

#### `configure_ssh_settings()`

**目的**：交互式 SSH 密钥和访问配置向导
**参数**：

- `step_info`（可选）：步骤指示器字符串（例如 "Step 17/19"）用于一致的对话框标题
**返回**：无
**副作用**：
- 为 SSH 密钥创建临时文件
- 发现并呈现主机上可用的 SSH 密钥
- 允许手动密钥输入或文件夹/glob 扫描
- 根据用户选择将 `SSH` 变量设置为 "yes" 或 "no"
- 如果提供手动密钥则设置 `SSH_AUTHORIZED_KEY`
- 使用选定的密钥填充 `SSH_KEYS_FILE`
**依赖关系**：`ssh_discover_default_files()`、`ssh_build_choices_from_files()`
**使用的环境变量**：`SSH`、`SSH_AUTHORIZED_KEY`、`SSH_KEYS_FILE`

**SSH 密钥源选项**：

1. `found` - 从自动检测的主机密钥中选择
2. `manual` - 粘贴单个公钥
3. `folder` - 扫描自定义文件夹或 glob 模式
4. `none` - 无 SSH 密钥

**注意**：无论是否配置了 SSH 密钥或密码，始终显示"启用 root SSH 访问？"对话框。这确保用户即使使用自动登录也始终可以启用 SSH 访问。

#### `ssh_discover_default_files()`

**目的**：发现主机系统上的 SSH 公钥文件
**参数**：无
**返回**：发现的密钥文件路径数组
**副作用**：扫描常见的 SSH 密钥位置
**依赖关系**：无
**使用的环境变量**：`var_ssh_import_glob`

#### `ssh_build_choices_from_files()`

**目的**：从 SSH 密钥文件构建 whiptail 检查列表选项
**参数**：

- 要处理的文件路径数组
**返回**：无
**副作用**：
- 为 whiptail 检查列表设置 `CHOICES` 数组
- 使用找到的密钥数量设置 `COUNT` 变量
- 创建密钥标签到内容映射的 `MAPFILE`
**依赖关系**：无
**使用的环境变量**：`CHOICES`、`COUNT`、`MAPFILE`

### 设置持久化函数

#### `default_var_settings()`

**目的**：提供将当前设置保存为默认值
**参数**：无
**返回**：无
**副作用**：

- 提示用户保存设置
- 保存到 default.vars 文件
- 保存到应用特定的 .vars 文件
**依赖关系**：`maybe_offer_save_app_defaults()`
**使用的环境变量**：所有配置变量

#### `maybe_offer_save_app_defaults()`

**目的**：提供保存应用特定默认值
**参数**：无
**返回**：无
**副作用**：

- 提示用户保存应用特定设置
- 保存到 app.vars 文件
- 更新应用特定配置
**依赖关系**：无
**使用的环境变量**：`APP`、`SAVE_APP_DEFAULTS`

### 实用函数

#### `validate_settings()`

**目的**：验证所有配置设置
**参数**：无
**返回**：如果有效则为 0，如果无效则为 1
**副作用**：

- 检查配置冲突
- 验证资源限制
- 验证网络配置
- 验证存储配置
**依赖关系**：无
**使用的环境变量**：所有配置变量

#### `check_conflicts()`

**目的**：检查配置冲突
**参数**：无
**返回**：如果没有冲突则为 0，如果发现冲突则为 1
**副作用**：

- 检查冲突的设置
- 验证资源分配
- 检查网络配置
**依赖关系**：无
**使用的环境变量**：所有配置变量

#### `cleanup_on_error()`

**目的**：错误时清理资源
**参数**：无
**返回**：无
**副作用**：

- 删除部分创建的容器
- 清理临时文件
- 重置配置
**依赖关系**：无
**使用的环境变量**：`CTID`

## 函数调用流程

### 主安装流程

```
start()
├── variables()
│   ├── base_settings()
│   ├── 加载 app.vars
│   └── 加载 default.vars
├── install_script()
│   ├── advanced_settings()
│   │   ├── select_storage()
│   │   │   ├── resolve_storage_preselect()
│   │   │   └── choose_and_set_storage_for_file()
│   │   └── detect_gpu_devices()
│   ├── build_container()
│   │   ├── validate_settings()
│   │   ├── check_conflicts()
│   │   └── create_lxc_container()
│   │       ├── configure_gpu_passthrough()
│   │       └── fix_gpu_gids()
│   └── default_var_settings()
│       └── maybe_offer_save_app_defaults()
```

### 错误处理流程

```
错误检测
├── validate_settings()
│   └── check_conflicts()
├── 错误处理
│   └── cleanup_on_error()
└── 以错误代码退出
```

## 函数依赖关系

### 核心依赖

- `start()` → `install_script()` → `build_container()` → `create_lxc_container()`
- `variables()` → `base_settings()`
- `advanced_settings()` → `select_storage()` → `detect_gpu_devices()`

### 存储依赖

- `select_storage()` → `resolve_storage_preselect()`
- `select_storage()` → `choose_and_set_storage_for_file()`

### GPU 依赖

- `configure_gpu_passthrough()` → `detect_gpu_devices()`
- `fix_gpu_gids()` → `configure_gpu_passthrough()`

### 设置依赖

- `default_var_settings()` → `maybe_offer_save_app_defaults()`

## 函数使用示例

### 基本容器创建

```bash
# 设置必需变量
export APP="plex"
export CTID="100"
export var_hostname="plex-server"

# 调用主函数
start()  # 入口点
# → variables()  # 加载配置
# → install_script()  # 主工作流
# → build_container()  # 创建容器
# → create_lxc_container()  # 实际创建
```

### 高级配置

```bash
# 设置高级变量
export var_os="debian"
export var_version="12"
export var_cpu="4"
export var_ram="4096"
export var_disk="20"

# 调用高级函数
advanced_settings()  # 交互式配置
# → select_storage()  # 存储选择
# → detect_gpu_devices()  # GPU 检测
```

### GPU 直通

```bash
# 启用 GPU 直通
export GPU_APPS="plex"
export var_gpu="nvidia"

# 调用 GPU 函数
detect_gpu_devices()  # 检测硬件
configure_gpu_passthrough()  # 配置直通
fix_gpu_gids()  # 修复权限
```

### 设置持久化

```bash
# 将设置保存为默认值
export SAVE_DEFAULTS="true"
export SAVE_APP_DEFAULTS="true"

# 调用持久化函数
default_var_settings()  # 保存全局默认值
maybe_offer_save_app_defaults()  # 保存应用默认值
```

### 容器资源和 ID 管理

#### `validate_container_id()`
**目的**：验证容器 ID 是否可用。
**参数**：`ctid`（整数）
**返回**：如果可用则为 `0`，如果已使用或无效则为 `1`。
**描述**：检查 `/etc/pve/lxc/` 或 `/etc/pve/qemu-server/` 中的现有配置文件，并验证 LVM 逻辑卷。

#### `get_valid_container_id()`
**目的**：返回下一个可用的未使用容器 ID。
**参数**：`suggested_id`（可选）
**返回**：有效的容器 ID 字符串。
**描述**：如果建议的 ID 已被占用，则递增直到找到可用的 ID。

#### `maxkeys_check()`
**目的**：确保主机内核参数支持大量密钥（某些应用需要）。
**参数**：无
**描述**：检查并可选择更新 `kernel.keys.maxkeys` 和 `kernel.keys.maxbytes`。

#### `get_current_ip()`
**目的**：检索容器的当前 IP 地址。
**参数**：`ctid`（整数）
**返回**：IP 地址字符串。

#### `update_motd_ip()`
**目的**：使用容器的 IP 更新每日消息（MOTD）文件。
**参数**：无

## 函数错误处理

### 验证函数

- `validate_settings()`：如果有效则返回 0，如果无效则返回 1
- `check_conflicts()`：如果没有冲突则返回 0，如果有冲突则返回 1

### 错误恢复

- `cleanup_on_error()`：任何错误时清理
- 错误代码向上传播调用堆栈
- 严重错误导致脚本终止

### 错误类型

1. **配置错误**：无效设置或冲突
2. **资源错误**：资源不足或冲突
3. **网络错误**：无效的网络配置
4. **存储错误**：存储不可用或无效
5. **GPU 错误**：GPU 配置失败
6. **容器创建错误**：LXC 创建失败
