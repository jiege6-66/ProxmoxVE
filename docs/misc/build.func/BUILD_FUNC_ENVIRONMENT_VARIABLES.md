# build.func 环境变量参考

## 概述

本文档提供 `build.func` 中使用的所有环境变量的完整参考，按类别和使用上下文组织。

## 变量类别

### 核心容器变量

| 变量  | 描述                                  | 默认值   | 设置位置    | 使用位置           |
| --------- | -------------------------------------------- | --------- | ----------- | ------------------ |
| `APP`     | 应用程序名称（例如 "plex"、"nextcloud"） | -         | Environment | 全局         |
| `NSAPP`   | 命名空间应用程序名称                   | `$APP`    | Environment | 全局         |
| `CTID`    | 容器 ID                                 | -         | Environment | 容器创建 |
| `CT_TYPE` | 容器类型（"install" 或 "update"）       | "install" | Environment | 入口点        |
| `CT_NAME` | 容器名称                               | `$APP`    | Environment | 容器创建 |

### 操作系统变量

| 变量       | 描述                | 默认值        | 设置位置          | 使用位置            |
| -------------- | -------------------------- | -------------- | --------------- | ------------------ |
| `var_os`       | 操作系统选择 | "debian"       | base_settings() | OS 选择       |
| `var_version`  | OS 版本                 | "12"           | base_settings() | 模板选择  |
| `var_template` | 模板名称              | 自动生成 | base_settings() | 模板下载  |

### 资源配置变量

| 变量     | 描述             | 默认值     | 设置位置          | 使用位置            |
| ------------ | ----------------------- | ----------- | --------------- | ------------------ |
| `var_cpu`    | CPU 核心数               | "2"         | base_settings() | 容器创建 |
| `var_ram`    | RAM（MB）               | "2048"      | base_settings() | 容器创建 |
| `var_disk`   | 磁盘大小（GB）         | "8"         | base_settings() | 容器创建 |
| `DISK_SIZE`  | 磁盘大小（替代） | `$var_disk` | Environment     | 容器创建 |
| `CORE_COUNT` | CPU 核心数（替代）  | `$var_cpu`  | Environment     | 容器创建 |
| `RAM_SIZE`   | RAM 大小（替代）  | `$var_ram`  | Environment     | 容器创建 |

### 网络配置变量

| 变量      | 描述                     | 默认值        | 设置位置          | 使用位置        |
| ------------- | ------------------------------- | -------------- | --------------- | -------------- |
| `var_net`     | 网络接口               | "vmbr0"        | base_settings() | 网络配置 |
| `var_bridge`  | 桥接接口                | "vmbr0"        | base_settings() | 网络配置 |
| `var_gateway` | 网关 IP                      | "192.168.1.1"  | base_settings() | 网络配置 |
| `var_ip`      | 容器 IP 地址            | -              | 用户输入      | 网络配置 |
| `var_ipv6`    | IPv6 地址                    | -              | 用户输入      | 网络配置 |
| `var_vlan`    | VLAN ID                         | -              | 用户输入      | 网络配置 |
| `var_mtu`     | MTU 大小                        | "1500"         | base_settings() | 网络配置 |
| `var_mac`     | MAC 地址                     | 自动生成 | base_settings() | 网络配置 |
| `NET`         | 网络接口（替代） | `$var_net`     | Environment     | 网络配置 |
| `BRG`         | 桥接接口（替代）  | `$var_bridge`  | Environment     | 网络配置 |
| `GATE`        | 网关 IP（替代）        | `$var_gateway` | Environment     | 网络配置 |
| `IPV6_METHOD` | IPv6 配置方法       | "none"         | Environment     | 网络配置 |
| `VLAN`        | VLAN ID（替代）           | `$var_vlan`    | Environment     | 网络配置 |
| `MTU`         | MTU 大小（替代）          | `$var_mtu`     | Environment     | 网络配置 |
| `MAC`         | MAC 地址（替代）       | `$var_mac`     | Environment     | 网络配置 |

### 存储配置变量

| 变量                | 描述                     | 默认值                  | 设置位置           | 使用位置           |
| ----------------------- | ------------------------------- | ------------------------ | ---------------- | ----------------- |
| `var_template_storage`  | 模板存储           | -                        | select_storage() | 模板存储  |
| `var_container_storage` | 容器磁盘存储     | -                        | select_storage() | 容器存储 |
| `TEMPLATE_STORAGE`      | 模板存储（替代）  | `$var_template_storage`  | Environment      | 模板存储  |
| `CONTAINER_STORAGE`     | 容器存储（替代） | `$var_container_storage` | Environment      | 容器存储 |

