# build.func 使用示例

## 概述

本文档提供 `build.func` 的实用示例，涵盖常见场景、CLI 示例和环境变量组合。

## 基本使用示例

### 1. 简单容器创建

**场景**：创建基本的 Plex 媒体服务器容器

```bash
# 设置基本环境变量
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

# 执行 build.func
source build.func
```

**预期输出**：
```
正在创建 Plex 容器...
容器 ID：100
主机名：plex-server
OS：Debian 12
资源：4 CPU，4GB RAM，20GB 磁盘
网络：192.168.1.100/24
容器创建成功！
```

### 2. 高级配置

**场景**：使用自定义设置创建 Nextcloud 容器

```bash
# 设置高级环境变量
export APP="nextcloud"
export CTID="101"
export var_hostname="nextcloud-server"
export var_os="ubuntu"
export var_version="22.04"
export var_cpu="6"
export var_ram="8192"
export var_disk="50"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.101"
export var_vlan="100"
export var_mtu="9000"
export var_template_storage="ssd-storage"
export var_container_storage="ssd-storage"
export var_fuse="yes"
export var_tun="yes"
export SSH="true"

# 执行 build.func
source build.func
```

### 3. GPU 直通配置

**场景**：创建带 NVIDIA GPU 直通的 Jellyfin 容器

```bash
# 设置 GPU 直通变量
export APP="jellyfin"
export CTID="102"
export var_hostname="jellyfin-server"
export var_os="debian"
export var_version="12"
export var_cpu="8"
export var_ram="16384"
export var_disk="30"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.102"
export var_template_storage="local"
export var_container_storage="local"
export GPU_APPS="jellyfin"
export var_gpu="nvidia"
export ENABLE_PRIVILEGED="true"
export ENABLE_FUSE="true"
export ENABLE_TUN="true"

# 执行 build.func
source build.func
```

## 静默/非交互式示例

### 1. 自动化部署

**场景**：无需用户交互部署多个容器

```bash
#!/bin/bash
# 自动化部署脚本

# 创建容器的函数
create_container() {
    local app=$1
    local ctid=$2
    local ip=$3

    export APP="$app"
    export CTID="$ctid"
    export var_hostname="${app}-server"
    export var_os="debian"
    export var_version="12"
    export var_cpu="2"
    export var_ram="2048"
    export var_disk="10"
    export var_net="vmbr0"
    export var_gateway="192.168.1.1"
    export var_ip="$ip"
    export var_template_storage="local"
    export var_container_storage="local"
    export ENABLE_FUSE="true"
    export ENABLE_TUN="true"
    export SSH="true"

    source build.func
}

# 创建多个容器
create_container "plex" "100" "192.168.1.100"
create_container "nextcloud" "101" "192.168.1.101"
create_container "nginx" "102" "192.168.1.102"
```

### 2. 开发环境设置

**场景**：创建具有特定配置的开发容器

```bash
#!/bin/bash
# 开发环境设置

# 开发容器配置
export APP="dev-container"
export CTID="200"
export var_hostname="dev-server"
export var_os="ubuntu"
export var_version="22.04"
export var_cpu="4"
export var_ram="4096"
export var_disk="20"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.200"
export var_template_storage="local"
export var_container_storage="local"
export ENABLE_NESTING="true"
export ENABLE_PRIVILEGED="true"
export ENABLE_FUSE="true"
export ENABLE_TUN="true"
export SSH="true"

# 执行 build.func
source build.func
```

## 网络配置示例

### 1. VLAN 配置

**场景**：创建支持 VLAN 的容器

```bash
# VLAN 配置
export APP="web-server"
export CTID="300"
export var_hostname="web-server"
export var_os="debian"
export var_version="12"
export var_cpu="2"
export var_ram="2048"
export var_disk="10"
export var_net="vmbr0"
export var_gateway="192.168.100.1"
export var_ip="192.168.100.100"
export var_vlan="100"
export var_mtu="1500"
export var_template_storage="local"
export var_container_storage="local"

source build.func
```

### 2. IPv6 配置

