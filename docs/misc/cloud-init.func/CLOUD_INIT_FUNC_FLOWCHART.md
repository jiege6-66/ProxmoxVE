# cloud-init.func 流程图

Cloud-init VM 配置流程。

## Cloud-Init 生成和应用

```
generate_cloud_init()
    ↓
generate_user_data()
    ↓
setup_ssh_keys()
    ↓
应用于 VM
    ↓
VM 启动
    ↓
cloud-init 阶段
├─ system
├─ config
└─ final
    ↓
VM 准备就绪 ✓
```

---

**最后更新**：2025 年 12 月