### 功能标志

| 变量         | 描述                    | 默认值 | 设置位置                          | 使用位置            |
| ---------------- | ------------------------------ | ------- | ------------------------------- | ------------------ |
| `var_fuse`       | 启用 FUSE 支持            | "no"    | CT 脚本 / 高级设置   | 容器功能 |
| `var_tun`        | 启用 TUN/TAP 支持         | "no"    | CT 脚本 / 高级设置   | 容器功能 |
| `var_nesting`    | 启用嵌套支持         | "1"     | CT 脚本 / 高级设置   | 容器功能 |
| `var_keyctl`     | 启用 keyctl 支持          | "0"     | CT 脚本 / 高级设置   | 容器功能 |
| `var_mknod`      | 允许设备节点创建     | "0"     | CT 脚本 / 高级设置   | 容器功能 |
| `var_mount_fs`   | 允许的文件系统挂载      | ""      | CT 脚本 / 高级设置   | 容器功能 |
| `var_protection` | 启用容器保护    | "no"    | CT 脚本 / 高级设置   | 容器创建 |
| `var_timezone`   | 容器时区             | ""      | CT 脚本 / 高级设置   | 容器创建 |
| `var_verbose`    | 启用详细输出          | "no"    | Environment / 高级设置 | 日志            |
| `var_ssh`        | 启用 SSH 密钥配置    | "no"    | CT 脚本 / 高级设置   | SSH 设置          |
| `ENABLE_FUSE`    | FUSE 标志（内部）           | "no"    | 高级设置               | 容器创建 |
| `ENABLE_TUN`     | TUN/TAP 标志（内部）        | "no"    | 高级设置               | 容器创建 |
| `ENABLE_NESTING` | 嵌套标志（内部）        | "1"     | 高级设置               | 容器创建 |
| `ENABLE_KEYCTL`  | Keyctl 标志（内部）         | "0"     | 高级设置               | 容器创建 |
| `ENABLE_MKNOD`   | Mknod 标志（内部）          | "0"     | 高级设置               | 容器创建 |
| `PROTECT_CT`     | 保护标志（内部）     | "no"    | 高级设置               | 容器创建 |
| `CT_TIMEZONE`    | 时区设置（内部）    | ""      | 高级设置               | 容器创建 |
| `VERBOSE`        | 详细模式标志              | "no"    | Environment                     | 日志            |
| `SSH`            | SSH 访问标志                | "no"    | 高级设置               | SSH 设置          |

### APT Cacher 配置

| 变量           | 描述              | 默认值 | 设置位置                        | 使用位置             |
| ------------------ | ------------------------ | ------- | ----------------------------- | ------------------- |
| `var_apt_cacher`   | 启用 APT cacher 代理  | "no"    | CT 脚本 / 高级设置 | 包管理  |
| `var_apt_cacher_ip`| APT cacher 服务器 IP     | ""      | CT 脚本 / 高级设置 | 包管理  |
| `APT_CACHER`       | APT cacher 标志          | "no"    | 高级设置             | 容器创建  |
| `APT_CACHER_IP`    | APT cacher IP（内部） | ""      | 高级设置             | 容器创建  |

### GPU 直通变量

| 变量     | 描述                     | 默认值 | 设置位置                                      | 使用位置            |
| ------------ | ------------------------------- | ------- | ------------------------------------------- | ------------------ |
| `var_gpu`    | 启用 GPU 直通          | "no"    | CT 脚本 / Environment / 高级设置 | GPU 直通    |
| `ENABLE_GPU` | GPU 直通标志（内部） | "no"    | 高级设置                           | 容器创建 |

**注意**：GPU 直通通过 `var_gpu` 控制。受益于 GPU 加速的应用（媒体服务器、AI/ML、转码）在其 CT 脚本中默认设置 `var_gpu=yes`。

**默认启用 GPU 的应用**：

- 媒体：jellyfin、plex、emby、channels、ersatztv、tunarr、immich
- 转码：tdarr、unmanic、fileflows
- AI/ML：ollama、openwebui
- NVR：frigate

**使用示例**：

```bash
# 为特定安装禁用 GPU
var_gpu=no bash -c "$(curl -fsSL https://...jellyfin.sh)"

# 为没有默认 GPU 支持的应用启用 GPU
var_gpu=yes bash -c "$(curl -fsSL https://...debian.sh)"

# 在 default.vars 中为所有应用设置
echo "var_gpu=yes" >> /usr/local/community-scripts/default.vars
```

### API 和诊断变量

