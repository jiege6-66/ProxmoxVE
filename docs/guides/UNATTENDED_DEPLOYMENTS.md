---
# 无人值守部署指南

使用 community-scripts 为 Proxmox VE 进行自动化、零交互容器部署的完整指南。

---

## 🎯 你将学到什么

本综合指南涵盖：
- ✅ 容器部署的完全自动化
- ✅ 零交互安装
- ✅ 批量部署（多个容器）
- ✅ 基础设施即代码（Ansible、Terraform）
- ✅ CI/CD 流水线集成
- ✅ 错误处理和回滚策略
- ✅ 生产就绪的部署脚本
- ✅ 安全最佳实践

---

## 目录

1. [概述](#概述)
2. [前置条件](#前置条件)
3. [部署方法](#部署方法)
4. [单容器部署](#单容器部署)
5. [批量部署](#批量部署)
6. [基础设施即代码](#基础设施即代码)
7. [CI/CD 集成](#cicd-集成)
8. [错误处理](#错误处理)
9. [安全考虑](#安全考虑)

---

## 概述

无人值守部署允许你：
- ✅ 无需手动交互即可部署容器
- ✅ 自动化基础设施配置
- ✅ 与 CI/CD 流水线集成
- ✅ 维护一致的配置
- ✅ 跨多个节点扩展部署

---

## 前置条件

### 1. Proxmox VE 访问权限
```bash
# 验证你拥有 root 访问权限
whoami  # 应返回：root

# 检查 Proxmox 版本（需要 8.0+ 或 9.0-9.1）
pveversion
```

### 2. 网络连接
```bash
# 测试 GitHub 访问
curl -I https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/debian.sh

# 测试互联网连接
ping -c 1 1.1.1.1
```

### 3. 可用存储
```bash
# 列出可用存储
pvesm status

# 检查可用空间
df -h
```

---

## 部署方法

### 方法比较

| 方法 | 使用场景 | 复杂度 | 灵活性 |
|--------|----------|------------|-------------|
| **环境变量** | 快速一次性部署 | 低 | 高 |
| **应用默认值** | 重复部署 | 低 | 中 |
| **Shell 脚本** | 批量操作 | 中 | 高 |
| **Ansible** | 基础设施即代码 | 高 | 非常高 |
| **Terraform** | 云原生 IaC | 高 | 非常高 |

---

## 单容器部署

### 基本无人值守部署

**最简单的形式：**
```bash
var_hostname=myserver bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/debian.sh)"
```

### 完整配置示例

```bash
#!/bin/bash
# deploy-single.sh - 使用完整配置部署单个容器

var_unprivileged=1 \
var_cpu=4 \
var_ram=4096 \
var_disk=30 \
var_hostname=production-app \
var_os=debian \
var_version=13 \
var_brg=vmbr0 \
var_net=dhcp \
var_ipv6_method=none \
var_ssh=yes \
var_ssh_authorized_key="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQ... admin@workstation" \
var_nesting=1 \
var_tags=production,automated \
var_protection=yes \
var_verbose=no \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/debian.sh)"

echo "✓ 容器部署成功"
```

### 使用 IP 范围扫描进行自动 IP 分配

无需手动指定静态 IP，你可以定义一个 IP 范围。系统将自动 ping 每个 IP 并分配第一个空闲的：

```bash
#!/bin/bash
# deploy-with-ip-scan.sh - 从范围中自动分配第一个空闲 IP

var_unprivileged=1 \
var_cpu=4 \
var_ram=4096 \
var_hostname=web-server \
var_net=192.168.1.100/24-192.168.1.150/24 \
var_gateway=192.168.1.1 \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/debian.sh)"

# 脚本将：
# 1. Ping 192.168.1.100 - 如果响应，跳过
# 2. Ping 192.168.1.101 - 如果响应，跳过
# 3. 继续直到找到第一个不响应的 IP
# 4. 将该 IP 分配给容器
```

> **注意**：IP 范围格式为 `起始IP/CIDR-结束IP/CIDR`。两侧必须包含相同的 CIDR 表示法。

### 使用应用默认值

**步骤 1：创建一次默认值（交互式）**
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/pihole.sh)"
# 选择"高级设置"→ 配置 → 保存为"应用默认值"
```

**步骤 2：无人值守部署（使用保存的默认值）**
```bash
#!/bin/bash
# deploy-with-defaults.sh

# 应用默认值会自动加载
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/pihole.sh)"
# 脚本将使用 /usr/local/community-scripts/defaults/pihole.vars
```

### 高级配置变量

除了基本资源设置外，你还可以控制高级容器功能：

| 变量 | 描述 | 选项 |
|----------|-------------|---------|
| `var_os` | 操作系统模板 | `debian`、`ubuntu`、`alpine` |
| `var_version` | 操作系统版本 | `12`、`13`（Debian），`22.04`、`24.04`（Ubuntu）|
| `var_gpu` | 启用 GPU 直通 | `yes`、`no`（默认：`no`）|
| `var_tun` | 启用 TUN/TAP 设备 | `yes`、`no`（默认：`no`）|
| `var_nesting` | 启用嵌套 | `1`、`0`（默认：`1`）|

**带 GPU 和 TUN 的示例：**
```bash
var_gpu=yes \
var_tun=yes \
var_hostname=transcoder \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/plex.sh)"
```

---

## 批量部署

### 部署多个容器

#### 简单循环

```bash
#!/bin/bash
# batch-deploy-simple.sh

apps=("thingsboard" "qui" "flatnotes")

for app in "${apps[@]}"; do
  echo "正在部署 $app..."
  var_hostname="$app-server" \
  var_cpu=2 \
  var_ram=2048 \
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/${app}.sh)"

  echo "✓ $app 已部署"
  sleep 5  # 部署之间等待
done
```

#### 带配置数组的高级方式

```bash
#!/bin/bash
# batch-deploy-advanced.sh - 使用单独配置部署多个容器

declare -A CONTAINERS=(
  ["beszel"]="1:512:8:vmbr0:monitoring"
  ["qui"]="2:1024:10:vmbr0:torrent,ui"
  ["thingsboard"]="6:8192:50:vmbr1:iot,industrial"
  ["dockge"]="2:2048:10:vmbr0:docker,management"
)

for app in "${!CONTAINERS[@]}"; do
  # 解析配置
  IFS=':' read -r cpu ram disk bridge tags <<< "${CONTAINERS[$app]}"

  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "正在部署：$app"
  echo "  CPU：$cpu 核"
  echo "  内存：$ram MB"
  echo "  磁盘：$disk GB"
  echo "  网桥：$bridge"
  echo "  标签：$tags"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

  # 部署容器
  var_unprivileged=1 \
  var_cpu="$cpu" \
  var_ram="$ram" \
  var_disk="$disk" \
  var_hostname="$app" \
  var_brg="$bridge" \
  var_net=dhcp \
  var_ipv6_method=none \
  var_ssh=yes \
  var_tags="$tags,automated" \
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/${app}.sh)" 2>&1 | tee "deploy-${app}.log"

  if [ $? -eq 0 ]; then
    echo "✓ $app 部署成功"
  else
    echo "✗ $app 部署失败 - 检查 deploy-${app}.log"
  fi

  sleep 5
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "批量部署完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
```

#### 并行部署

```bash
#!/bin/bash
# parallel-deploy.sh - 并行部署多个容器

deploy_container() {
  local app="$1"
  local cpu="$2"
  local ram="$3"
  local disk="$4"

  echo "[$app] 开始部署..."
  var_cpu="$cpu" \
  var_ram="$ram" \
  var_disk="$disk" \
  var_hostname="$app" \
  var_net=dhcp \
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/${app}.sh)" \
    &> "deploy-${app}.log"

  echo "[$app] ✓ 完成"
}

# 导出函数以供并行执行
export -f deploy_container

# 并行部署（一次最多 3 个）
parallel -j 3 deploy_container ::: \
  "debian 2 2048 10" \
  "ubuntu 2 2048 10" \
  "alpine 1 1024 5" \
  "pihole 2 1024 8" \
  "docker 4 4096 30"

echo "所有部署完成！"
```

---

## 基础设施即代码

### Ansible Playbook

#### 基本 Playbook

```yaml
---
# playbook-proxmox.yml
- name: 部署 ProxmoxVE 容器
  hosts: proxmox_hosts
  become: yes
  tasks:
    - name: 部署 Debian 容器
      shell: |
        var_unprivileged=1 \
        var_cpu=2 \
        var_ram=2048 \
        var_disk=10 \
        var_hostname=debian-{{ inventory_hostname }} \
        var_net=dhcp \
        var_ssh=yes \
        var_tags=ansible,automated \
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/debian.sh)"
      args:
        executable: /bin/bash
      register: deploy_result

    - name: 显示部署结果
      debug:
        var: deploy_result.stdout_lines
```

#### 带变量的高级 Playbook

```yaml
---
# advanced-playbook.yml
- name: 部署多种容器类型
  hosts: proxmox
  vars:
    containers:
      - name: pihole
        cpu: 2
        ram: 1024
        disk: 8
        tags: "dns,network"
      - name: homeassistant
        cpu: 4
        ram: 4096
        disk: 20
        tags: "automation,ha"
      - name: docker
        cpu: 6
        ram: 8192
        disk: 50
        tags: "containers,docker"

    ssh_key: "{{ lookup('file', '~/.ssh/id_rsa.pub') }}"

  tasks:
    - name: 确保 community-scripts 目录存在
      file:
        path: /usr/local/community-scripts/defaults
        state: directory
        mode: '0755'

    - name: 部署容器
      shell: |
        var_unprivileged=1 \
        var_cpu={{ item.cpu }} \
        var_ram={{ item.ram }} \
        var_disk={{ item.disk }} \
        var_hostname={{ item.name }} \
        var_brg=vmbr0 \
        var_net=dhcp \
        var_ipv6_method=none \
        var_ssh=yes \
        var_ssh_authorized_key="{{ ssh_key }}" \
        var_tags="{{ item.tags }},ansible" \
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/{{ item.name }}.sh)"
      args:
        executable: /bin/bash
      loop: "{{ containers }}"
      register: deployment_results

    - name: 等待容器就绪
      wait_for:
        timeout: 60

    - name: 报告部署状态
      debug:
        msg: "已部署 {{ item.item.name }} - 状态：{{ '成功' if item.rc == 0 else '失败' }}"
      loop: "{{ deployment_results.results }}"
```

运行命令：
```bash
ansible-playbook -i inventory.ini advanced-playbook.yml
```

### Terraform 集成

```hcl
# main.tf - 通过 Terraform 部署容器

terraform {
  required_providers {
    proxmox = {
      source = "telmate/proxmox"
      version = "2.9.14"
    }
  }
}

provider "proxmox" {
  pm_api_url = "https://proxmox.example.com:8006/api2/json"
  pm_api_token_id = "terraform@pam!terraform"
  pm_api_token_secret = var.proxmox_token
}

resource "null_resource" "deploy_container" {
  for_each = var.containers

  provisioner "remote-exec" {
    inline = [
      "var_unprivileged=1",
      "var_cpu=${each.value.cpu}",
      "var_ram=${each.value.ram}",
      "var_disk=${each.value.disk}",
      "var_hostname=${each.key}",
      "var_net=dhcp",
      "bash -c \"$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/${each.value.template}.sh)\""
    ]

    connection {
      type = "ssh"
      host = var.proxmox_host
      user = "root"
      private_key = file("~/.ssh/id_rsa")
    }
  }
}

variable "containers" {
  type = map(object({
    template = string
    cpu = number
    ram = number
    disk = number
  }))

  default = {
    "pihole" = {
      template = "pihole"
      cpu = 2
      ram = 1024
      disk = 8
    }
    "homeassistant" = {
      template = "homeassistant"
      cpu = 4
      ram = 4096
      disk = 20
    }
  }
}
```

---

## CI/CD 集成

### GitHub Actions

```yaml
# .github/workflows/deploy-container.yml
name: 部署容器到 Proxmox

on:
  push:
    branches: [main]
  workflow_dispatch:
    inputs:
      container_type:
        description: '要部署的容器类型'
        required: true
        type: choice
        options:
          - debian
          - ubuntu
          - docker
          - pihole

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: 部署到 Proxmox
        uses: appleboy/ssh-action@v0.1.10
        with:
          host: ${{ secrets.PROXMOX_HOST }}
          username: root
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            var_unprivileged=1 \
            var_cpu=4 \
            var_ram=4096 \
            var_disk=30 \
            var_hostname=${{ github.event.inputs.container_type }}-ci \
            var_net=dhcp \
            var_ssh=yes \
            var_tags=ci-cd,automated \
            bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/${{ github.event.inputs.container_type }}.sh)"

      - name: 通知部署状态
        if: success()
        run: echo "✓ 容器部署成功"
