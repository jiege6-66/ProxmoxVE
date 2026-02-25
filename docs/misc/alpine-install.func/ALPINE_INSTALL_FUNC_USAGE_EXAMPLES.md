# alpine-install.func 使用示例

Alpine 容器安装的基本示例。

### 示例：基本 Alpine 设置

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

setting_up_container
update_os

# 安装 Alpine 包
apk add --no-cache curl wget git

motd_ssh
customize
cleanup_lxc
```

---

**最后更新**：2025 年 12 月
