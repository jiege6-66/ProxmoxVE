# alpine-tools.func 使用示例

Alpine 工具安装示例。

### 示例：使用工具的 Alpine 设置

```bash
#!/usr/bin/env bash
source /dev/stdin <<<"$FUNCTIONS_FILE_PATH"

apk_update
setup_nodejs "20"
setup_php "8.3"
setup_mariadb "11"
```

---

**最后更新**：2025 年 12 月