```

### GitLab CI

```yaml
# .gitlab-ci.yml
stages:
  - deploy

deploy_container:
  stage: deploy
  image: alpine:latest
  before_script:
    - apk add --no-cache openssh-client curl bash
    - eval $(ssh-agent -s)
    - echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -
    - mkdir -p ~/.ssh
    - chmod 700 ~/.ssh
    - ssh-keyscan $PROXMOX_HOST >> ~/.ssh/known_hosts
  script:
    - |
      ssh root@$PROXMOX_HOST << 'EOF'
        var_unprivileged=1 \
        var_cpu=4 \
        var_ram=4096 \
        var_disk=30 \
        var_hostname=gitlab-ci-container \
        var_net=dhcp \
        var_tags=gitlab-ci,automated \
        bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/debian.sh)"
      EOF
  only:
    - main
  when: manual
```

---

## 错误处理

### 部署验证脚本

```bash
#!/bin/bash
# deploy-with-verification.sh

APP="debian"
HOSTNAME="production-server"
MAX_RETRIES=3
RETRY_COUNT=0

deploy_container() {
  echo "尝试部署（第 $((RETRY_COUNT + 1))/$MAX_RETRIES 次）..."

  var_unprivileged=1 \
  var_cpu=4 \
  var_ram=4096 \
  var_disk=30 \
  var_hostname="$HOSTNAME" \
  var_net=dhcp \
  var_ssh=yes \
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/${APP}.sh)" 2>&1 | tee deploy.log

  return ${PIPESTATUS[0]}
}

