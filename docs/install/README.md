# 安装脚本文档 (/install)

本目录包含 `/install` 目录中安装脚本的综合文档。

## 概述

安装脚本（`install/*.sh`）在 LXC 容器内运行，处理应用程序特定的设置、配置和部署。

## 文档结构

每个安装脚本类别都有遵循项目模式的文档。

## 关键资源

- **[DETAILED_GUIDE.md](DETAILED_GUIDE.md)** - 创建安装脚本的完整参考
- **[../contribution/README.md](../contribution/README.md)** - 如何贡献
- **[../misc/install.func/](../misc/install.func/)** - 安装工作流文档
- **[../misc/tools.func/](../misc/tools.func/)** - 包安装文档

## 安装脚本流程

```
install/appname-install.sh (容器端)
    │
    ├─ Sources：$FUNCTIONS_FILE_PATH
    │  ├─ core.func（消息传递）
    │  ├─ error_handler.func（错误处理）
    │  ├─ install.func（设置）
    │  └─ tools.func（包和工具）
    │
    ├─ 10 阶段安装：
    │  1. 操作系统设置
    │  2. 基础依赖项
    │  3. 工具设置
    │  4. 应用程序下载
    │  5. 配置
    │  6. 数据库设置
    │  7. 权限
    │  8. 服务
    │  9. 版本跟踪
    │  10. 最终清理
    │
    └─ 结果：应用程序就绪
```

## 可用安装脚本

查看 `/install` 目录以获取所有安装脚本。示例：

- `pihole-install.sh` - Pi-hole 安装
- `docker-install.sh` - Docker 安装
- `wallabag-install.sh` - Wallabag 设置
- `nextcloud-install.sh` - Nextcloud 部署
- `debian-install.sh` - 基本 Debian 设置
- 以及 30+ 个更多...

## 快速开始

要了解如何创建安装脚本：

1. 阅读：[UPDATED_APP-install.md](../UPDATED_APP-install.md)
2. 研究：`/install` 中类似的现有脚本
3. 复制模板并自定义
4. 在容器中测试
5. 提交 PR

## 10 阶段安装模式

每个安装脚本都遵循此结构：

### 阶段 1：操作系统设置
```bash
setting_up_container
network_check
update_os
```

### 阶段 2：基础依赖项
```bash
pkg_update
pkg_install curl wget git
```

### 阶段 3：工具设置
```bash
setup_nodejs "20"
setup_php "8.3"
setup_mariadb  # 使用发行版包（推荐）
# MARIADB_VERSION="11.4" setup_mariadb  # 用于特定版本
```

### 阶段 4：应用程序下载
```bash
git clone https://github.com/user/app /opt/app
cd /opt/app
```

### 阶段 5：配置
```bash
# 创建 .env 文件、配置文件等
cat > .env <<EOF
SETTING=value
EOF
```

### 阶段 6：数据库设置
```bash
# 创建数据库、用户等
mysql -e "CREATE DATABASE appdb"
```

### 阶段 7：权限
```bash
chown -R appuser:appgroup /opt/app
chmod -R 755 /opt/app
```

### 阶段 8：服务
```bash
systemctl enable app
systemctl start app
```

### 阶段 9：版本跟踪
```bash
echo "1.0.0" > /opt/app_version.txt
```

### 阶段 10：最终清理
```bash
motd_ssh
customize
cleanup_lxc
```

## 贡献安装脚本

1. 创建 `ct/myapp.sh`（主机脚本）
2. 创建 `install/myapp-install.sh`（容器脚本）
3. 遵循 [UPDATED_APP-install.md](../UPDATED_APP-install.md) 中的 10 阶段模式
4. 在实际容器中测试
5. 提交包含两个文件的 PR

## 常见任务

- **创建新安装脚本** → [UPDATED_APP-install.md](../UPDATED_APP-install.md)
- **安装 Node.js/PHP/数据库** → [misc/tools.func/](../misc/tools.func/)
- **设置 Alpine 容器** → [misc/alpine-install.func/](../misc/alpine-install.func/)
- **调试安装错误** → [EXIT_CODES.md](../EXIT_CODES.md)
- **使用开发模式** → [DEV_MODE.md](../DEV_MODE.md)

## Alpine vs Debian

- **基于 Debian** → 使用 `tools.func`、`install.func`、`systemctl`
- **基于 Alpine** → 使用 `alpine-tools.func`、`alpine-install.func`、`rc-service`

---

**最后更新**：2025 年 12 月
**维护者**：community-scripts 团队
