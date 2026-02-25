# 配置和默认系统 - 用户指南

> **应用默认值和用户默认值完整指南**
> 
> *学习如何配置、保存和重用您的安装设置*

---

## 目录

1. [快速开始](#快速开始)
2. [理解默认系统](#理解默认系统)
3. [安装模式](#安装模式)
4. [如何保存默认值](#如何保存默认值)
5. [如何使用保存的默认值](#如何使用保存的默认值)
6. [管理您的默认值](#管理您的默认值)
7. [高级配置](#高级配置)
8. [故障排除](#故障排除)

---

## 快速开始

### 30秒设置

```bash
# 1. 运行任何容器安装脚本
bash pihole-install.sh

# 2. 当提示时，选择："Advanced Settings"
#    （这允许您自定义所有内容）

# 3. 回答所有配置问题

# 4. 最后，当询问 "Save as App Defaults?" 时
#    选择：YES

# 5. 完成！您的设置现已保存
```

**下次**：再次运行相同的脚本，选择 **"App Defaults"**，您的设置将自动应用！

---

## 理解默认系统

### 三层系统

您的安装设置通过三个层次管理：

#### 🔷 **层次 1: 内置默认值**（后备）
```
这些是脚本中硬编码的
为每个应用程序提供合理的默认值
示例：PiHole 默认使用 2 个 CPU 核心
```

#### 🔶 **层次 2: 用户默认值**（全局）
```
您的个人全局默认值
应用于所有容器安装
位置：/usr/local/community-scripts/default.vars
示例："我总是想要 4 个 CPU 核心和 2GB RAM"
```

#### 🔴 **层次 3: 应用默认值**（特定）
```
应用程序特定的保存设置
仅在安装该特定应用时应用
位置：/usr/local/community-scripts/defaults/<appname>.vars
示例："每当我安装 PiHole 时，使用这些确切的设置"
```

### 优先级系统

安装容器时，设置按以下顺序应用：

```
┌─────────────────────────────────────┐
│ 1. 环境变量（最高）                  │  在 shell 中设置：export var_cpu=8
│    （这些覆盖所有内容）              │
├─────────────────────────────────────┤
│ 2. 应用默认值                        │  来自：defaults/pihole.vars
│    （应用特定的保存设置）            │
├─────────────────────────────────────┤
│ 3. 用户默认值                        │  来自：default.vars
│    （您的全局默认值）                │
├─────────────────────────────────────┤
│ 4. 内置默认值（最低）                │  脚本中硬编码
│    （故障安全，始终可用）            │
└─────────────────────────────────────┘
```

**简单来说**：
- 如果您设置了环境变量 → 它获胜
- 否则，如果您有应用特定的默认值 → 使用它们
- 否则，如果您有用户默认值 → 使用它们
- 否则，使用硬编码的默认值

---

## 安装模式

运行任何安装脚本时，您将看到一个菜单：

### 选项 1️⃣：**默认设置**

```
使用标准设置快速安装
├─ 最适合：首次用户，快速部署
├─ 发生什么：
│  1. 脚本使用内置默认值
│  2. 立即创建容器
│  3. 不询问问题
└─ 时间：约 2 分钟
```

**何时使用**：您想要标准安装，不需要自定义

---

### 选项 2️⃣：**高级设置**

```
通过 19 个配置步骤完全自定义
├─ 最适合：高级用户，自定义需求
├─ 发生什么：
│  1. 脚本询问每个设置
│  2. 您控制：CPU、RAM、磁盘、网络、SSH 等
│  3. 创建前显示摘要
│  4. 提供保存为应用默认值
└─ 时间：约 5-10 分钟
```

**何时使用**：您想要完全控制配置

**可用设置**：
- CPU 核心数、RAM 数量、磁盘大小
- 容器名称、网络设置
- SSH 访问、API 访问、功能
- 密码、SSH 密钥、标签

---

### 选项 3️⃣：**用户默认值**

```
使用您保存的全局默认值
├─ 最适合：跨多个容器的一致部署
├─ 要求：您之前已保存用户默认值
├─ 发生什么：
│  1. 从以下位置加载设置：/usr/local/community-scripts/default.vars
│  2. 显示加载的设置
│  3. 立即创建容器
└─ 时间：约 2 分钟
```

**何时使用**：您有想要用于每个应用的首选默认值

---

### 选项 4️⃣：**应用默认值**（如果可用）

```
使用之前保存的应用特定默认值
├─ 最适合：多次重复相同配置
├─ 要求：您之前已为此应用保存应用默认值
├─ 发生什么：
│  1. 从以下位置加载设置：/usr/local/community-scripts/defaults/<app>.vars
│  2. 显示加载的设置
│  3. 立即创建容器
└─ 时间：约 2 分钟
```

**何时使用**：您之前安装过此应用并想要相同的设置

---

### 选项 5️⃣：**设置菜单**

```
管理您保存的配置
├─ 功能：
│  • 查看当前设置
│  • 编辑存储选择
│  • 管理默认值位置
│  • 查看当前配置的内容
└─ 时间：约 1 分钟
```

**何时使用**：您想要查看或修改保存的设置

---

## 如何保存默认值

### 方法 1：安装时保存

这是最简单的方法：

#### 分步说明：创建应用默认值

```bash
# 1. 运行安装脚本
bash pihole-install.sh

# 2. 选择安装模式
#    ┌─────────────────────────┐
#    │ Select installation mode:│
#    │ 1) Default Settings     │
#    │ 2) Advanced Settings    │
#    │ 3) User Defaults        │
#    │ 4) App Defaults         │
#    │ 5) Settings Menu        │
#    └─────────────────────────┘
#
#    输入：2（高级设置）

# 3. 回答所有配置问题
#    • Container name? → my-pihole
#    • CPU cores? → 4
#    • RAM amount? → 2048
#    • Disk size? → 20
#    • SSH access? → yes
#    ...（更多选项）

# 4. 查看摘要（创建前显示）
#    ✓ 确认继续

# 5. 创建完成后，您将看到：
#    ┌──────────────────────────────────┐
#    │ Save as App Defaults for PiHole? │
#    │ (Yes/No)                         │
#    └──────────────────────────────────┘
#
#    选择：Yes

# 6. 完成！设置保存到：
#    /usr/local/community-scripts/defaults/pihole.vars
```

#### 分步说明：创建用户默认值

```bash
# 与应用默认值相同，但是：
# 当您选择 "Advanced Settings" 时
# 您运行此选择的第一个应用将提供
# 额外保存为 "User Defaults"

# 这保存到：/usr/local/community-scripts/default.vars
```

---

### 方法 2：手动文件创建

对于想要在不运行安装的情况下创建默认值的高级用户：

```bash
# 手动创建用户默认值
sudo tee /usr/local/community-scripts/default.vars > /dev/null << 'EOF'
# Global User Defaults
var_cpu=4
var_ram=2048
var_disk=20
var_unprivileged=1
var_brg=vmbr0
var_gateway=192.168.1.1
var_timezone=Europe/Berlin
var_ssh=yes
var_container_storage=local
var_template_storage=local
EOF

# 手动创建应用默认值
sudo tee /usr/local/community-scripts/defaults/pihole.vars > /dev/null << 'EOF'
# App-specific defaults for PiHole
var_unprivileged=1
var_cpu=2
var_ram=1024
var_disk=10
var_brg=vmbr0
var_gateway=192.168.1.1
var_hostname=pihole
var_container_storage=local
var_template_storage=local
EOF
```

---

### 方法 3：使用环境变量

在运行前通过环境设置默认值：

```bash
# 设置为环境变量
export var_cpu=4
export var_ram=2048
export var_disk=20
export var_hostname=my-container

# 运行安装
bash pihole-install.sh

# 这些设置将被使用
#（仍可被保存的默认值覆盖）
```

---

## 如何使用保存的默认值

### 使用用户默认值

```bash
# 1. 运行任何安装脚本
bash pihole-install.sh

# 2. 当询问模式时，选择：
#    选项：3（用户默认值）

# 3. 应用来自 default.vars 的设置
# 4. 使用您保存的设置创建容器
```

### 使用应用默认值

```bash
# 1. 运行您之前配置的应用
bash pihole-install.sh

# 2. 当询问模式时，选择：
#    选项：4（应用默认值）

# 3. 应用来自 defaults/pihole.vars 的设置
# 4. 使用完全相同的设置创建容器
```

### 覆盖保存的默认值

```bash
# 即使您保存了默认值，
# 您也可以使用环境变量覆盖它们

export var_cpu=8  # 覆盖保存的默认值
export var_hostname=custom-name

bash pihole-install.sh
# 安装将使用这些值而不是保存的默认值
```

---

## 管理您的默认值

### 查看您的设置

#### 查看用户默认值
```bash
cat /usr/local/community-scripts/default.vars
```

#### 查看应用默认值
```bash
cat /usr/local/community-scripts/defaults/pihole.vars
```

#### 列出所有保存的应用默认值
```bash
ls -la /usr/local/community-scripts/defaults/
```

### 编辑您的设置

#### 编辑用户默认值
```bash
sudo nano /usr/local/community-scripts/default.vars
```

#### 编辑应用默认值
```bash
sudo nano /usr/local/community-scripts/defaults/pihole.vars
```

### 更新现有默认值

```bash
# 再次运行您的应用的安装
bash pihole-install.sh

# 选择：高级设置
# 进行所需的更改
# 最后，当询问保存时：
#   "Defaults already exist, Update?"
#   选择：Yes

# 您保存的默认值已更新
```

### 删除默认值

#### 删除用户默认值
```bash
sudo rm /usr/local/community-scripts/default.vars
```

#### 删除应用默认值
```bash
sudo rm /usr/local/community-scripts/defaults/pihole.vars
```

#### 删除所有应用默认值
```bash
sudo rm /usr/local/community-scripts/defaults/*
```

---

## 高级配置

### 可用变量

所有可配置变量都以 `var_` 开头：

#### 资源分配
```bash
var_cpu=4              # CPU 核心数
var_ram=2048           # RAM（MB）
var_disk=20            # 磁盘（GB）
var_unprivileged=1     # 0=特权，1=非特权
```

#### 网络
```bash
var_brg=vmbr0          # 桥接接口
var_net=dhcp           # dhcp、静态 IP/CIDR 或 IP 范围（见下文）
var_gateway=192.168.1.1  # 默认网关（静态 IP 需要）
var_mtu=1500           # MTU 大小
var_vlan=100           # VLAN ID
```

#### IP 范围扫描

您可以指定 IP 范围而不是静态 IP。系统将 ping 范围内的每个 IP 并自动分配第一个空闲 IP：

```bash
# 格式：START_IP/CIDR-END_IP/CIDR
var_net=192.168.1.100/24-192.168.1.200/24
var_gateway=192.168.1.1
```

这对于自动化部署很有用，您想要静态 IP 但不想跟踪哪些 IP 已在使用。

#### 系统
```bash
var_hostname=pihole    # 容器名称
var_timezone=Europe/Berlin  # 时区
var_pw=SecurePass123   # Root 密码
var_tags=dns,pihole    # 用于组织的标签
var_verbose=yes        # 启用详细输出
```

#### 安全和访问
```bash
var_ssh=yes            # 启用 SSH
var_ssh_authorized_key="ssh-rsa AA..." # SSH 公钥
var_protection=1       # 启用保护标志
```

#### 功能
```bash
var_fuse=1             # FUSE 文件系统支持
var_tun=1              # TUN 设备支持
var_nesting=1          # 嵌套（LXC 中的 Docker）
var_keyctl=1           # Keyctl 系统调用
var_mknod=1            # 设备节点创建
```

#### 存储
```bash
var_container_storage=local    # 存储容器的位置
var_template_storage=local     # 存储模板的位置
```

### 示例配置文件

#### 游戏服务器默认值
```bash
# 游戏容器的高性能
var_cpu=8
var_ram=4096
var_disk=50
var_unprivileged=0
var_fuse=1
var_nesting=1
var_tags=gaming
```

#### 开发服务器
```bash
# 支持 Docker 的开发
var_cpu=4
var_ram=2048
var_disk=30
var_unprivileged=1
var_nesting=1
var_ssh=yes
var_tags=development
```

#### IoT/监控
```bash
# 低资源，始终在线的容器
var_cpu=2
var_ram=512
var_disk=10
var_unprivileged=1
var_nesting=0
var_fuse=0
var_tun=0
var_tags=iot,monitoring
```

---

## 故障排除

### "App Defaults not available" 消息

**问题**：您想使用应用默认值，但选项显示它们不可用

**解决方案**：
1. 您尚未为此应用创建应用默认值
2. 使用 "Advanced Settings" 运行应用
3. 完成后，保存为应用默认值
4. 下次，应用默认值将可用

---

### "Settings not being applied"

**问题**：您保存了默认值，但它们没有被使用

**检查清单**：
```bash
# 1. 验证文件存在
ls -la /usr/local/community-scripts/default.vars
ls -la /usr/local/community-scripts/defaults/<app>.vars

# 2. 检查文件权限（应该可读）
stat /usr/local/community-scripts/default.vars

# 3. 验证选择了正确的模式
#    （确保您选择了 "User Defaults" 或 "App Defaults"）

# 4. 检查环境变量覆盖
env | grep var_
#    如果您在环境中设置了 var_*，
#    这些会覆盖您保存的默认值
```

---

### "Cannot write to defaults location"

**问题**：保存默认值时权限被拒绝

**解决方案**：
```bash
# 如果缺少，创建默认值目录
sudo mkdir -p /usr/local/community-scripts/defaults

# 修复权限
sudo chmod 755 /usr/local/community-scripts
sudo chmod 755 /usr/local/community-scripts/defaults

# 确保您以 root 身份运行
sudo bash pihole-install.sh
```

---

### "Defaults directory doesn't exist"

**问题**：脚本找不到保存默认值的位置

**解决方案**：
```bash
# 创建目录
sudo mkdir -p /usr/local/community-scripts/defaults

# 验证
ls -la /usr/local/community-scripts/
```

---

### 设置看起来随机或错误

**问题**：容器获得的设置与预期不同

**可能的原因和解决方案**：

```bash
# 1. 检查是否设置了环境变量
env | grep var_
# 如果您看到 var_* 条目，这些会覆盖您的默认值
# 清除它们：unset var_cpu var_ram（等）

# 2. 验证文件中的默认值正确
cat /usr/local/community-scripts/default.vars
cat /usr/local/community-scripts/defaults/pihole.vars

# 3. 检查您实际选择的模式
#（脚本输出显示应用了哪些默认值）

# 4. 检查 Proxmox 日志中的错误
sudo journalctl -u pve-daemon -n 50
```

---

### "Variable not recognized"

**问题**：您设置的变量不起作用

**解决方案**：
只允许某些变量（安全白名单）：

```
允许的变量（以 var_ 开头）：
✓ var_cpu、var_ram、var_disk、var_unprivileged
✓ var_brg、var_gateway、var_mtu、var_vlan、var_net
✓ var_hostname、var_pw、var_timezone
✓ var_ssh、var_ssh_authorized_key
✓ var_fuse、var_tun、var_nesting、var_keyctl
✓ var_container_storage、var_template_storage
✓ var_tags、var_verbose
✓ var_apt_cacher、var_apt_cacher_ip
✓ var_protection、var_mount_fs

✗ 不支持其他变量
```

---

## 最佳实践

### ✅ 应该做的

✓ 当您想要应用特定设置时使用 **应用默认值**
✓ 为您的全局首选项使用 **用户默认值**
✓ 使用 `nano` 直接编辑默认值文件（安全）
✓ 为每个应用保留单独的应用默认值
✓ 定期备份您的默认值
✓ 使用环境变量进行临时覆盖

### ❌ 不应该做的

✗ 不要在默认值文件上使用 `source`（安全风险）
✗ 不要在默认值中放置敏感密码（使用 SSH 密钥）
✗ 不要在安装运行时修改默认值
✗ 不要在创建容器时删除 defaults.d
✗ 不要在不转义的情况下使用特殊字符

---

## 快速参考

### 默认值位置

| 类型 | 位置 | 示例 |
|------|----------|---------|
| 用户默认值 | `/usr/local/community-scripts/default.vars` | 全局设置 |
| 应用默认值 | `/usr/local/community-scripts/defaults/<app>.vars` | PiHole 特定 |
| 备份目录 | `/usr/local/community-scripts/defaults/` | 所有应用默认值 |

### 文件格式

```bash
# 注释以 # 开头
var_name=value

# = 周围没有空格
✓ var_cpu=4
✗ var_cpu = 4

# 字符串值不需要引号
✓ var_hostname=mycontainer
✓ var_hostname='mycontainer'

# 带空格的值需要引号
✓ var_tags="docker,production,testing"
✗ var_tags=docker,production,testing
```

### 命令参考

```bash
# 查看默认值
cat /usr/local/community-scripts/default.vars

# 编辑默认值
sudo nano /usr/local/community-scripts/default.vars

# 列出所有应用默认值
ls /usr/local/community-scripts/defaults/

# 备份您的默认值
cp -r /usr/local/community-scripts/defaults/ ~/defaults-backup/

# 设置临时覆盖
export var_cpu=8
bash pihole-install.sh

# 创建自定义默认值
sudo tee /usr/local/community-scripts/defaults/custom.vars << 'EOF'
var_cpu=4
var_ram=2048
EOF
```

---

## 获取帮助

### 需要更多信息？

- 📖 [主文档](../../docs/)
- 🐛 [报告问题](https://github.com/community-scripts/ProxmoxVE/issues)
- 💬 [讨论](https://github.com/community-scripts/ProxmoxVE/discussions)

### 有用的命令

```bash
# 检查可用的变量
grep "var_" /path/to/app-install.sh | head -20

# 验证默认值语法
cat /usr/local/community-scripts/default.vars

# 使用默认值监控安装
bash pihole-install.sh 2>&1 | tee installation.log
```

---

## 文档信息

| 字段 | 值 |
|-------|-------|
| 版本 | 1.0 |
| 最后更新 | 2025年11月28日 |
| 状态 | 当前 |
| 许可证 | MIT |

---

**祝配置愉快！🚀**