verify_deployment() {
  echo "验证部署..."

  # 检查容器是否存在
  if ! pct list | grep -q "$HOSTNAME"; then
    echo "✗ 在 pct 列表中未找到容器"
    return 1
  fi

  # 检查容器是否运行
  CTID=$(pct list | grep "$HOSTNAME" | awk '{print $1}')
  STATUS=$(pct status "$CTID" | awk '{print $2}')

  if [ "$STATUS" != "running" ]; then
    echo "✗ 容器未运行（状态：$STATUS）"
    return 1
  fi

  # 检查网络连接
  if ! pct exec "$CTID" -- ping -c 1 1.1.1.1 &>/dev/null; then
    echo "⚠ 警告：无互联网连接"
  fi

  echo "✓ 部署验证成功"
  echo "  容器 ID：$CTID"
  echo "  状态：$STATUS"
  echo "  IP：$(pct exec "$CTID" -- hostname -I)"

  return 0
}

# 带重试的主部署循环
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
  if deploy_container; then
    if verify_deployment; then
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      echo "✓ 部署成功！"
      echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
      exit 0
    else
      echo "✗ 部署验证失败"
    fi
  else
    echo "✗ 部署失败"
  fi

  RETRY_COUNT=$((RETRY_COUNT + 1))

  if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
    echo "10 秒后重试..."
    sleep 10
  fi
