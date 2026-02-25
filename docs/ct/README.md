# 容器脚本文档 (/ct)

本目录包含 `/ct` 目录中容器创建脚本的综合文档。

## 概述

容器脚本（`ct/*.sh`）是在 Proxmox VE 中创建 LXC 容器的入口点。它们在主机上运行并编排整个容器创建过程。

## 文档结构

每个脚本都有遵循项目模式的标准化文档。

## 关键资源

- **[DETAILED_GUIDE.md](DETAILED_GUIDE.md)** - 创建 ct 脚本的完整参考
- **[../contribution/README.md](../contribution/README.md)** - 如何贡献
- **[../misc/build.func/](../misc/build.func/)** - 核心编排器文档

## 容器创建流程

```
ct/AppName.sh (主机端)
    │
    ├─ 调用：build.func（编排器）
    │
    ├─ 变量：var_cpu、var_ram、var_disk、var_os
    │
    └─ 创建：LXC 容器
                │
                └─ 运行：install/appname-install.sh（内部）
```

## 可用脚本

查看 `/ct` 目录以获取所有容器创建脚本。常见示例：

- `pihole.sh` - Pi-hole DNS/DHCP 服务器
- `docker.sh` - Docker 容器运行时
- `wallabag.sh` - 文章阅读和归档
- `nextcloud.sh` - 私有云存储
- `debian.sh` - 基本 Debian 容器
- 以及 30+ 个更多...

## 快速开始

要了解如何创建容器脚本：

1. 阅读：[UPDATED_APP-ct.md](../UPDATED_APP-ct.md)
2. 研究：`/ct` 中类似的现有脚本
3. 复制模板并自定义
4. 本地测试
5. 提交 PR

## 贡献新容器

1. 创建 `ct/myapp.sh`
2. 创建 `install/myapp-install.sh`
3. 遵循 [UPDATED_APP-ct.md](../UPDATED_APP-ct.md) 中的模板
4. 彻底测试
5. 提交包含两个文件的 PR

## 常见任务

- **添加新容器应用程序** → [CONTRIBUTION_GUIDE.md](../CONTRIBUTION_GUIDE.md)
- **调试容器创建** → [EXIT_CODES.md](../EXIT_CODES.md)
- **理解 build.func** → [misc/build.func/](../misc/build.func/)
- **开发模式调试** → [DEV_MODE.md](../DEV_MODE.md)

---

**最后更新**：2025 年 12 月
**维护者**：community-scripts 团队
