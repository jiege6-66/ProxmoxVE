# cloud-init.func 文档

## 概述

`cloud-init.func` 文件为 Proxmox VE 虚拟机提供 cloud-init 配置和 VM 初始化函数。它处理用户数据、cloud-config 生成和 VM 设置自动化。

## 目的和用例

- **VM Cloud-Init 设置**：为 VM 生成并应用 cloud-init 配置
- **用户数据生成**：创建 VM 初始化的用户数据脚本
- **Cloud-Config**：为 VM 配置生成 cloud-config YAML
- **SSH 密钥管理**：设置 VM 访问的 SSH 密钥
- **网络配置**：为 VM 配置网络
- **自动化 VM 配置**：无需手动干预即可完成 VM 设置

## 快速参考

### 主要功能组
- **Cloud-Init 核心**：生成并应用 cloud-init 配置
- **用户数据**：为 VM 创建初始化脚本
- **SSH 设置**：自动部署 SSH 密钥
- **网络配置**：在 VM 配置期间设置网络
- **VM 自定义**：将自定义设置应用于 VM

### 依赖关系
- **外部**：`cloud-init`、`curl`、`qemu-img`
- **内部**：使用 `core.func`、`error_handler.func` 中的函数

### 集成点
- 使用者：VM 创建脚本（vm/*.sh）
- 使用：来自 build.func 的环境变量
- 提供：VM 初始化和 cloud-init 服务

## 文档文件

### 📊 [CLOUD_INIT_FUNC_FLOWCHART.md](./CLOUD_INIT_FUNC_FLOWCHART.md)
显示 cloud-init 生成和 VM 配置工作流的可视化执行流程。

### 📚 [CLOUD_INIT_FUNC_FUNCTIONS_REFERENCE.md](./CLOUD_INIT_FUNC_FUNCTIONS_REFERENCE.md)
所有 cloud-init 函数的完整字母顺序参考。

### 💡 [CLOUD_INIT_FUNC_USAGE_EXAMPLES.md](./CLOUD_INIT_FUNC_USAGE_EXAMPLES.md)
VM cloud-init 设置和自定义的实用示例。

### 🔗 [CLOUD_INIT_FUNC_INTEGRATION.md](./CLOUD_INIT_FUNC_INTEGRATION.md)
cloud-init.func 如何与 VM 创建和 Proxmox 工作流集成。

## 主要功能

### Cloud-Init 配置
- **用户数据生成**：创建自定义初始化脚本
- **Cloud-Config YAML**：生成标准化的 cloud-config
- **SSH 密钥**：自动部署公钥
- **包安装**：在 VM 启动期间安装包
- **自定义命令**：在首次启动时运行任意命令

### VM 网络设置
- **DHCP 配置**：配置 DHCP 以自动分配 IP
- **静态 IP 设置**：配置静态 IP 地址
- **IPv6 支持**：在 VM 上启用 IPv6
- **DNS 配置**：为 VM 设置 DNS 服务器
- **防火墙规则**：基本防火墙配置

### 安全功能
- **SSH 密钥注入**：在 VM 创建期间部署 SSH 密钥
- **禁用密码**：禁用密码身份验证
- **Sudoers 配置**：设置 sudo 访问
- **用户管理**：创建和配置用户

## 功能类别

### 🔹 Cloud-Init 核心函数
- `generate_cloud_init()` - 创建 cloud-init 配置
- `generate_user_data()` - 生成用户数据脚本
- `apply_cloud_init()` - 将 cloud-init 应用于 VM
- `validate_cloud_init()` - 验证 cloud-config 语法

### 🔹 SSH 和安全函数
- `setup_ssh_keys()` - 部署 SSH 公钥
- `setup_sudo()` - 配置 sudoers
- `create_user()` - 创建新用户账户
- `disable_password_auth()` - 禁用密码登录

### 🔹 网络配置函数
- `setup_dhcp()` - 配置 DHCP 网络
- `setup_static_ip()` - 配置静态 IP
- `setup_dns()` - 配置 DNS 服务器
- `setup_ipv6()` - 启用 IPv6 支持

### 🔹 VM 自定义函数
- `install_packages()` - 在启动期间安装包
- `run_custom_commands()` - 执行自定义脚本
- `configure_hostname()` - 设置 VM 主机名
- `configure_timezone()` - 设置 VM 时区

## Cloud-Init 工作流

```
VM 已创建
    ↓
cloud-init (system) 启动阶段
    ↓
用户数据脚本执行
    ↓
├─ 安装包
├─ 部署 SSH 密钥
├─ 配置网络
└─ 创建用户
    ↓
cloud-init config 阶段
    ↓
应用 cloud-config 设置
    ↓
cloud-init final 阶段
    ↓
VM 准备就绪
```

## 常见使用模式

### 使用 Cloud-Init 的基本 VM 设置
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# 生成 cloud-init 配置
cat > cloud-init.yaml <<EOF
#cloud-config
hostname: myvm
timezone: UTC

packages:
  - curl
  - wget
  - git

users:
  - name: ubuntu
    ssh_authorized_keys:
      - ssh-rsa AAAAB3...
    sudo: ALL=(ALL) NOPASSWD:ALL

bootcmd:
  - echo "VM 正在初始化..."

runcmd:
  - apt-get update
  - apt-get upgrade -y
EOF

# 应用于 VM
qm set VMID --cicustom local:snippets/cloud-init.yaml
```

### 使用 SSH 密钥部署
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# 获取 SSH 公钥
SSH_KEY=$(cat ~/.ssh/id_rsa.pub)

# 使用 SSH 密钥生成 cloud-init
generate_user_data > user-data.txt

# 注入 SSH 密钥
setup_ssh_keys "$VMID" "$SSH_KEY"

# 使用 cloud-init 创建 VM
qm create $VMID ... --cicustom local:snippets/user-data
```

### 网络配置
```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# 静态 IP 设置
setup_static_ip "192.168.1.100" "255.255.255.0" "192.168.1.1"

# DNS 配置
setup_dns "8.8.8.8 8.8.4.4"

# IPv6 支持
setup_ipv6
```

## 最佳实践

### ✅ 应该做
- 在应用前验证 cloud-config 语法
- 使用 cloud-init 进行自动化设置
- 部署 SSH 密钥以实现安全访问
- 首先在非生产环境中测试 cloud-init 配置
- 使用 DHCP 以便更轻松地部署 VM
- 记录自定义 cloud-init 配置
- 对 cloud-init 模板进行版本控制

### ❌ 不应该做
- 使用弱 SSH 密钥或密码
- 保持 SSH 密码身份验证启用
- 在 cloud-init 中硬编码凭据
- 跳过 cloud-config 验证
- 使用不受信任的 cloud-init 源
- 忘记在 VM 上设置时区
- 混合使用 cloud-init 版本

## Cloud-Config 格式

### Cloud-Config 示例
```yaml
#cloud-config
# 这是注释

# 系统配置
hostname: myvm
timezone: UTC
package_upgrade: true

# 要安装的包
packages:
  - curl
  - wget
  - git
  - build-essential

# 用户的 SSH 密钥
ssh_authorized_keys:
  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC...

# 要创建的用户
users:
  - name: ubuntu
    home: /home/ubuntu
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - ssh-rsa AAAAB3...

# 启动时运行的命令
runcmd:
  - apt-get update
  - apt-get upgrade -y
  - systemctl restart ssh

# 要创建的文件
write_files:
  - path: /etc/profile.d/custom.sh
    content: |
      export CUSTOM_VAR="value"
```

## VM 网络配置

### DHCP 配置
```bash
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: true
      dhcp6: true
```

### 静态 IP 配置
```bash
network:
  version: 2
  ethernets:
    eth0:
      addresses:
        - 192.168.1.100/24
      gateway4: 192.168.1.1
      nameservers:
        addresses: [8.8.8.8, 8.8.4.4]
```

## 故障排除

### "Cloud-Init 配置未应用"
```bash
# 在 VM 中检查 cloud-init 状态
cloud-init status
cloud-init status --long

# 查看 cloud-init 日志
tail /var/log/cloud-init.log
```

### "SSH 密钥未部署"
```bash
# 验证 cloud-config 中的 SSH 密钥
grep ssh_authorized_keys user-data.txt

# 检查权限
ls -la ~/.ssh/authorized_keys
```

### "网络未配置"
```bash
# 检查网络配置
ip addr show
ip route show

# 查看 netplan（如果使用）
cat /etc/netplan/*.yaml
```

### "包安装失败"
```bash
# 检查 cloud-init 包日志
tail /var/log/cloud-init-output.log

# 手动包安装
apt-get update && apt-get install -y package-name
```

## 相关文档

- **[install.func/](../install.func/)** - 容器安装（类似工作流）
- **[core.func/](../core.func/)** - 实用函数
- **[error_handler.func/](../error_handler.func/)** - 错误处理
- **[UPDATED_APP-install.md](../../UPDATED_APP-install.md)** - 应用程序设置指南
- **Proxmox 文档**：https://pve.proxmox.com/wiki/Cloud-Init

## 最近更新

### 版本 2.0（2025 年 12 月）
- ✅ 增强的 cloud-init 验证
- ✅ 改进的 SSH 密钥部署
- ✅ 更好的网络配置支持
- ✅ 添加 IPv6 支持
- ✅ 简化的用户和包设置

---

**最后更新**：2025 年 12 月
**维护者**：community-scripts 团队
**许可证**：MIT
