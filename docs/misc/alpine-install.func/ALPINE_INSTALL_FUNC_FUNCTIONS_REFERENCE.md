# alpine-install.func 函数参考

Alpine Linux 特定的安装函数（基于 apk，OpenRC）。

## 核心函数

### setting_up_container()
初始化 Alpine 容器设置。

### update_os()
通过 `apk update && apk upgrade` 更新 Alpine 包。

### verb_ip6()
在 Alpine 上启用 IPv6 并持久化配置。

### network_check()
验证 Alpine 中的网络连接性。

### motd_ssh()
在 Alpine 上配置 SSH 守护进程和 MOTD。

### customize()
应用 Alpine 特定的自定义。

### cleanup_lxc()
最终清理（Alpine 特定）。

---

**最后更新**：2025 年 12 月