done

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✗ 尝试 $MAX_RETRIES 次后部署失败"
echo "查看 deploy.log 了解详情"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
exit 1
```

### 失败时回滚

```bash
#!/bin/bash
# deploy-with-rollback.sh

APP="debian"
HOSTNAME="test-server"
SNAPSHOT_NAME="pre-deployment"

# 对现有容器创建快照（如果存在）
backup_existing() {
  EXISTING_CTID=$(pct list | grep "$HOSTNAME" | awk '{print $1}')
  if [ -n "$EXISTING_CTID" ]; then
    echo "正在创建现有容器的快照..."
    pct snapshot "$EXISTING_CTID" "$SNAPSHOT_NAME" --description "部署前备份"
    return 0
  fi
  return 1
}

# 部署新容器
deploy() {
  var_hostname="$HOSTNAME" \
  var_cpu=4 \
  var_ram=4096 \
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/${APP}.sh)"
  return $?
}

# 回滚到快照
rollback() {
  local ctid="$1"
  echo "正在回滚到快照..."
  pct rollback "$ctid" "$SNAPSHOT_NAME"
  pct delsnapshot "$ctid" "$SNAPSHOT_NAME"
}

# 主执行
backup_existing
HAD_BACKUP=$?

if deploy; then
  echo "✓ 部署成功"
  [ $HAD_BACKUP -eq 0 ] && echo "你可以使用以下命令删除快照：pct delsnapshot <CTID> $SNAPSHOT_NAME"
