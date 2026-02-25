# install.func 使用示例

在应用程序安装脚本中使用 install.func 函数的实用示例。

## 基础示例

### 示例 1：最小化设置

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

setting_up_container
network_check
update_os

# ... application installation ...

motd_ssh
customize
cleanup_lxc
```

### 示例 2：带错误处理

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

catch_errors
setting_up_container

if ! network_check; then
  msg_error "Network failed"
  exit 1
fi

if ! update_os; then
  msg_error "OS update failed"
  exit 1
fi

# ... continue ...
```

---

## 生产环境示例

### 示例 3：完整应用程序安装

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

catch_errors
setting_up_container
network_check
update_os

msg_info "Installing application"
# ... install steps ...
msg_ok "Application installed"

motd_ssh
customize
cleanup_lxc
```

### 示例 4：支持 IPv6

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

catch_errors
setting_up_container
verb_ip6
network_check
update_os

# ... application installation ...

motd_ssh
customize
cleanup_lxc
```

---

**最后更新**：2025年12月
**示例**：基础和生产环境模式
**所有示例均可用于生产环境**
