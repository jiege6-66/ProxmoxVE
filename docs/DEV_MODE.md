# 开发模式 - 调试与开发指南

开发模式为容器创建和安装过程提供强大的调试和测试功能。

## 快速开始

```bash
# 单一模式
export dev_mode="motd"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/wallabag.sh)"

# 多个模式（逗号分隔）
export dev_mode="motd,keep,trace"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/wallabag.sh)"

# 结合详细输出
export var_verbose="yes"
export dev_mode="pause,logs"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/wallabag.sh)"
```

## 可用模式

### 1. **motd** - 早期 SSH/MOTD 设置

在主应用程序安装**之前**设置 SSH 访问和 MOTD。

**使用场景**：

- 快速访问容器进行手动调试
- 如果出现问题可以手动继续安装
- 在主安装前验证容器网络

**行为**：

```
✔ 容器已创建
✔ 网络已配置
[DEV] 在安装前设置 MOTD 和 SSH
✔ [DEV] MOTD/SSH 就绪 - 容器可访问
# 容器现在可以通过 SSH 访问，同时安装继续进行
```

**结合使用**：`keep`、`breakpoint`、`logs`

---

### 2. **keep** - 失败时保留容器

安装失败时永不删除容器。跳过清理提示。

**使用场景**：

- 重复测试相同的安装
- 调试失败的安装
- 手动修复尝试

**行为**：

```
✖ 容器 107 中的安装失败（退出代码：1）
✔ 容器创建日志：/tmp/create-lxc-107-abc12345.log
✔ 安装日志：/tmp/install-lxc-107-abc12345.log

🔧 [DEV] Keep 模式激活 - 容器 107 已保留
root@proxmox:~#
```

**容器保留**：使用 `pct enter 107` 访问和调试

**结合使用**：`motd`、`trace`、`logs`

---

### 3. **trace** - Bash 命令跟踪

启用 `set -x` 进行完整的命令行跟踪。在执行前显示每个命令。

**使用场景**：

- 深度调试安装逻辑
- 理解脚本流程
- 精确识别错误发生位置

**行为**：

```
+(/opt/wallabag/bin/console): /opt/wallabag/bin/console cache:warmup
+(/opt/wallabag/bin/console): env APP_ENV=prod /opt/wallabag/bin/console cache:warmup
+(/opt/wallabag/bin/console): [[ -d /opt/wallabag/app/cache ]]
+(/opt/wallabag/bin/console): rm -rf /opt/wallabag/app/cache/*
```

**⚠️ 警告**：在日志输出中暴露密码和机密！仅在隔离环境中使用。

**日志输出**：所有跟踪输出保存到日志（参见 `logs` 模式）

**结合使用**：`keep`、`pause`、`logs`

---

### 4. **pause** - 逐步执行

在每个主要步骤（`msg_info`）后暂停。需要手动按 Enter 继续。

**使用场景**：

- 检查步骤之间的容器状态
- 理解每个步骤的作用
- 识别哪个步骤导致问题

**行为**：

```
⏳ 设置容器操作系统
[PAUSE] 按 Enter 继续...
⏳ 更新容器操作系统
[PAUSE] 按 Enter 继续...
⏳ 安装依赖项
[PAUSE] 按 Enter 继续...
```

**暂停期间**：您可以打开另一个终端并检查容器

```bash
# 在暂停时在另一个终端中
pct enter 107
root@container:~# df -h  # 检查磁盘使用情况
root@container:~# ps aux # 检查运行的进程
```

**结合使用**：`motd`、`keep`、`logs`

---

### 5. **breakpoint** - 错误时交互式 Shell

发生错误时在容器内打开交互式 shell，而不是清理提示。

**使用场景**：

- 在实际容器中实时调试
- 手动命令测试
- 在失败点检查容器状态

**行为**：

```
✖ 容器 107 中的安装失败（退出代码：1）
✔ 容器创建日志：/tmp/create-lxc-107-abc12345.log
✔ 安装日志：/tmp/install-lxc-107-abc12345.log

🐛 [DEV] Breakpoint 模式 - 在容器 107 中打开 shell
输入 'exit' 返回主机
root@wallabag:~#

# 现在您可以调试：
root@wallabag:~# tail -f /root/.install-abc12345.log
root@wallabag:~# mysql -u root -p$PASSWORD wallabag
root@wallabag:~# apt-get install -y strace
root@wallabag:~# exit

容器 107 仍在运行。现在删除？(y/N): n
🔧 容器 107 已保留用于调试
```

