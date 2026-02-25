# 📚 ProxmoxVE 文档

所有 ProxmoxVE 文档的完整指南 - 快速找到您需要的内容。

---

## 🎯 **按目标快速导航**

### 👤 **我想要...**

**贡献新应用程序**
→ 从这里开始：[contribution/README.md](contribution/README.md)
→ 然后：[ct/DETAILED_GUIDE.md](ct/DETAILED_GUIDE.md) + [install/DETAILED_GUIDE.md](install/DETAILED_GUIDE.md)

**理解架构**
→ 阅读：[TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md)
→ 然后：[misc/README.md](misc/README.md)

**调试失败的安装**
→ 检查：[EXIT_CODES.md](EXIT_CODES.md)
→ 然后：[DEV_MODE.md](DEV_MODE.md)
→ 另见：[misc/error_handler.func/](misc/error_handler.func/)

**配置系统默认值**
→ 阅读：[guides/DEFAULTS_SYSTEM_GUIDE.md](guides/DEFAULTS_SYSTEM_GUIDE.md)

**自动部署容器**
→ 阅读：[guides/UNATTENDED_DEPLOYMENTS.md](guides/UNATTENDED_DEPLOYMENTS.md)

**开发函数库**
→ 研究：[misc/](misc/) 文档

---

## 👤 **按角色快速开始**

### **我是...**

**新贡献者**
→ 开始：[contribution/README.md](contribution/README.md)
→ 然后：选择下面的路径

**容器创建者**
→ 阅读：[ct/README.md](ct/README.md)
→ 深入：[ct/DETAILED_GUIDE.md](ct/DETAILED_GUIDE.md)
→ 参考：[misc/build.func/](misc/build.func/)

**安装脚本开发者**
→ 阅读：[install/README.md](install/README.md)
→ 深入：[install/DETAILED_GUIDE.md](install/DETAILED_GUIDE.md)
→ 参考：[misc/tools.func/](misc/tools.func/)

**VM 配置者**
→ 阅读：[vm/README.md](vm/README.md)
→ 参考：[misc/cloud-init.func/](misc/cloud-init.func/)

**工具开发者**
→ 阅读：[tools/README.md](tools/README.md)
→ 参考：[misc/build.func/](misc/build.func/)

**API 集成者**
→ 阅读：[api/README.md](api/README.md)
→ 参考：[misc/api.func/](misc/api.func/)

**系统运维人员**
→ 开始：[EXIT_CODES.md](EXIT_CODES.md)
→ 然后：[guides/DEFAULTS_SYSTEM_GUIDE.md](guides/DEFAULTS_SYSTEM_GUIDE.md)
→ 自动化：[guides/UNATTENDED_DEPLOYMENTS.md](guides/UNATTENDED_DEPLOYMENTS.md)
→ 调试：[DEV_MODE.md](DEV_MODE.md)

**架构师**
→ 阅读：[TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md)
→ 深入：[misc/README.md](misc/README.md)

---

## 📂 **文档结构**

### 项目镜像目录

每个主要项目目录都有文档：

```
ProxmoxVE/
├─ ct/                 ↔ docs/ct/ (README.md + DETAILED_GUIDE.md)
├─ install/           ↔ docs/install/ (README.md + DETAILED_GUIDE.md)
├─ vm/                ↔ docs/vm/ (README.md)
├─ tools/            ↔ docs/tools/ (README.md)
├─ api/              ↔ docs/api/ (README.md)
├─ misc/             ↔ docs/misc/ (9 个函数库)
└─ [系统级]          ↔ docs/guides/ (配置和部署指南)
```

### 核心文档

