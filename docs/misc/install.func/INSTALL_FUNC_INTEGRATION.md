# install.func 集成指南

install.func 如何与 ProxmoxVE 生态系统集成并连接到其他函数库。

## 组件集成

### 安装流程中的 install.func

```
install/app-install.sh (container-side)
    │
    ├─ Sources: core.func (messaging)
    ├─ Sources: error_handler.func (error handling)
    │
    ├─ ★ Uses: install.func ★
    │  ├─ setting_up_container()
    │  ├─ network_check()
    │  ├─ update_os()
    │  └─ motd_ssh()
    │
    ├─ Uses: tools.func (package installation)
    │
    └─ Back to install.func:
       ├─ customize()
       └─ cleanup_lxc()
```

### 与 tools.func 的集成

install.func 和 tools.func 协同工作：

```
setting_up_container()          [install.func]
    │
update_os()                     [install.func]
    │
pkg_update()                    [tools.func]
setup_nodejs()                  [tools.func]
setup_mariadb()                 [tools.func]
    │
motd_ssh()                      [install.func]
customize()                     [install.func]
cleanup_lxc()                   [install.func]
```

---

## 依赖项

### 外部依赖项

- `curl`, `wget` - 用于下载
- `apt-get` 或 `apk` - 包管理
- `ping` - 网络验证
- `systemctl` 或 `rc-service` - 服务管理

### 内部依赖项

```
install.func uses:
├─ core.func (for messaging and colors)
├─ error_handler.func (for error handling)
└─ tools.func (for package operations)
```

---

## 最佳实践

### 始终遵循此模式

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

# 1. 设置错误处理
catch_errors

# 2. 初始化容器
setting_up_container

# 3. 验证网络
network_check

# 4. 更新操作系统
update_os

# 5. 安装（你的代码）
# ... install application ...

# 6. 配置访问
motd_ssh

# 7. 自定义
customize

# 8. 清理
cleanup_lxc
```

---

**最后更新**: December 2025
**维护者**: community-scripts team