| 变量      | 描述              | 默认值   | 设置位置      | 使用位置           |
| ------------- | ------------------------ | --------- | ----------- | ----------------- |
| `DIAGNOSTICS` | 启用诊断模式  | "false"   | Environment | 诊断       |
| `METHOD`      | 安装方法      | "install" | Environment | 安装流程 |
| `RANDOM_UUID` | 用于跟踪的随机 UUID | -         | Environment | 日志           |
| `API_TOKEN`   | Proxmox API 令牌        | -         | Environment | API 调用         |
| `API_USER`    | Proxmox API 用户         | -         | Environment | API 调用         |

### 设置持久化变量

| 变量            | 描述                | 默认值                                           | 设置位置      | 使用位置              |
| ------------------- | -------------------------- | ------------------------------------------------- | ----------- | -------------------- |
| `SAVE_DEFAULTS`     | 保存设置为默认值  | "false"                                           | 用户输入  | 设置持久化 |
| `SAVE_APP_DEFAULTS` | 保存应用特定默认值 | "false"                                           | 用户输入  | 设置持久化 |
| `DEFAULT_VARS_FILE` | default.vars 路径       | "/usr/local/community-scripts/default.vars"       | Environment | 设置持久化 |
| `APP_DEFAULTS_FILE` | app.vars 路径           | "/usr/local/community-scripts/defaults/$APP.vars" | Environment | 设置持久化 |

## 变量优先级链

变量按以下顺序解析（从高到低优先级）：

1. **硬环境变量**：脚本执行前设置
2. **应用特定的 .vars 文件**：`/usr/local/community-scripts/defaults/<app>.vars`
3. **全局 default.vars 文件**：`/usr/local/community-scripts/default.vars`
4. **内置默认值**：在 `base_settings()` 函数中设置

## 非交互式使用的关键变量

对于静默/非交互式执行，必须设置这些变量：

```bash
# 核心容器设置
export APP="plex"
export CTID="100"
export var_hostname="plex-server"

# OS 选择
export var_os="debian"
export var_version="12"

# 资源分配
export var_cpu="4"
export var_ram="4096"
export var_disk="20"

# 网络配置
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.100"

# 存储选择
export var_template_storage="local"
export var_container_storage="local"

# 功能标志
export ENABLE_FUSE="true"
export ENABLE_TUN="true"
export SSH="true"
```

## 环境变量使用模式

### 1. 容器创建

```bash
# 基本容器创建
export APP="nextcloud"
export CTID="101"
export var_hostname="nextcloud-server"
export var_os="debian"
export var_version="12"
export var_cpu="2"
export var_ram="2048"
export var_disk="10"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.101"
export var_template_storage="local"
export var_container_storage="local"
```

### 2. GPU 直通

```bash
# 启用 GPU 直通
export GPU_APPS="plex,jellyfin,emby"
export var_gpu="intel"
export ENABLE_PRIVILEGED="true"
```

### 3. 高级网络配置

```bash
# VLAN 和 IPv6 配置
export var_vlan="100"
export var_ipv6="2001:db8::100"
export IPV6_METHOD="static"
export var_mtu="9000"
```

### 4. 存储配置

```bash
# 自定义存储位置
export var_template_storage="nfs-storage"
export var_container_storage="ssd-storage"
```

## 变量验证

脚本在多个点验证变量：

1. **容器 ID 验证**：必须唯一且在有效范围内
2. **IP 地址验证**：必须是有效的 IPv4/IPv6 格式
3. **存储验证**：必须存在并支持所需的内容类型
4. **资源验证**：必须在合理限制内
5. **网络验证**：必须是有效的网络配置

## 常见变量组合

### 开发容器

```bash
export APP="dev-container"
export CTID="200"
export var_hostname="dev-server"
export var_os="ubuntu"
export var_version="22.04"
export var_cpu="4"
export var_ram="4096"
export var_disk="20"
export ENABLE_NESTING="true"
export ENABLE_PRIVILEGED="true"
```

### 带 GPU 的媒体服务器

```bash
export APP="plex"
export CTID="300"
export var_hostname="plex-server"
export var_os="debian"
export var_version="12"
export var_cpu="6"
export var_ram="8192"
export var_disk="50"
export GPU_APPS="plex"
export var_gpu="nvidia"
export ENABLE_PRIVILEGED="true"
```

### 轻量级服务

```bash
export APP="nginx"
export CTID="400"
export var_hostname="nginx-proxy"
export var_os="alpine"
export var_version="3.18"
export var_cpu="1"
export var_ram="512"
export var_disk="2"
export ENABLE_UNPRIVILEGED="true"
```
