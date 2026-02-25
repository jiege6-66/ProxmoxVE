# 高级设置向导参考

## 概述

高级设置向导为 LXC 容器创建提供了 28 步交互式配置。它允许用户自定义容器的每个方面，同时从 CT 脚本继承合理的默认值。

## 主要功能

- **继承应用默认值**：CT 脚本中的所有 `var_*` 值预填充向导字段
- **返回导航**：按取消/返回可返回上一步
- **应用默认提示**：每个对话框显示 `(App default: X)` 以指示脚本默认值
- **完全自定义**：可访问每个可配置选项

## 向导步骤

| 步骤 | 标题                    | 变量                       | 描述                                           |
| ---- | ----------------------- | -------------------------- | ---------------------------------------------- |
| 1    | 容器类型                | `var_unprivileged`         | 特权 (0) 或非特权 (1) 容器                     |
| 2    | Root 密码               | `var_pw`                   | 设置密码或使用自动登录                         |
| 3    | 容器 ID                 | `var_ctid`                 | 唯一容器 ID（自动建议）                        |
| 4    | 主机名                  | `var_hostname`             | 容器主机名                                     |
| 5    | 磁盘大小                | `var_disk`                 | 磁盘大小（GB）                                 |
| 6    | CPU 核心数              | `var_cpu`                  | CPU 核心数量                                   |
| 7    | RAM 大小                | `var_ram`                  | RAM 大小（MiB）                                |
| 8    | 网络桥接                | `var_brg`                  | 网络桥接（vmbr0 等）                           |
| 9    | IPv4 配置               | `var_net`, `var_gateway`   | DHCP 或静态 IP 及网关                          |
| 10   | IPv6 配置               | `var_ipv6_method`          | 自动、DHCP、静态或无                           |
| 11   | MTU 大小                | `var_mtu`                  | 网络 MTU（默认：1500）                         |
| 12   | DNS 搜索域              | `var_searchdomain`         | DNS 搜索域                                     |
| 13   | DNS 服务器              | `var_ns`                   | 自定义 DNS 服务器 IP                           |
| 14   | MAC 地址                | `var_mac`                  | 自定义 MAC 地址（为空则自动生成）              |
| 15   | VLAN 标签               | `var_vlan`                 | VLAN 标签 ID                                   |
| 16   | 标签                    | `var_tags`                 | 容器标签（逗号/分号分隔）                      |
| 17   | SSH 设置                | `var_ssh`                  | SSH 密钥选择和 root 访问                       |
| 18   | FUSE 支持               | `var_fuse`                 | 为 rclone、mergerfs、AppImage 启用 FUSE        |
| 19   | TUN/TAP 支持            | `var_tun`                  | 为 VPN 应用启用（WireGuard、OpenVPN、Tailscale）|
| 20   | 嵌套支持                | `var_nesting`              | 为 Docker、LXC in LXC、Podman 启用             |
| 21   | GPU 直通                | `var_gpu`                  | 自动检测并直通 Intel/AMD/NVIDIA GPU            |
| 22   | Keyctl 支持             | `var_keyctl`               | 为 Docker、systemd-networkd 启用               |
| 23   | APT Cacher 代理         | `var_apt_cacher`, `var_apt_cacher_ip` | 使用 apt-cacher-ng 加速下载        |
| 24   | 容器时区                | `var_timezone`             | 设置时区（例如 Europe/Berlin）                 |
| 25   | 容器保护                | `var_protection`           | 防止意外删除                                   |
| 26   | 设备节点创建            | `var_mknod`                | 允许 mknod（实验性，内核 5.3+）                |
| 27   | 挂载文件系统            | `var_mount_fs`             | 允许特定挂载：nfs、cifs、fuse 等               |
| 28   | 详细模式和确认          | `var_verbose`              | 启用详细输出 + 最终确认                        |

## 默认值继承

向导从多个来源继承默认值：

```text
CT 脚本 (var_*) → default.vars → app.vars → 用户输入
```

### 示例：VPN 容器 (alpine-wireguard.sh)

```bash
# CT 脚本设置：
var_tun="${var_tun:-1}"  # 默认启用 TUN

# 在高级设置步骤 19：
# 对话框显示："(App default: 1)" 并预选 "Yes"
```

### 示例：媒体服务器 (jellyfin.sh)

```bash
# CT 脚本设置：
var_gpu="${var_gpu:-yes}"  # 默认启用 GPU

# 在高级设置步骤 21：
# 对话框显示："(App default: yes)" 并预选 "Yes"
```

## 功能矩阵

| 功能              | 变量             | 何时启用                                        |
| ----------------- | ---------------- | ----------------------------------------------- |
| FUSE              | `var_fuse`       | rclone、mergerfs、AppImage、SSHFS               |
| TUN/TAP           | `var_tun`        | WireGuard、OpenVPN、Tailscale、VPN 容器         |
| 嵌套              | `var_nesting`    | Docker、Podman、LXC-in-LXC、systemd-nspawn      |
| GPU 直通          | `var_gpu`        | Plex、Jellyfin、Emby、Frigate、Ollama、ComfyUI  |
| Keyctl            | `var_keyctl`     | Docker（非特权）、systemd-networkd               |
| 保护              | `var_protection` | 生产容器，防止意外删除                          |
| Mknod             | `var_mknod`      | 设备节点创建（实验性）                          |
| 挂载 FS           | `var_mount_fs`   | NFS 挂载、CIFS 共享、自定义文件系统             |
| APT Cacher        | `var_apt_cacher` | 使用本地 apt-cacher-ng 加速下载                 |

## 确认摘要

步骤 28 在创建前显示全面摘要：

```text
容器类型：非特权
容器 ID：100
主机名：jellyfin

资源：
  磁盘：8 GB
  CPU：2 核心
  RAM：2048 MiB

网络：
  桥接：vmbr0
  IPv4：dhcp
  IPv6：auto

功能：
  FUSE：no | TUN：no
  嵌套：已启用 | Keyctl：已禁用
  GPU：yes | 保护：否

高级：
  时区：Europe/Berlin
  APT Cacher：no
  详细：no
```

## 使用示例

### 跳转到高级设置

```bash
# 运行脚本，从菜单选择 "Advanced"
bash -c "$(curl -fsSL https://...jellyfin.sh)"
# 然后选择选项 3 "Advanced"
```

### 通过环境预设默认值

```bash
# 运行前设置默认值
export var_cpu=4
export var_ram=4096
export var_gpu=yes
bash -c "$(curl -fsSL https://...jellyfin.sh)"
# 高级设置将继承这些值
```

### 包含所有选项的非交互式

```bash
# 设置所有变量以实现完全自动化部署
export var_unprivileged=1
export var_cpu=2
export var_ram=2048
export var_disk=8
export var_net=dhcp
export var_fuse=no
export var_tun=no
export var_gpu=yes
export var_nesting=1
export var_protection=no
export var_verbose=no
bash -c "$(curl -fsSL https://...jellyfin.sh)"
```

## 注意事项

- **在步骤 1 取消**：完全退出脚本
- **在步骤 2-28 取消**：返回上一步
- **空字段**：使用默认值
- **Keyctl**：自动为非特权容器启用
- **嵌套**：默认启用（许多应用需要）
