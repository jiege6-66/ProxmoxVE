# alpine-install.func 流程图

Alpine 容器初始化流程（基于 apk，OpenRC init 系统）。

## Alpine 容器设置流程

```
Alpine 容器启动
    ↓
setting_up_container()
    ↓
verb_ip6()              [可选 - IPv6]
    ↓
update_os()             [apk update/upgrade]
    ↓
network_check()
    ↓
应用程序安装
    ↓
motd_ssh()
    ↓
customize()
    ↓
cleanup_lxc()
    ↓
完成 ✓
```

**最后更新**：2025 年 12 月