**结合使用**：`keep`、`logs`、`trace`

---

### 6. **logs** - 持久日志记录

将所有日志保存到 `/var/log/community-scripts/` 并带有时间戳。即使安装成功，日志也会保留。

**使用场景**：

- 事后分析
- 性能分析
- 带日志收集的自动化测试
- CI/CD 集成

**行为**：

```
日志位置：/var/log/community-scripts/

create-lxc-abc12345-20251117_143022.log    (主机端创建)
install-abc12345-20251117_143022.log       (容器端安装)
```

**访问日志**：

```bash
# 查看创建日志
tail -f /var/log/community-scripts/create-lxc-*.log

# 搜索错误
grep ERROR /var/log/community-scripts/*.log

# 分析性能
grep "msg_info\|msg_ok" /var/log/community-scripts/create-*.log
```

**使用 trace 模式**：创建所有命令的详细跟踪

```bash
grep "^+" /var/log/community-scripts/install-*.log
```

**结合使用**：所有其他模式（推荐用于 CI/CD）

---

### 7. **dryrun** - 模拟模式

显示将要执行的所有命令，但实际上不运行它们。

**使用场景**：

- 测试脚本逻辑而不进行更改
- 验证命令语法
- 了解将要发生什么
- 预检查

**行为**：

```
[DRYRUN] apt-get update
[DRYRUN] apt-get install -y curl
[DRYRUN] mkdir -p /opt/wallabag
[DRYRUN] cd /opt/wallabag
[DRYRUN] git clone https://github.com/wallabag/wallabag.git .
```

**不进行实际更改**：容器/系统保持不变

**结合使用**：`trace`（显示 dryrun 跟踪）、`logs`（显示将要运行的内容）

---

## 模式组合

### 开发工作流

```bash
# 首次测试：查看将要发生什么
export dev_mode="dryrun,logs"
bash -c "$(curl ...)"

# 然后使用跟踪和暂停进行测试
export dev_mode="pause,trace,logs"
bash -c "$(curl ...)"

# 最后使用早期 SSH 访问进行完整调试
export dev_mode="motd,keep,breakpoint,logs"
bash -c "$(curl ...)"
```

### CI/CD 集成

```bash
# 带完整日志记录的自动化测试
export dev_mode="logs"
export var_verbose="yes"
bash -c "$(curl ...)"

# 捕获日志进行分析
tar czf installation-logs-$(date +%s).tar.gz /var/log/community-scripts/
```

### 类生产测试

```bash
# 保留容器以进行手动验证
export dev_mode="keep,logs"
for i in {1..5}; do
  bash -c "$(curl ...)"
done

# 检查所有创建的容器
pct list
pct enter 100
```

### 实时调试

```bash
# 早期 SSH 进入，逐步执行安装，错误时调试
export dev_mode="motd,pause,breakpoint,keep"
bash -c "$(curl ...)"
```

---

## 环境变量参考

### 开发模式变量

- `dev_mode`（字符串）：逗号分隔的模式列表
  - 格式：`"motd,keep,trace"`
  - 默认：空（无开发模式）

### 输出控制

- `var_verbose="yes"`：显示所有命令输出（禁用静默模式）
  - 与以下配合良好：`trace`、`pause`、`logs`

### 带变量的示例

```bash
# 最大详细程度和调试
export var_verbose="yes"
export dev_mode="motd,trace,pause,logs"
bash -c "$(curl ...)"

# 静默调试（仅日志）
export dev_mode="keep,logs"
bash -c "$(curl ...)"

# 交互式调试
export var_verbose="yes"
export dev_mode="motd,breakpoint"
bash -c "$(curl ...)"
```

---

## 使用开发模式进行故障排除

### "安装在步骤 X 失败"

```bash
export dev_mode="pause,logs"
# 逐步执行直到失败点
# 在暂停之间检查容器状态
pct enter 107
```

### "密码/凭据不工作"

```bash
export dev_mode="motd,keep,trace"
# 使用 trace 模式，查看确切的密码处理（小心日志！）
# 使用 motd 通过 SSH 进入并手动测试
ssh root@container-ip
```

### "权限被拒绝错误"

```bash
export dev_mode="breakpoint,keep"
# 在失败点获取 shell
# 检查文件权限、用户上下文、SELinux 状态
ls -la /path/to/file
whoami
```

### "网络问题"