**场景**：创建支持 IPv6 的容器

```bash
# IPv6 配置
export APP="ipv6-server"
export CTID="301"
export var_hostname="ipv6-server"
export var_os="debian"
export var_version="12"
export var_cpu="2"
export var_ram="2048"
export var_disk="10"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.101"
export var_ipv6="2001:db8::101"
export IPV6_METHOD="static"
export var_template_storage="local"
export var_container_storage="local"

source build.func
```

## 存储配置示例

### 1. 自定义存储位置

**场景**：为模板和容器使用不同的存储

```bash
# 自定义存储配置
export APP="storage-test"
export CTID="400"
export var_hostname="storage-test"
export var_os="debian"
export var_version="12"
export var_cpu="2"
export var_ram="2048"
export var_disk="10"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.140"
export var_template_storage="nfs-storage"
export var_container_storage="ssd-storage"

source build.func
```

### 2. 高性能存储

**场景**：为资源密集型应用使用高性能存储

```bash
# 高性能存储配置
export APP="database-server"
export CTID="401"
export var_hostname="database-server"
export var_os="debian"
export var_version="12"
export var_cpu="8"
export var_ram="16384"
export var_disk="100"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.141"
export var_template_storage="nvme-storage"
export var_container_storage="nvme-storage"

source build.func
```

## 功能配置示例

### 1. 特权容器

**场景**：创建用于系统级访问的特权容器

```bash
# 特权容器配置
export APP="system-container"
export CTID="500"
export var_hostname="system-container"
export var_os="debian"
export var_version="12"
export var_cpu="4"
export var_ram="4096"
export var_disk="20"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.150"
export var_template_storage="local"
export var_container_storage="local"
export ENABLE_PRIVILEGED="true"
export ENABLE_FUSE="true"
export ENABLE_TUN="true"
export ENABLE_KEYCTL="true"
export ENABLE_MOUNT="true"

source build.func
```

### 2. 非特权容器

**场景**：创建安全的非特权容器

```bash
# 非特权容器配置
export APP="secure-container"
export CTID="501"
export var_hostname="secure-container"
export var_os="debian"
export var_version="12"
export var_cpu="2"
export var_ram="2048"
export var_disk="10"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.151"
export var_template_storage="local"
export var_container_storage="local"
export ENABLE_UNPRIVILEGED="true"
export ENABLE_FUSE="true"
export ENABLE_TUN="true"

source build.func
```

## 设置持久化示例

### 1. 保存全局默认值

**场景**：将当前设置保存为全局默认值

```bash
# 保存全局默认值
export APP="default-test"
export CTID="600"
export var_hostname="default-test"
export var_os="debian"
export var_version="12"
export var_cpu="2"
export var_ram="2048"
export var_disk="10"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.160"
export var_template_storage="local"
export var_container_storage="local"
export SAVE_DEFAULTS="true"

source build.func
```

### 2. 保存应用特定默认值

**场景**：将设置保存为应用特定默认值

```bash
# 保存应用特定默认值
export APP="plex"
export CTID="601"
export var_hostname="plex-server"
export var_os="debian"
export var_version="12"
export var_cpu="4"
export var_ram="4096"
export var_disk="20"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.161"
export var_template_storage="local"
export var_container_storage="local"
export SAVE_APP_DEFAULTS="true"

source build.func
```

## 错误处理示例

### 1. 验证错误处理

**场景**：处理配置验证错误

```bash
#!/bin/bash
# 错误处理示例

# 设置无效配置
export APP="error-test"
export CTID="700"
export var_hostname="error-test"
export var_os="invalid-os"
export var_version="invalid-version"
export var_cpu="invalid-cpu"
export var_ram="invalid-ram"
export var_disk="invalid-disk"
export var_net="invalid-network"
export var_gateway="invalid-gateway"
export var_ip="invalid-ip"

# 使用错误处理执行
if source build.func; then
    echo "容器创建成功！"
else
    echo "错误：容器创建失败！"
    echo "请检查您的配置并重试。"
fi
```

### 2. 存储错误处理