| 文档 | 目的 | 受众 |
|----------|---------|----------|
| [contribution/README.md](contribution/README.md) | 如何贡献 | 贡献者 |
| [ct/DETAILED_GUIDE.md](ct/DETAILED_GUIDE.md) | 创建 ct 脚本 | 容器开发者 |
| [install/DETAILED_GUIDE.md](install/DETAILED_GUIDE.md) | 创建安装脚本 | 安装开发者 |
| [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md) | 架构深入探讨 | 架构师，高级用户 |
| [guides/DEFAULTS_SYSTEM_GUIDE.md](guides/DEFAULTS_SYSTEM_GUIDE.md) | 配置系统 | 运维人员，高级用户 |
| [guides/CONFIGURATION_REFERENCE.md](guides/CONFIGURATION_REFERENCE.md) | 配置选项参考 | 高级用户 |
| [guides/UNATTENDED_DEPLOYMENTS.md](guides/UNATTENDED_DEPLOYMENTS.md) | 自动化部署 | DevOps，自动化 |
| [EXIT_CODES.md](EXIT_CODES.md) | 退出代码参考 | 故障排除者 |
| [DEV_MODE.md](DEV_MODE.md) | 调试工具 | 开发者 |

---

## 📂 **目录指南**

### [ct/](ct/) - 容器脚本
`/ct` 的文档 - 在 Proxmox 主机上运行的容器创建脚本。

**包括**：
- 容器创建过程概述
- 深入：[DETAILED_GUIDE.md](ct/DETAILED_GUIDE.md) - 带示例的完整参考
- 参考 [misc/build.func/](misc/build.func/)
- 创建新容器的快速开始

### [install/](install/) - 安装脚本
`/install` 的文档 - 在容器内运行以安装应用程序的脚本。

**包括**：
- 10 阶段安装模式概述
- 深入：[DETAILED_GUIDE.md](install/DETAILED_GUIDE.md) - 带示例的完整参考
- 参考 [misc/tools.func/](misc/tools.func/)
- Alpine vs Debian 差异

### [vm/](vm/) - 虚拟机脚本
`/vm` 的文档 - 使用 cloud-init 配置的 VM 创建脚本。

**包括**：
- VM 配置概述
- 链接到 [misc/cloud-init.func/](misc/cloud-init.func/)
- VM vs 容器比较
- Cloud-init 示例

### [tools/](tools/) - 工具和实用程序
`/tools` 的文档 - 管理工具和附加组件。

**包括**：
- 工具结构概述
- 集成点
- 贡献新工具
- 常见操作

### [api/](api/) - API 集成
`/api` 的文档 - 遥测和 API 后端。

**包括**：
- API 概述
- 集成方法
- API 端点
- 隐私信息

### [misc/](misc/) - 函数库
`/misc` 的文档 - 9 个核心函数库的完整参考。