```bash
export dev_mode="motd"
# 在主安装前使用 motd 模式通过 SSH 进入
ssh root@container-ip
ping 8.8.8.8
nslookup example.com
```

### "需要手动完成安装"

```bash
export dev_mode="motd,keep"
# 安装运行时容器可通过 SSH 访问
# 失败后，通过 SSH 进入并手动继续
ssh root@container-ip
# ... 手动命令 ...
exit
# 然后使用 'keep' 模式保留容器以供检查
```

---

## 日志文件位置

### 默认（不使用 `logs` 模式）

- 主机创建：`/tmp/create-lxc-<SESSION_ID>.log`
- 容器安装：失败时复制到 `/tmp/install-lxc-<CTID>-<SESSION_ID>.log`

### 使用 `logs` 模式

- 主机创建：`/var/log/community-scripts/create-lxc-<SESSION_ID>-<TIMESTAMP>.log`
- 容器安装：`/var/log/community-scripts/install-<SESSION_ID>-<TIMESTAMP>.log`

### 查看日志

```bash
# 实时跟踪
tail -f /var/log/community-scripts/*.log

# 搜索错误
grep -r "exit code [1-9]" /var/log/community-scripts/

# 按会话过滤
grep "ed563b19" /var/log/community-scripts/*.log
```

---

## 最佳实践

### ✅ 应该做的

- 在 CI/CD 和自动化测试中使用 `logs` 模式
- 在长时间安装期间使用 `motd` 进行早期 SSH 访问
- 学习安装流程时使用 `pause`
- 调试逻辑问题时使用 `trace`（注意机密！）
- 组合模式以进行全面调试
- 成功测试后归档日志

### ❌ 不应该做的

- 在生产环境或不受信任的网络中使用 `trace`（暴露机密）
- 为无人值守脚本启用 `keep` 模式（容器会累积）
- 使用 `dryrun` 并期望实际更改
- 将 `dev_mode` 导出提交到生产部署脚本
- 在非交互式环境中使用 `breakpoint`（会挂起）

---

## 示例

### 示例 1：调试失败的安装

```bash
# 初始测试以查看失败
export dev_mode="keep,logs"
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/wallabag.sh)"

# 容器 107 已保留，检查日志
tail /var/log/community-scripts/install-*.log

# 通过 SSH 进入调试
pct enter 107
root@wallabag:~# cat /root/.install-*.log | tail -100
root@wallabag:~# apt-get update  # 重试失败的命令
root@wallabag:~# exit

# 使用手动逐步执行重新运行
export dev_mode="motd,pause,keep"
bash -c "$(curl ...)"
```

### 示例 2：验证安装步骤

```bash
export dev_mode="pause,logs"
export var_verbose="yes"
bash -c "$(curl ...)"

# 在每个步骤按 Enter
# 在另一个终端中监控容器
# pct enter 107
# 实时查看日志
```

### 示例 3：CI/CD 管道集成

```bash
#!/bin/bash
export dev_mode="logs"
export var_verbose="no"

for app in wallabag nextcloud wordpress; do
  echo "测试 $app 安装..."
  APP="$app" bash -c "$(curl ...)" || {
    echo "失败：$app"
    tar czf logs-$app.tar.gz /var/log/community-scripts/
    exit 1
  }
  echo "成功：$app"
done

echo "所有安装成功"
tar czf all-logs.tar.gz /var/log/community-scripts/
```

---

## 高级用法

### 自定义日志分析

```bash
# 提取所有错误
grep "ERROR\|exit code [1-9]" /var/log/community-scripts/*.log

# 性能时间线
grep "^$(date +%Y-%m-%d)" /var/log/community-scripts/*.log | grep "msg_"

# 安装期间的内存使用情况
grep "free\|available" /var/log/community-scripts/*.log
```

### 与外部工具集成

```bash
# 将日志发送到 Elasticsearch
curl -X POST "localhost:9200/installation-logs/_doc" \
  -H 'Content-Type: application/json' \
  -d @/var/log/community-scripts/install-*.log

# 归档以符合合规性
tar czf installation-records-$(date +%Y%m).tar.gz \
  /var/log/community-scripts/
gpg --encrypt installation-records-*.tar.gz
```

---

## 支持与问题

报告安装问题时，请始终包括：

```bash
# 收集所有相关信息
export dev_mode="logs"
# 运行失败的安装
# 然后提供：
tar czf debug-logs.tar.gz /var/log/community-scripts/
```

报告问题时包含 `debug-logs.tar.gz` 以获得更好的诊断。
