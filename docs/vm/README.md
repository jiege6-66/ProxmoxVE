# 虚拟机脚本文档 (/vm)

本目录包含 `/vm` 目录中虚拟机创建脚本的综合文档。

## 概述

VM 脚本（`vm/*.sh`）在 Proxmox VE 中创建完整的虚拟机（而非容器），具有完整的操作系统和 cloud-init 配置。

## 文档结构

VM 文档与容器文档并行，但专注于 VM 特定功能。

## 关键资源

- **[misc/cloud-init.func/](../misc/cloud-init.func/)** - Cloud-init 配置文档
- **[CONTRIBUTION_GUIDE.md](../CONTRIBUTION_GUIDE.md)** - 贡献工作流
- **[EXIT_CODES.md](../EXIT_CODES.md)** - 退出代码参考

## VM 创建流程

```
vm/OsName-vm.sh (主机端)
    │
    ├─ 调用：build.func（编排器）
    │
    ├─ 变量：var_cpu、var_ram、var_disk、var_os
    │
    ├─ 使用：cloud-init.func（配置）
    │
    └─ 创建：KVM/QEMU VM
                │
                └─ 使用以下启动：Cloud-init 配置
                               │
                               ├─ 系统阶段
                               ├─ 配置阶段
                               └─ 最终阶段
```

## 可用 VM 脚本

查看 `/vm` 目录以获取所有 VM 创建脚本。示例：

- `ubuntu2504-vm.sh` - Ubuntu 25.04 VM（最新）
- `ubuntu2404-vm.sh` - Ubuntu 24.04 VM（LTS）
- `debian-13-vm.sh` - Debian 13 VM（Trixie）
- `archlinux-vm.sh` - Arch Linux VM
- `haos-vm.sh` - Home Assistant OS
- `mikrotik-routeros.sh` - MikroTik RouterOS
- `openwrt-vm.sh` - OpenWrt VM
- `opnsense-vm.sh` - OPNsense 防火墙
- `umbrel-os-vm.sh` - Umbrel OS VM
- 以及 10+ 个更多...

## VM vs 容器

| 功能 | VM | 容器 |
|---------|:---:|:---:|
| 隔离 | 完全 | 轻量级 |
| 启动时间 | 较慢 | 即时 |
| 资源使用 | 较高 | 较低 |
| 使用场景 | 完整操作系统 | 单个应用 |
| 初始化系统 | systemd/等 | cloud-init |
| 存储 | 磁盘镜像 | 文件系统 |

## 快速开始

要了解 VM 创建：

1. 阅读：[misc/cloud-init.func/README.md](../misc/cloud-init.func/README.md)
2. 研究：`/vm` 中类似的现有脚本
3. 理解 cloud-init 配置
4. 本地测试
5. 提交 PR

## 贡献新 VM

1. 创建 `vm/osname-vm.sh`
2. 使用 cloud-init 进行配置
3. 遵循 VM 脚本模板
4. 测试 VM 创建和启动
5. 提交 PR

## Cloud-Init 配置

VM 使用 cloud-init 进行配置：

```yaml
#cloud-config
hostname: myvm
timezone: UTC

packages:
  - curl
  - wget

users:
  - name: ubuntu
    ssh_authorized_keys:
      - ssh-rsa AAAAB3...

bootcmd:
  - echo "VM 启动中..."

runcmd:
  - apt-get update
  - apt-get upgrade -y
```

## 常见 VM 操作

- **使用 cloud-init 创建 VM** → [misc/cloud-init.func/](../misc/cloud-init.func/)
- **配置网络** → Cloud-init YAML 文档
- **设置 SSH 密钥** → [misc/cloud-init.func/CLOUD_INIT_FUNC_USAGE_EXAMPLES.md](../misc/cloud-init.func/CLOUD_INIT_FUNC_USAGE_EXAMPLES.md)
- **调试 VM 创建** → [EXIT_CODES.md](../EXIT_CODES.md)

## VM 模板

可用的常见 VM 模板：

- **Ubuntu LTS** - 最新稳定版 Ubuntu
- **Debian Stable** - 最新稳定版 Debian
- **OPNsense** - 网络安全平台
- **Home Assistant** - 家庭自动化
- **Kubernetes** - K3s 轻量级集群
- **Proxmox Backup** - 备份服务器

---

**最后更新**：2025 年 12 月
**维护者**：community-scripts 团队
