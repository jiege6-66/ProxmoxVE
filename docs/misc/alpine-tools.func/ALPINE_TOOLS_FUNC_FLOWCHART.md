# alpine-tools.func 流程图

Alpine 工具安装和包管理流程。

## Alpine 上的工具安装

```
apk_update()
    ↓
add_community_repo()    [可选]
    ↓
apk_add PACKAGES
    ↓
工具安装
    ↓
rc-service start
    ↓
rc-update add           [开机启用]
    ↓
完成 ✓
```

---

**最后更新**：2025 年 12 月