else
  echo "✗ 部署失败"
  if [ $HAD_BACKUP -eq 0 ]; then
    read -p "回滚到之前的版本？(y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      rollback "$EXISTING_CTID"
      echo "✓ 回滚成功"
    fi
  fi
  exit 1
fi
```

---

## 安全考虑

### 安全部署脚本

```bash
#!/bin/bash
# secure-deploy.sh - 生产就绪的安全部署

set -euo pipefail  # 遇到错误、未定义变量、管道失败时退出

# 配置
readonly APP="debian"
readonly HOSTNAME="secure-server"
readonly SSH_KEY_PATH="/root/.ssh/id_rsa.pub"
readonly LOG_FILE="/var/log/container-deployments.log"

# 日志函数
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

# 验证前置条件
validate_environment() {
  log "验证环境..."

  # 检查是否以 root 运行
  if [ "$EUID" -ne 0 ]; then
    log "错误：必须以 root 运行"
    exit 1
  fi

  # 检查 SSH 密钥是否存在
  if [ ! -f "$SSH_KEY_PATH" ]; then
    log "错误：在 $SSH_KEY_PATH 未找到 SSH 密钥"
    exit 1
  fi

  # 检查互联网连接
  if ! curl -s --max-time 5 https://github.com &>/dev/null; then
    log "错误：无互联网连接"
    exit 1
  fi

  log "✓ 环境验证通过"
}

# 安全部署
deploy_secure() {
  log "开始为 $HOSTNAME 进行安全部署..."

  SSH_KEY=$(cat "$SSH_KEY_PATH")

  var_unprivileged=1 \
  var_cpu=4 \
  var_ram=4096 \
  var_disk=30 \
  var_hostname="$HOSTNAME" \
  var_brg=vmbr0 \
  var_net=dhcp \
  var_ipv6_method=disable \
  var_ssh=yes \
  var_ssh_authorized_key="$SSH_KEY" \
  var_nesting=0 \
  var_keyctl=0 \
  var_fuse=0 \
  var_protection=yes \
  var_tags=production,secure,automated \
  var_verbose=no \
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/${APP}.sh)" 2>&1 | tee -a "$LOG_FILE"

  if [ ${PIPESTATUS[0]} -eq 0 ]; then
    log "✓ 部署成功"
    return 0
  else
    log "✗ 部署失败"
    return 1
  fi
}

# 主执行
main() {
  validate_environment

  if deploy_secure; then
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "安全部署成功完成"
    log "容器：$HOSTNAME"
    log "功能：非特权、仅 SSH、受保护"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
  else
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "部署失败 - 查看日志：$LOG_FILE"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 1
  fi
}

main "$@"
```

### SSH 密钥管理

```bash
#!/bin/bash
# deploy-with-ssh-keys.sh - 安全的 SSH 密钥部署

# 从多个来源加载 SSH 密钥
load_ssh_keys() {
  local keys=()

  # 个人密钥
  if [ -f ~/.ssh/id_rsa.pub ]; then
    keys+=("$(cat ~/.ssh/id_rsa.pub)")
  fi

  # 团队密钥
  if [ -f /etc/ssh/authorized_keys.d/team ]; then
    while IFS= read -r key; do
      [ -n "$key" ] && keys+=("$key")
    done < /etc/ssh/authorized_keys.d/team
  fi

  # 用换行符连接密钥
  printf "%s\n" "${keys[@]}"
}

# 使用多个 SSH 密钥部署
SSH_KEYS=$(load_ssh_keys)

var_ssh=yes \
var_ssh_authorized_key="$SSH_KEYS" \
var_hostname=multi-key-server \
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/debian.sh)"
```

---

## 完整生产示例

```bash
#!/bin/bash
# production-deploy.sh - 完整的生产部署系统

set -euo pipefail

#━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
