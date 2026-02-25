# cloud-init.func 使用示例

VM cloud-init 配置示例。

### 示例：基本 Cloud-Init

```bash
#!/usr/bin/env bash

generate_cloud_init > cloud-init.yaml
setup_ssh_keys "$VMID" "$SSH_KEY"
apply_cloud_init "$VMID" cloud-init.yaml
```

---

**最后更新**：2025 年 12 月
