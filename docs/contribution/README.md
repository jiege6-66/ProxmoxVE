# 🤝 为 ProxmoxVE 做贡献

从第一次分叉到提交拉取请求的完整贡献指南。

---

## 📋 目录

- [快速开始](#快速开始)
- [设置您的分支](#设置您的分支)
- [编码标准](#编码标准)
- [代码审计](#代码审计)
- [指南和资源](#指南和资源)
- [常见问题](#常见问题)

---

## 🚀 快速开始

### 60 秒开始贡献（开发）

在**您的分支**中开发和测试时：

```bash
# 1. 在 GitHub 上分叉
# 访问：https://github.com/community-scripts/ProxmoxVE → Fork（右上角）

# 2. 克隆您的分支
git clone https://github.com/YOUR_USERNAME/ProxmoxVE.git
cd ProxmoxVE

# 3. 自动配置您的分支（重要 - 更新所有链接！）
bash docs/contribution/setup-fork.sh --full

# 4. 创建功能分支
git checkout -b feature/my-awesome-app

# 5. 阅读指南
cat docs/README.md              # 文档概述
cat docs/ct/DETAILED_GUIDE.md   # 容器脚本
cat docs/install/DETAILED_GUIDE.md  # 安装脚本

# 6. 创建您的贡献
cp docs/contribution/templates_ct/AppName.sh ct/myapp.sh
cp docs/contribution/templates_install/AppName-install.sh install/myapp-install.sh
# ... 编辑文件 ...

# 7. 推送到您的分支并通过 GitHub 测试
git push origin feature/my-awesome-app
bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/ct/myapp.sh)"
# ⏱️ GitHub 可能需要 10-30 秒更新文件 - 请耐心等待！

# 8. 创建您的 JSON 元数据文件
cp docs/contribution/templates_json/AppName.json frontend/public/json/myapp.json
# 编辑元数据：name、slug、categories、description、resources 等

# 9. 不要直接测试安装脚本
# 安装脚本由 CT 脚本在容器内执行

# 10. 仅提交您的新文件（见下面的 Cherry-Pick 部分！）
git add ct/myapp.sh install/myapp-install.sh frontend/public/json/myapp.json
git commit -m "feat: add MyApp container and install scripts"
git push origin feature/my-awesome-app

# 11. 在 GitHub 上创建拉取请求
```

⚠️ **重要：运行 setup-fork.sh 后，许多文件被修改！**

查看下面的 **Cherry-Pick：仅提交您的更改** 部分，了解如何仅推送您的 3-4 个文件，而不是 600+ 个修改的文件！

### 用户如何运行脚本（合并后）

一旦您的脚本合并到主仓库，用户从 GitHub 下载并运行它，如下所示：

```bash
# ✅ 用户从 GitHub 运行（PR 合并后的正常使用）
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/myapp.sh)"

# 安装脚本由 CT 脚本调用，用户不直接运行
```

### 开发与生产执行

**开发期间（您，在您的分支中）：**

```bash
# 您必须通过 GitHub 分支的 curl 测试（不是本地文件！）
bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/ct/myapp.sh)"

# 脚本的 curl 命令由 setup-fork.sh 更新为指向您的分支
# 这确保您正在测试实际的更改
# ⏱️ 推送后等待 10-30 秒 - GitHub 更新缓慢
```

**合并后（用户，从 GitHub）：**

```bash
# 用户通过 curl 从上游下载脚本
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/myapp.sh)"

# 脚本的 curl 命令现在指向上游（community-scripts）
# 这是稳定的、经过测试的版本
```

**总结：**

- **开发**：推送到分支，通过 curl 测试 → setup-fork.sh 将 curl URL 更改为您的分支
- **生产**：从上游 curl | bash → curl URL 指向 community-scripts 仓库

---

## 🍴 设置您的分支

### 自动设置（推荐）

克隆分支后，运行设置脚本自动配置所有内容：

```bash
bash docs/contribution/setup-fork.sh --full
```

**它做什么：**

- 从 git config 自动检测您的 GitHub 用户名
- 自动检测您的分支仓库名称
- 更新**所有**硬编码链接指向您的分支而不是主仓库（`--full`）
- 创建包含您配置的 `.git-setup-info`
- 允许您在分支中独立开发和测试

**为什么这很重要：**

如果不运行此脚本，分支中的所有链接仍将指向上游仓库（community-scripts）。这在测试时是个问题，因为：

- 安装链接将从上游拉取，而不是您的分支
- 更新将针对错误的仓库
- 您的贡献将无法正确测试

**运行 setup-fork.sh 后：**

您的分支已完全配置并准备好开发。您可以：

- 将更改推送到您的分支
- 通过 curl 测试：`bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/ct/myapp.sh)"`
- 所有链接将引用您的分支进行开发
- ⏱️ 推送后等待 10-30 秒 - GitHub 需要时间更新
- 自信地提交和推送
- 创建 PR 合并到上游

**查看**：[FORK_SETUP.md](FORK_SETUP.md) 获取详细说明

### 手动设置

如果脚本不起作用，手动配置：

```bash
# 设置 git 用户
git config user.name "Your Name"
git config user.email "your.email@example.com"

# 添加上游远程以与主仓库同步
git remote add upstream https://github.com/community-scripts/ProxmoxVE.git

# 验证远程
git remote -v
# 应该显示：origin（您的分支）和 upstream（主仓库）
```

---

## 📖 编码标准

所有脚本和配置必须遵循我们的编码标准以确保一致性和质量。

### 可用指南

- **[CONTRIBUTING.md](CONTRIBUTING.md)** - 基本编码标准和最佳实践
- **[CODE_AUDIT.md](CODE_AUDIT.md)** - 代码审查清单和审计程序
- **[GUIDE.md](GUIDE.md)** - 综合贡献指南
- **[HELPER_FUNCTIONS.md](HELPER_FUNCTIONS.md)** - 所有 tools.func 辅助函数的参考
- **容器脚本** - `/ct/` 模板和指南
- **安装脚本** - `/install/` 模板和指南
- **JSON 配置** - `frontend/public/json/` 结构和格式

### 快速清单

- ✅ 使用 `/ct/example.sh` 作为容器脚本的模板
- ✅ 使用 `/install/example-install.sh` 作为安装脚本的模板
- ✅ 遵循命名约定：`appname.sh` 和 `appname-install.sh`
- ✅ 包含正确的 shebang：`#!/usr/bin/env bash`
- ✅ 添加带有作者的版权头
- ✅ 使用 `msg_error`、`msg_ok` 等正确处理错误
- ✅ 提交 PR 前测试（通过您分支的 curl，而不是本地 bash）
- ✅ 如需要，更新文档

---

## 🔍 代码审计

提交拉取请求之前，确保您的代码通过我们的审计：

**查看**：[CODE_AUDIT.md](CODE_AUDIT.md) 获取完整的审计清单

关键点：

- 代码与现有脚本的一致性
- 正确的错误处理
- 正确的变量命名
- 充分的注释和文档
- 安全最佳实践

---

## 🍒 Cherry-Pick：仅提交您的更改

**问题**：`setup-fork.sh` 修改了 600+ 个文件以更新链接。您不想提交所有这些更改 - 只提交您的新 3-4 个文件！

**解决方案**：使用 git cherry-pick 仅选择您的文件。

### 分步 Cherry-Pick 指南

#### 1. 检查更改了什么

```bash
# 查看所有修改的文件
git status

# 验证您的文件在那里
git status | grep -E "ct/myapp|install/myapp|json/myapp"
```

#### 2. 为提交创建干净的功能分支

```bash
# 回到上游 main（干净的起点）
git fetch upstream
git checkout -b submit/myapp upstream/main

# 不要使用您修改的 main 分支！
```

#### 3. 仅 Cherry-pick 您的文件

Cherry-picking 从提交中提取特定更改：

```bash
# 选项 A：Cherry-pick 添加您文件的提交
# （如果您单独提交了文件）
git cherry-pick <commit-hash-of-your-files>

# 选项 B：手动复制并仅提交您的文件
# 从您的工作分支获取文件内容
git show feature/my-awesome-app:ct/myapp.sh > /tmp/myapp.sh
git show feature/my-awesome-app:install/myapp-install.sh > /tmp/myapp-install.sh
git show feature/my-awesome-app:frontend/public/json/myapp.json > /tmp/myapp.json

# 将它们添加到干净的分支
cp /tmp/myapp.sh ct/myapp.sh
cp /tmp/myapp-install.sh install/myapp-install.sh
cp /tmp/myapp.json frontend/public/json/myapp.json

# 提交
git add ct/myapp.sh install/myapp-install.sh frontend/public/json/myapp.json
git commit -m "feat: add MyApp"
```

#### 4. 验证 PR 中仅有您的文件

```bash
# 检查与上游的 git diff
git diff upstream/main --name-only
# 应该仅显示：
#   ct/myapp.sh
#   install/myapp-install.sh
#   frontend/public/json/myapp.json
```

#### 5. 推送并创建 PR

```bash
# 推送您的干净提交分支
git push origin submit/myapp

# 在 GitHub 上创建 PR：submit/myapp → main
```

### 为什么这很重要

- ✅ 仅包含您更改的干净 PR
- ✅ 维护者更容易审查
- ✅ 更快合并，无冲突
- ❌ 没有 cherry-pick：PR 有 600+ 文件更改（不会合并！）

### 如果您犯了错误

```bash
# 删除混乱的分支
git branch -D submit/myapp

# 回到干净的分支
git checkout -b submit/myapp upstream/main

# 再次尝试 cherry-picking
```

---

## 🤖 使用 AI 助手

如果您使用带有 AI 助手的 **Visual Studio Code**，您可以利用我们的详细指南自动生成高质量的贡献。

### 如何使用 AI 协助

1. **打开 AI 指南**

   ```
   docs/contribution/AI.md
   ```

   此文件包含编写正确脚本的所有要求、模式和示例。

2. **准备您的信息**

   在要求 AI 生成代码之前，收集：
   - **仓库 URL**：例如，`https://github.com/owner/myapp`
   - **Dockerfile/脚本**：粘贴应用的安装说明（如果可用）
   - **依赖项**：它需要什么包？（Node、Python、Java、PostgreSQL 等）
   - **端口**：它监听什么端口？（例如，3000、8080、5000）
   - **配置**：任何环境变量或配置文件？

3. **告诉 AI 助手**

   与 AI 分享：
   - 仓库 URL
   - Dockerfile 或安装说明
   - 链接到 [docs/contribution/AI.md](AI.md) 并遵循说明

   **示例提示：**

   ```
   我想为 ProxmoxVE 贡献 MyApp 的容器脚本。
   仓库：https://github.com/owner/myapp

   这是 Dockerfile：
   [粘贴 Dockerfile 内容]

   请遵循 docs/contribution/AI.md 中的指南创建：
   1. ct/myapp.sh（容器脚本）
   2. install/myapp-install.sh（安装脚本）
   3. frontend/public/json/myapp.json（元数据）
   ```

4. **AI 将生成**

   AI 将生成以下脚本：
   - 遵循所有 ProxmoxVE 模式和约定
   - 正确使用 `tools.func` 中的辅助函数
   - 包含正确的错误处理和消息
   - 具有正确的更新机制
   - 准备好作为 PR 提交

### AI 助手的关键点

- **模板位置**：`docs/contribution/templates_ct/AppName.sh`、`templates_install/`、`templates_json/`
- **指南**：必须完全遵循 `docs/contribution/AI.md`
- **辅助函数**：仅使用 `misc/tools.func` 中的函数 - 永远不要编写自定义函数
- **测试**：提交前始终通过您分支的 curl 测试
  ```bash
  bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/ct/myapp.sh)"
  # 推送更改后等待 10-30 秒
  ```
- **不使用 Docker**：容器脚本必须是裸机，而不是基于 Docker

### 好处

- **速度**：AI 在几秒钟内生成样板
- **一致性**：遵循与 200+ 现有脚本相同的模式
- **质量**：更少的错误和更易维护的代码
- **学习**：了解您的应用应该如何构建

---

## 📚 文档

- **[docs/README.md](../README.md)** - 主文档中心
- **[docs/ct/README.md](../ct/README.md)** - 容器脚本概述
- **[docs/install/README.md](../install/README.md)** - 安装脚本概述
- **[docs/ct/DETAILED_GUIDE.md](../ct/DETAILED_GUIDE.md)** - 完整的 ct/ 脚本参考
- **[docs/install/DETAILED_GUIDE.md](../install/DETAILED_GUIDE.md)** - 完整的 install/ 脚本参考
- **[docs/TECHNICAL_REFERENCE.md](../TECHNICAL_REFERENCE.md)** - 架构深入探讨
- **[docs/EXIT_CODES.md](../EXIT_CODES.md)** - 退出代码参考
- **[docs/DEV_MODE.md](../DEV_MODE.md)** - 调试指南

### 社区指南

查看 [USER_SUBMITTED_GUIDES.md](USER_SUBMITTED_GUIDES.md) 获取优秀的社区编写指南：

- Home Assistant 安装和配置
- Proxmox 上的 Frigate 设置
- Docker 和 Portainer 安装
- 数据库设置和优化
- 还有更多！

### 模板

创建新脚本时使用这些模板：

```bash
# 容器脚本模板
cp docs/contribution/templates_ct/AppName.sh ct/my-app.sh

# 安装脚本模板
cp docs/contribution/templates_install/AppName-install.sh install/my-app-install.sh

# JSON 配置模板
cp docs/contribution/templates_json/AppName.json frontend/public/json/my-app.json
```

**模板功能：**

- 更新以匹配当前代码库模式
- 包含 `tools.func` 中所有可用的辅助函数
- Node.js、Python、PHP、Go 应用的示例
- 数据库设置示例（MariaDB、PostgreSQL）
- 正确的服务创建和清理

---

## 🔄 Git 工作流

### 保持您的分支更新

```bash
# 从上游获取最新内容
git fetch upstream

# 在最新 main 上 rebase 您的工作
git rebase upstream/main

# 推送到您的分支
git push -f origin main
```

### 创建功能分支

```bash
# 创建并切换到新分支
git checkout -b feature/my-feature

# 进行更改...
git add .
git commit -m "feat: description of changes"

# 推送到您的分支
git push origin feature/my-feature

# 在 GitHub 上创建拉取请求
```

### 提交 PR 之前

1. **与上游同步**

   ```bash
   git fetch upstream
   git rebase upstream/main
   ```

2. **测试您的更改**（通过您分支的 curl）

   ```bash
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/ct/my-app.sh)"
   # 按照提示测试容器
   # ⏱️ 推送后等待 10-30 秒 - GitHub 需要时间更新
   ```

3. **检查代码标准**
   - [ ] 遵循模板结构
   - [ ] 正确的错误处理
   - [ ] 文档已更新（如需要）
   - [ ] 无硬编码值
   - [ ] 实现版本跟踪

4. **推送最终更改**
   ```bash
   git push origin feature/my-feature
   ```

---

## 📋 拉取请求清单

打开 PR 之前：

- [ ] 代码遵循编码标准（见 CONTRIBUTING.md）
- [ ] 所有模板正确使用
- [ ] 在 Proxmox VE 上测试
- [ ] 实现错误处理
- [ ] 文档已更新（如适用）
- [ ] 无合并冲突
- [ ] 与 upstream/main 同步
- [ ] 清晰的 PR 标题和描述

---

## ❓ 常见问题

### ❌ 为什么我不能用 `bash ct/myapp.sh` 在本地测试？

您可能会尝试：

```bash
# ❌ 错误 - 这不会测试您的实际更改！
bash ct/myapp.sh
./ct/myapp.sh
sh ct/myapp.sh
```

**为什么这会失败：**

- `bash ct/myapp.sh` 使用本地克隆文件
- 本地文件不执行 curl 命令 - 它已经在磁盘上
- 脚本内部的 curl URL 由 setup-fork.sh 修改，但它们不会被执行
- 所以您无法验证 curl URL 是否实际工作
- 用户将获得 curl URL 版本（可能已损坏）

**解决方案：** 始终通过 GitHub 的 curl 测试：

```bash
# ✅ 正确 - 测试实际的 GitHub URL
bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/ct/myapp.sh)"
```

### ❓ 如何测试我的更改？

您**不能**从克隆的目录使用 `bash ct/myapp.sh` 在本地测试！

您**必须**推送到 GitHub 并通过您分支的 curl 测试：

```bash
# 1. 将更改推送到您的分支
git push origin feature/my-awesome-app

# 2. 通过 curl 测试（这从 GitHub 加载脚本，而不是本地文件）
bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/ct/my-app.sh)"

# 3. 对于详细/调试输出，传递环境变量
VERBOSE=yes bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/ct/my-app.sh)"
DEV_MODE_LOGS=true bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/ct/my-app.sh)"
```

**为什么？**

- 本地 `bash ct/myapp.sh` 使用克隆中的本地文件
- 但脚本的内部 curl 命令已由 setup-fork.sh 修改为指向您的分支
- 这种差异意味着您实际上没有测试 curl URL
- 通过 curl 测试确保脚本从您的分支 GitHub URL 下载
- ⏱️ **重要：** GitHub 需要 10-30 秒识别新推送的文件。测试前请等待！

**如果本地 bash 有效会怎样？**

您只会测试本地文件，而不是用户将下载的实际 GitHub URL。这意味着损坏的 curl 链接在测试期间不会被发现。

### 如果我的 PR 有冲突怎么办？

```bash
# 与上游主仓库同步
git fetch upstream
git rebase upstream/main

# 在编辑器中解决冲突
git add .
git rebase --continue
git push -f origin your-branch
```

### 如何保持我的分支更新？

两种方式：

**选项 1：再次运行设置脚本**

```bash
bash docs/contribution/setup-fork.sh --full
```

**选项 2：手动同步**

```bash
git fetch upstream
git rebase upstream/main
git push -f origin main
```

### 我在哪里提问？

- **GitHub Issues**：用于错误和功能请求
- **GitHub Discussions**：用于一般问题和想法
- **Discord**：Community-scripts 服务器用于实时聊天

---

## 🎓 学习资源

### 对于首次贡献者

1. 阅读：[docs/README.md](../README.md) - 文档概述
2. 阅读：[CONTRIBUTING.md](CONTRIBUTING.md) - 基本编码标准
3. 选择您的路径：
   - 容器 → [docs/ct/DETAILED_GUIDE.md](../ct/DETAILED_GUIDE.md)
   - 安装 → [docs/install/DETAILED_GUIDE.md](../install/DETAILED_GUIDE.md)
4. 研究同类别中的现有脚本
5. 创建您的贡献

### 对于有经验的开发者

1. 审查 [CONTRIBUTING.md](CONTRIBUTING.md) - 编码标准
2. 审查 [CODE_AUDIT.md](CODE_AUDIT.md) - 审计清单
3. 检查 `/docs/contribution/templates_*/` 中的模板
4. 使用 AI 助手和 [AI.md](AI.md) 进行代码生成
5. 自信地提交 PR

### 对于使用 AI 助手

查看上面的"使用 AI 助手"部分了解：

- 如何构建提示
- 提供什么信息
- 如何验证 AI 输出

---

## 🚀 准备好贡献了吗？

1. **分叉**仓库
2. **克隆**您的分支并使用 `bash docs/contribution/setup-fork.sh --full` **设置**
3. **选择**您的贡献类型（容器、安装、工具等）
4. **阅读**适当的详细指南
5. **创建**您的功能分支
6. **开发**和**测试**您的更改
7. **提交**清晰的消息
8. **推送**到您的分支
9. **创建**拉取请求

---

## 📞 联系和支持

- **GitHub**：[community-scripts/ProxmoxVE](https://github.com/community-scripts/ProxmoxVE)
- **Issues**：[GitHub Issues](https://github.com/community-scripts/ProxmoxVE/issues)
- **Discussions**：[GitHub Discussions](https://github.com/community-scripts/ProxmoxVE/discussions)
- **Discord**：[加入服务器](https://discord.gg/UHrpNWGwkH)

---

**感谢您为 ProxmoxVE 做贡献！** 🙏

您的努力帮助使 Proxmox VE 自动化对每个人都可访问。祝编码愉快！🚀