**场景**：处理存储选择错误

```bash
#!/bin/bash
# 存储错误处理

# 设置无效存储
export APP="storage-error-test"
export CTID="701"
export var_hostname="storage-error-test"
export var_os="debian"
export var_version="12"
export var_cpu="2"
export var_ram="2048"
export var_disk="10"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.170"
export var_template_storage="nonexistent-storage"
export var_container_storage="nonexistent-storage"

# 使用错误处理执行
if source build.func; then
    echo "容器创建成功！"
else
    echo "错误：存储不可用！"
    echo "请检查可用存储并重试。"
fi
```

## 集成示例

### 1. 与安装脚本集成

**场景**：与应用程序安装脚本集成

```bash
#!/bin/bash
# 与安装脚本集成

# 创建容器
export APP="plex"
export CTID="800"
export var_hostname="plex-server"
export var_os="debian"
export var_version="12"
export var_cpu="4"
export var_ram="4096"
export var_disk="20"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.180"
export var_template_storage="local"
export var_container_storage="local"

# 创建容器
source build.func

# 运行安装脚本
if [ -f "plex-install.sh" ]; then
    source plex-install.sh
else
    echo "未找到安装脚本！"
fi
```

### 2. 与监控集成

**场景**：与监控系统集成

```bash
#!/bin/bash
# 监控集成

# 创建带监控的容器
export APP="monitored-app"
export CTID="801"
export var_hostname="monitored-app"
export var_os="debian"
export var_version="12"
export var_cpu="2"
export var_ram="2048"
export var_disk="10"
export var_net="vmbr0"
export var_gateway="192.168.1.1"
export var_ip="192.168.1.181"
export var_template_storage="local"
export var_container_storage="local"
export DIAGNOSTICS="true"

# 创建容器
source build.func

# 设置监控
if [ -f "monitoring-setup.sh" ]; then
    source monitoring-setup.sh
fi
```

## 最佳实践

### 1. 环境变量管理

```bash
#!/bin/bash
# 最佳实践：环境变量管理

# 设置配置文件
CONFIG_FILE="/etc/build.func.conf"

# 如果存在则加载配置
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# 设置必需变量
export APP="${APP:-plex}"
export CTID="${CTID:-100}"
export var_hostname="${var_hostname:-plex-server}"
export var_os="${var_os:-debian}"
export var_version="${var_version:-12}"
export var_cpu="${var_cpu:-2}"
export var_ram="${var_ram:-2048}"
export var_disk="${var_disk:-10}"
export var_net="${var_net:-vmbr0}"
export var_gateway="${var_gateway:-192.168.1.1}"
export var_ip="${var_ip:-192.168.1.100}"
export var_template_storage="${var_template_storage:-local}"
export var_container_storage="${var_container_storage:-local}"

# 执行 build.func
source build.func
```

### 2. 错误处理和日志记录

```bash
#!/bin/bash
# 最佳实践：错误处理和日志记录

# 设置日志文件
LOG_FILE="/var/log/build.func.log"

# 记录消息的函数
log_message() {
    echo "$(date): $1" >> "$LOG_FILE"
}

# 使用错误处理创建容器的函数
create_container() {
    local app=$1
    local ctid=$2

    log_message "开始为 $app 创建容器（ID：$ctid）"

    # 设置变量
    export APP="$app"
    export CTID="$ctid"
    export var_hostname="${app}-server"
    export var_os="debian"
    export var_version="12"
    export var_cpu="2"
    export var_ram="2048"
    export var_disk="10"
    export var_net="vmbr0"
    export var_gateway="192.168.1.1"
    export var_ip="192.168.1.$ctid"
    export var_template_storage="local"
    export var_container_storage="local"

    # 创建容器
    if source build.func; then
        log_message "容器 $app 创建成功（ID：$ctid）"
        return 0
    else
        log_message "错误：创建容器 $app 失败（ID：$ctid）"
        return 1
    fi
}

# 创建容器
create_container "plex" "100"
create_container "nextcloud" "101"
create_container "nginx" "102"
```
