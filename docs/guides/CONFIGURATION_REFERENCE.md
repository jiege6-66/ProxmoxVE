# 配置参考

**community-scripts for Proxmox VE 中所有配置变量和选项的完整参考。**

---

## 目录

1. [变量命名约定](#变量命名约定)
2. [完整变量参考](#完整变量参考)
3. [资源配置](#资源配置)
4. [网络配置](#网络配置)
5. [IPv6 配置](#ipv6-配置)
6. [SSH 配置](#ssh-配置)
7. [容器功能](#容器功能)
8. [存储配置](#存储配置)
9. [安全设置](#安全设置)
10. [高级选项](#高级选项)
11. [快速参考表](#快速参考表)

---

## 变量命名约定

所有配置变量遵循一致的模式：

```
var_<setting>=<value>
```

**规则：**
- ✅ 始终以 `var_` 开头
- ✅ 仅小写字母
- ✅ 使用下划线分隔单词
- ✅ `=` 周围没有空格
- ✅ 如需要，值可以加引号

**示例：**
```bash
# ✓ 正确
var_cpu=4
var_hostname=myserver
var_ssh_authorized_key=ssh-rsa AAAA...

# ✗ 错误
CPU=4                    # 缺少 var_ 前缀
var_CPU=4                # 不允许大写
var_cpu = 4              # = 周围有空格
var-cpu=4                # 不允许连字符
```

---

## 完整变量参考

### var_unprivileged

**类型：** Boolean (0 或 1)
**默认值：** `1`（非特权）
**描述：** 确定容器是以非特权（推荐）还是特权方式运行。

```bash
var_unprivileged=1    # 非特权（更安全，推荐）
var_unprivileged=0    # 特权（安全性较低，功能更多）
```

**何时使用特权 (0)：**
- 需要硬件访问
- 需要某些内核模块
- 遗留应用程序
- 具有完整功能的嵌套虚拟化

**安全影响：**
- 非特权：容器 root 映射到主机上的非特权用户
- 特权：容器 root = 主机 root（安全风险）

---

### var_cpu

**类型：** Integer
**默认值：** 因应用而异（通常 1-4）
**范围：** 1 到主机 CPU 数量
**描述：** 分配给容器的 CPU 核心数。

```bash
var_cpu=1     # 单核（最小）
var_cpu=2     # 双核（典型）
var_cpu=4     # 四核（推荐用于应用）
var_cpu=8     # 高性能
```

**最佳实践：**
- 大多数应用从 2 核开始
- 使用 `pct exec <id> -- htop` 监控使用情况
- 创建后可以更改
- 考虑主机 CPU 数量（不要过度分配）

---

### var_ram

**类型：** Integer (MB)
**默认值：** 因应用而异（通常 512-2048）
**范围：** 512 MB 到主机 RAM
**描述：** RAM 数量（兆字节）。

```bash
var_ram=512      # 512 MB（最小）
var_ram=1024     # 1 GB（典型）
var_ram=2048     # 2 GB（舒适）
var_ram=4096     # 4 GB（推荐用于数据库）
var_ram=8192     # 8 GB（高内存应用）
```

**转换指南：**
```
512 MB   = 0.5 GB
1024 MB  = 1 GB
2048 MB  = 2 GB
4096 MB  = 4 GB
8192 MB  = 8 GB
16384 MB = 16 GB
```

**最佳实践：**
- 基本 Linux 最少 512 MB
- 典型应用 1 GB
- Web 服务器、数据库 2-4 GB
- 在容器内使用 `free -h` 监控

---

### var_disk

**类型：** Integer (GB)
**默认值：** 因应用而异（通常 2-8）
**范围：** 0.001 GB 到存储容量
**描述：** 根磁盘大小（千兆字节）。

```bash
var_disk=2      # 2 GB（仅最小操作系统）
var_disk=4      # 4 GB（典型）
var_disk=8      # 8 GB（舒适）
var_disk=20     # 20 GB（推荐用于应用）
var_disk=50     # 50 GB（大型应用）
var_disk=100    # 100 GB（数据库、媒体）
```

**重要说明：**
- 创建后可以扩展（不能缩小）
- 实际空间取决于存储类型
- 大多数存储支持精简配置
- 为日志、数据、更新做好规划

**按用例推荐的大小：**
```
基本 Linux 容器：     4 GB
Web 服务器 (Nginx/Apache)：8 GB
应用服务器：        10-20 GB
数据库服务器：      20-50 GB
Docker 主机：       30-100 GB
媒体服务器：        100+ GB
```

---

### var_hostname

**类型：** String
**默认值：** 应用程序名称
**最大长度：** 63 个字符
**描述：** 容器主机名（允许 FQDN 格式）。

```bash
var_hostname=myserver
var_hostname=pihole
var_hostname=docker-01
var_hostname=web.example.com
```

**规则：**
- 小写字母、数字、连字符
- 不能以连字符开头或结尾
- 不允许下划线
- 不允许空格

**最佳实践：**
```bash
# ✓ 好
var_hostname=web-server
var_hostname=db-primary
var_hostname=app.domain.com

# ✗ 避免
var_hostname=Web_Server    # 大写、下划线
var_hostname=-server       # 以连字符开头
var_hostname=my server     # 包含空格
```

---

### var_brg

**类型：** String
**默认值：** `vmbr0`
**描述：** 网络桥接接口。

```bash
var_brg=vmbr0    # 默认 Proxmox 桥接
var_brg=vmbr1    # 自定义桥接
var_brg=vmbr2    # 隔离网络
```

**常见设置：**
```
vmbr0 → 主网络（LAN）
vmbr1 → 访客网络
vmbr2 → DMZ
vmbr3 → 管理
vmbr4 → 存储网络
```

**检查可用桥接：**
```bash
ip link show | grep vmbr
# 或
brctl show
```

---

### var_net

**类型：** String
**选项：** `dhcp` 或 `static`
**默认值：** `dhcp`
**描述：** IPv4 网络配置方法。

```bash
var_net=dhcp     # 通过 DHCP 自动分配 IP
var_net=static   # 手动 IP 配置
```

**DHCP 模式：**
- 自动 IP 分配
- 易于设置
- 适合开发
- 需要网络上的 DHCP 服务器

**静态模式：**
- 固定 IP 地址
- 需要网关配置
- 更适合服务器
- 通过高级设置或创建后配置

---

### var_gateway

**类型：** IPv4 Address
**默认值：** 从主机自动检测
**描述：** 网络网关 IP 地址。

```bash
var_gateway=192.168.1.1
var_gateway=10.0.0.1
var_gateway=172.16.0.1
```

**自动检测：**
如果未指定，系统从主机检测网关：
```bash
ip route | grep default
```

**何时指定：**
- 有多个网关可用
- 自定义路由设置
- 不同的网络段

---

### var_vlan

**类型：** Integer
**范围：** 1-4094
**默认值：** None
**描述：** 用于网络隔离的 VLAN 标签。

```bash
var_vlan=10      # VLAN 10
var_vlan=100     # VLAN 100
var_vlan=200     # VLAN 200
```

**常见 VLAN 方案：**
```
VLAN 10  → 管理
VLAN 20  → 服务器
VLAN 30  → 桌面
VLAN 40  → 访客 WiFi
VLAN 50  → IoT 设备
VLAN 99  → DMZ
```

**要求：**
- 交换机必须支持 VLAN
- Proxmox 桥接配置为 VLAN 感知
- 网关在同一 VLAN 上

---

### var_mtu

**类型：** Integer
**默认值：** `1500`
**范围：** 68-9000
**描述：** 最大传输单元大小。

```bash
var_mtu=1500     # 标准以太网
var_mtu=1492     # PPPoE
var_mtu=9000     # 巨型帧
```

**常见值：**
```
1500 → 标准以太网（默认）
1492 → PPPoE 连接
1400 → 某些 VPN 设置
9000 → 巨型帧（10GbE 网络）
```

**何时更改：**
- 10GbE 上的巨型帧以提高性能
- PPPoE 互联网连接
- 有开销的 VPN 隧道
- 特定网络要求

---

### var_mac

**类型：** MAC Address
**格式：** `XX:XX:XX:XX:XX:XX`
**默认值：** 自动生成
**描述：** 容器 MAC 地址。

```bash
var_mac=02:00:00:00:00:01
var_mac=DE:AD:BE:EF:00:01
```

**何时指定：**
- 基于 MAC 的许可
- 静态 DHCP 保留
- 网络访问控制
- 克隆配置

**最佳实践：**
- 使用本地管理的地址（第 2 位设置）
- 以 `02:`、`06:`、`0A:`、`0E:` 开头
- 避免供应商 OUI
- 记录自定义 MAC

---

### var_ipv6_method

**类型：** String
**选项：** `auto`、`dhcp`、`static`、`none`、`disable`
**默认值：** `none`
**描述：** IPv6 配置方法。

```bash
var_ipv6_method=auto      # SLAAC（自动配置）
var_ipv6_method=dhcp      # DHCPv6
var_ipv6_method=static    # 手动配置
var_ipv6_method=none      # IPv6 已启用但未配置
var_ipv6_method=disable   # 完全禁用 IPv6
```

**详细选项：**

**auto (SLAAC)**
- 无状态地址自动配置
- 路由器通告
- 不需要 DHCPv6 服务器
- 大多数情况下推荐

**dhcp (DHCPv6)**
- 有状态配置
- 需要 DHCPv6 服务器
- 对地址有更多控制

**static**
- 手动 IPv6 地址
- 手动网关
- 完全控制

**none**
- IPv6 堆栈活动
- 未配置地址
- 可以稍后配置

**disable**
- 在内核级别完全禁用 IPv6
- 当 IPv6 导致问题时使用
- 设置 `net.ipv6.conf.all.disable_ipv6=1`

---

### var_ns

**类型：** IP Address
**默认值：** Auto（来自主机）
**描述：** DNS 名称服务器 IP。

```bash
var_ns=8.8.8.8           # Google DNS
var_ns=1.1.1.1           # Cloudflare DNS
var_ns=9.9.9.9           # Quad9 DNS
var_ns=192.168.1.1       # 本地 DNS
```

**常见 DNS 服务器：**
```
8.8.8.8, 8.8.4.4         → Google Public DNS
1.1.1.1, 1.0.0.1         → Cloudflare DNS
9.9.9.9, 149.112.112.112 → Quad9 DNS
208.67.222.222           → OpenDNS
192.168.1.1              → 本地路由器/Pi-hole
```

---

### var_ssh

**类型:** Boolean
**选项：** `yes` 或 `no`
**默认值：** `no`
**描述：** 在容器中启用 SSH 服务器。

```bash
var_ssh=yes      # SSH 服务器已启用
var_ssh=no       # SSH 服务器已禁用（仅控制台）
```

**启用时：**
- 安装 OpenSSH 服务器
- 启动时启动
- 端口 22 打开
- 允许 root 登录

**安全考虑：**
- 如果不需要则禁用
- 使用 SSH 密钥而不是密码
- 考虑非标准端口
- 推荐防火墙规则

---

### var_ssh_authorized_key

**类型：** String (SSH 公钥)
**默认值：** None
**描述：** root 用户的 SSH 公钥。

```bash
var_ssh_authorized_key=ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC... user@host
var_ssh_authorized_key=ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA... user@host
```

**支持的密钥类型：**
- RSA (2048-4096 位)
- Ed25519（推荐）
- ECDSA
- DSA（已弃用）

**如何获取您的公钥：**
```bash
cat ~/.ssh/id_rsa.pub
# 或
cat ~/.ssh/id_ed25519.pub
```

**多个密钥：**
用换行符分隔（在文件中）或使用多次部署。

---

### var_pw

**类型：** String
**默认值：** Empty（自动登录）
**描述：** Root 密码。

```bash
var_pw=SecurePassword123!    # 设置密码
var_pw=                      # 自动登录（空）
```

**自动登录行为：**
- 控制台不需要密码
- 控制台访问时自动登录
- 如果启用，SSH 仍需要密钥
- 适合开发

**密码最佳实践：**
- 最少 12 个字符
- 混合大小写/数字/符号
- 使用密码管理器
- 定期轮换

---

### var_nesting

**类型：** Boolean (0 或 1)
**默认值：** `1`
**描述：** 允许嵌套容器（Docker 需要）。

```bash
var_nesting=1    # 允许嵌套容器
var_nesting=0    # 禁用嵌套容器
```

**需要用于：**
- Docker
- LXC 内的 LXC
- Systemd 功能
- 容器编排

**安全影响：**
- 隔离略有降低
- 容器平台需要
- 非特权时通常安全

---

### var_diagnostics

**类型：** Boolean (yes 或 no)
**默认值：** `yes`
**描述：** 确定是否将匿名遥测和诊断数据发送到 Community-Scripts API。

```bash
var_diagnostics=yes      # 允许遥测（帮助我们改进脚本）
var_diagnostics=no       # 禁用所有遥测
```

**隐私和使用：**
- 数据严格匿名（随机会话 ID）
- 报告安装的成功/失败
- 映射错误代码（例如 APT 锁定、内存不足）
- 从不发送用户特定数据、主机名或密钥

---

### var_gpu

**类型：** Boolean/Toggle
**选项：** `yes` 或 `no`
**默认值：** `no`
**描述：** 为容器启用 GPU 直通。

```bash
var_gpu=yes      # 启用 GPU 直通（自动检测）
var_gpu=no       # 禁用 GPU 直通（默认）
```

**启用的功能：**
- 自动检测 Intel (QuickSync)、NVIDIA 和 AMD GPU
- 直通 `/dev/dri` 和渲染节点
- 配置适当的容器权限
- 对媒体服务器至关重要（Plex、Jellyfin、Immich）

**先决条件：**
- 主机驱动程序正确安装
- 硬件存在且对 Proxmox 可见
- IOMMU 已启用（对于某些配置）

---

### var_tun

**类型：** Boolean/Toggle
**选项：** `yes` 或 `no`
**默认值：** `no`
**描述：** 启用 TUN/TAP 设备支持。

```bash
var_tun=yes      # 启用 TUN/TAP 支持
var_tun=no       # 禁用 TUN/TAP 支持（默认）
```

**需要用于：**
- VPN 软件（WireGuard、OpenVPN）
- 网络隧道（Tailscale、ZeroTier）
- 自定义网络桥接

---

### var_keyctl

**类型：** Boolean (0 或 1)
**默认值：** `0`
**描述：** 启用 keyctl 系统调用。

```bash
var_keyctl=1     # Keyctl 已启用
var_keyctl=0     # Keyctl 已禁用
```

**需要用于：**
- 某些配置中的 Docker
- Systemd 密钥环功能
- 加密密钥管理
- 某些身份验证系统

---

### var_fuse

**类型：** Boolean/Toggle
**选项：** `yes` 或 `no`
**默认值：** `no`
**描述：** 启用 FUSE 文件系统支持。

```bash
var_fuse=yes     # FUSE 已启用
var_fuse=no      # FUSE 已禁用
```

**需要用于：**
- sshfs
- AppImage
- 某些备份工具
- 用户空间文件系统

---

### var_mknod

**类型：** Boolean (0 或 1)
**默认值：** `0`
**描述：** 允许设备节点创建。

```bash
var_mknod=1      # 允许设备节点
var_mknod=0      # 禁用设备节点
```

**要求：**
- 内核 5.3+
- 实验性功能
- 谨慎使用

---

### var_mount_fs

**类型：** String（逗号分隔）
**默认值：** Empty
**描述：** 允许挂载的文件系统。

```bash
var_mount_fs=nfs
var_mount_fs=nfs,cifs
var_mount_fs=ext4,xfs,nfs
```

**常见选项：**
```
nfs      → NFS 网络共享
cifs     → SMB/CIFS 共享
ext4     → Ext4 文件系统
xfs      → XFS 文件系统
btrfs    → Btrfs 文件系统
```

---

### var_protection

**类型：** Boolean
**选项：** `yes` 或 `no`
**默认值：** `no`
**描述：** 防止意外删除。

```bash
var_protection=yes    # 受保护免于删除
var_protection=no     # 可以正常删除
```

**受保护时：**
- 无法通过 GUI 删除
- 无法通过 `pct destroy` 删除
- 必须先禁用保护
- 适合生产容器

---

### var_tags

**类型：** String（逗号分隔）
**默认值：** `community-script`
**描述：** 用于组织的容器标签。

```bash
var_tags=production
var_tags=production,webserver
var_tags=dev,testing,temporary
```

**最佳实践：**
```bash
# 环境标签
var_tags=production
var_tags=development
var_tags=staging

# 功能标签
var_tags=webserver,nginx
var_tags=database,postgresql
var_tags=cache,redis

# 项目标签
var_tags=project-alpha,frontend
var_tags=customer-xyz,billing

# 组合
var_tags=production,webserver,project-alpha
```

---

### var_timezone

**类型：** String (TZ 数据库格式)
**默认值：** 主机时区
**描述：** 容器时区。

```bash
var_timezone=Europe/Berlin
var_timezone=America/New_York
var_timezone=Asia/Tokyo
```

**常见时区：**
```
Europe/London
Europe/Berlin
Europe/Paris
America/New_York
America/Chicago
America/Los_Angeles
Asia/Tokyo
Asia/Singapore
Australia/Sydney
UTC
```

**列出所有时区：**
```bash
timedatectl list-timezones
```

---

### var_verbose

**类型：** Boolean
**选项：** `yes` 或 `no`
**默认值：** `no`
**描述：** 启用详细输出。

```bash
var_verbose=yes    # 显示所有命令
var_verbose=no     # 静默模式
```

**启用时：**
- 显示所有执行的命令
- 显示详细进度
- 对调试有用
- 更多日志输出

---

### var_apt_cacher

**类型：** Boolean
**选项：** `yes` 或 `no`
**默认值：** `no`
**描述：** 使用 APT 缓存代理。

```bash
var_apt_cacher=yes
var_apt_cacher=no
```

**好处：**
- 更快的包安装
- 减少带宽
- 离线包缓存
- 加速多个容器

---

### var_apt_cacher_ip

**类型：** IP Address
**默认值：** None
**描述：** APT 缓存代理 IP。

```bash
var_apt_cacher=yes
var_apt_cacher_ip=192.168.1.100
```

**设置 apt-cacher-ng：**
```bash
apt install apt-cacher-ng
# 在端口 3142 上运行
```

---

### var_container_storage

**类型：** String
**默认值：** 自动检测
**描述：** 容器的存储。

```bash
var_container_storage=local
var_container_storage=local-zfs
var_container_storage=pve-storage
```

**列出可用存储：**
```bash
pvesm status
```

---

### var_template_storage

**类型：** String
**默认值：** 自动检测
**描述：** 模板的存储。

```bash
var_template_storage=local
var_template_storage=nfs-templates
```

---

## 快速参考表

| 变量 | 类型 | 默认值 | 示例 |
|----------|------|---------|---------|
| `var_unprivileged` | 0/1 | 1 | `var_unprivileged=1` |
| `var_cpu` | int | varies | `var_cpu=4` |
| `var_ram` | int (MB) | varies | `var_ram=4096` |
| `var_disk` | int (GB) | varies | `var_disk=20` |
| `var_hostname` | string | app name | `var_hostname=server` |
| `var_brg` | string | vmbr0 | `var_brg=vmbr1` |
| `var_net` | dhcp/static | dhcp | `var_net=dhcp` |
| `var_gateway` | IP | auto | `var_gateway=192.168.1.1` |
| `var_ipv6_method` | string | none | `var_ipv6_method=disable` |
| `var_vlan` | int | - | `var_vlan=100` |
| `var_mtu` | int | 1500 | `var_mtu=9000` |
| `var_mac` | MAC | auto | `var_mac=02:00:00:00:00:01` |
| `var_ns` | IP | auto | `var_ns=8.8.8.8` |
| `var_ssh` | yes/no | no | `var_ssh=yes` |
| `var_ssh_authorized_key` | string | - | `var_ssh_authorized_key=ssh-rsa...` |
| `var_pw` | string | empty | `var_pw=password` |
| `var_nesting` | 0/1 | 1 | `var_nesting=1` |
| `var_keyctl` | 0/1 | 0 | `var_keyctl=1` |
| `var_fuse` | 0/1 | 0 | `var_fuse=1` |
| `var_mknod` | 0/1 | 0 | `var_mknod=1` |
| `var_mount_fs` | string | - | `var_mount_fs=nfs,cifs` |
| `var_protection` | yes/no | no | `var_protection=yes` |
| `var_tags` | string | community-script | `var_tags=prod,web` |
| `var_timezone` | string | host TZ | `var_timezone=Europe/Berlin` |
| `var_verbose` | yes/no | no | `var_verbose=yes` |
| `var_apt_cacher` | yes/no | no | `var_apt_cacher=yes` |
| `var_apt_cacher_ip` | IP | - | `var_apt_cacher_ip=192.168.1.10` |
| `var_container_storage` | string | auto | `var_container_storage=local-zfs` |
| `var_template_storage` | string | auto | `var_template_storage=local` |

---

## 另见

- [默认系统指南](DEFAULTS_GUIDE.md)
- [无人值守部署](UNATTENDED_DEPLOYMENTS.md)
- [安全最佳实践](SECURITY_GUIDE.md)
- [网络配置](NETWORK_GUIDE.md)