**包含**：
- **build.func/** - 容器编排（7 个文件）
- **core.func/** - 实用程序和消息传递（5 个文件）
- **error_handler.func/** - 错误处理（5 个文件）
- **api.func/** - API 集成（5 个文件）
- **install.func/** - 容器设置（5 个文件）
- **tools.func/** - 包安装（6 个文件）
- **alpine-install.func/** - Alpine 设置（5 个文件）
- **alpine-tools.func/** - Alpine 工具（5 个文件）
- **cloud-init.func/** - VM 配置（5 个文件）

---

## 🎓 **学习路径**

### 路径 1：首次贡献者（2-3 小时）

1. [contribution/README.md](contribution/README.md) - 快速开始
2. 选择您的领域：
   - 容器 → [ct/README.md](ct/README.md) + [ct/DETAILED_GUIDE.md](ct/DETAILED_GUIDE.md)
   - 安装 → [install/README.md](install/README.md) + [install/DETAILED_GUIDE.md](install/DETAILED_GUIDE.md)
   - VM → [vm/README.md](vm/README.md)
3. 研究现有的类似脚本
4. 创建您的贡献
5. 提交 PR

### 路径 2：中级开发者（4-6 小时）

1. [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md)
2. 深入函数库：
   - [misc/build.func/README.md](misc/build.func/README.md)
   - [misc/tools.func/README.md](misc/tools.func/README.md)
   - [misc/install.func/README.md](misc/install.func/README.md)
3. 研究高级示例
4. 创建复杂应用程序

### 路径 3：高级架构师（8+ 小时）

1. 中级路径的所有内容
2. 深入研究所有 9 个函数库
3. [guides/DEFAULTS_SYSTEM_GUIDE.md](guides/DEFAULTS_SYSTEM_GUIDE.md) - 配置系统
4. [DEV_MODE.md](DEV_MODE.md) - 调试和开发
5. 设计新功能或函数库

### 路径 4：故障排除者（30 分钟 - 1 小时）

1. [EXIT_CODES.md](EXIT_CODES.md) - 查找错误代码
2. [DEV_MODE.md](DEV_MODE.md) - 使用调试运行
3. 检查相关函数库文档
4. 查看日志并修复

---

## 📊 **数据统计**

| 指标 | 数量 |
|--------|:---:|
| **文档文件** | 63 |
| **总行数** | 15,000+ |
| **函数库** | 9 |
| **已记录的函数** | 150+ |
| **代码示例** | 50+ |
| **流程图** | 15+ |
| **应该做/不应该做的部分** | 20+ |
| **实际示例** | 30+ |

---

## 🔍 **快速查找**

### 按功能
- **如何创建容器？** → [ct/DETAILED_GUIDE.md](ct/DETAILED_GUIDE.md)
- **如何创建安装脚本？** → [install/DETAILED_GUIDE.md](install/DETAILED_GUIDE.md)
- **如何创建 VM？** → [vm/README.md](vm/README.md)
- **如何安装 Node.js？** → [misc/tools.func/](misc/tools.func/)
- **如何调试？** → [DEV_MODE.md](DEV_MODE.md)

### 按错误
- **退出代码 206？** → [EXIT_CODES.md](EXIT_CODES.md)
- **网络失败？** → [misc/install.func/](misc/install.func/)
- **包错误？** → [misc/tools.func/](misc/tools.func/)

### 按角色
- **贡献者** → [contribution/README.md](contribution/README.md)
- **运维人员** → [guides/DEFAULTS_SYSTEM_GUIDE.md](guides/DEFAULTS_SYSTEM_GUIDE.md)
- **自动化** → [guides/UNATTENDED_DEPLOYMENTS.md](guides/UNATTENDED_DEPLOYMENTS.md)
- **开发者** → [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md)
- **架构师** → [misc/README.md](misc/README.md)

---

## ✅ **文档特性**

- ✅ **项目镜像结构** - 像实际项目一样组织
- ✅ **完整的函数参考** - 每个函数都有文档
- ✅ **实际示例** - 可复制粘贴的代码
- ✅ **可视化流程图** - 工作流的 ASCII 图表
- ✅ **集成指南** - 组件如何连接
- ✅ **故障排除** - 常见问题和解决方案
- ✅ **最佳实践** - 贯穿始终的应该做/不应该做部分
- ✅ **学习路径** - 按角色的结构化课程
- ✅ **快速参考** - 按错误代码快速查找
- ✅ **全面导航** - 本页面

---

## 🚀 **从这里开始**

**ProxmoxVE 新手？** → [contribution/README.md](contribution/README.md)

**寻找特定内容？** → 选择上面的角色或按目录浏览

**需要调试？** → [EXIT_CODES.md](EXIT_CODES.md)

**想要理解架构？** → [TECHNICAL_REFERENCE.md](TECHNICAL_REFERENCE.md)

---

## 🤝 **贡献文档**

发现错误？想要改进文档？

1. 参见：[contribution/README.md](contribution/README.md) 获取完整的贡献指南
2. 开启问题：[GitHub Issues](https://github.com/community-scripts/ProxmoxVE/issues)
3. 或提交带有改进的 PR

---

## 📝 **状态**

- **最后更新**：2025 年 12 月
- **版本**：2.3（整合和重组）
- **完整性**：✅ 100% - 所有组件已记录
- **质量**：✅ 生产就绪
- **结构**：✅ 清晰有序

---

**欢迎来到 ProxmoxVE！从 [CONTRIBUTION_GUIDE.md](CONTRIBUTION_GUIDE.md) 开始或选择上面的角色。** 🚀
