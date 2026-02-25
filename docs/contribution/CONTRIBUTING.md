# 社区脚本贡献指南

## **欢迎来到 community-scripts 仓库！**

📜 这些文档概述了我们所有脚本和 JSON 文件的基本编码标准。遵守这些标准可确保我们的代码库保持一致、可读和可维护。通过遵循这些指南，我们可以改善协作、减少错误并提高项目的整体质量。

### 为什么编码标准很重要

编码标准至关重要，原因如下：

1. **一致性**：一致的代码更易于阅读、理解和维护。它帮助新团队成员快速上手并减少学习曲线。
2. **可读性**：清晰且结构良好的代码更易于调试和扩展。它允许开发人员快速识别和修复问题。
3. **可维护性**：遵循标准结构的代码更易于重构和更新。它确保可以以最小的引入新错误的风险进行更改。
4. **协作**：当每个人都遵循相同的标准时，协作代码变得更容易。它减少了代码审查和合并期间的摩擦和误解。

### 这些文档的范围

这些文档涵盖了我们项目中以下类型文件的编码标准：

- **`install/$AppName-install.sh` 脚本**：这些脚本负责应用程序的安装。
- **`ct/$AppName.sh` 脚本**：这些脚本处理容器的创建和更新。
- **`json/$AppName.json`**：这些文件存储结构化数据并用于网站。

每个部分提供了关于编码各个方面的详细指南，包括 shebang 使用、注释、变量命名、函数命名、缩进、错误处理、命令替换、引用、脚本结构和日志记录。此外，还提供了示例来说明这些标准的应用。

通过遵循本文档中概述的编码标准，我们确保我们的脚本和 JSON 文件具有高质量，使我们的项目更加健壮且更易于管理。每当您创建或更新脚本和 JSON 文件时，请参考本指南，以在整个项目中保持高标准的代码质量。📚🔍

让我们共同努力，保持我们的代码库干净、高效和可维护！💪🚀

## 入门

在贡献之前，请确保您已完成以下设置：

1. **Visual Studio Code**（推荐用于脚本开发）
2. **推荐的 VS Code 扩展：**
   - [Shell Syntax](https://marketplace.visualstudio.com/items?itemName=bmalehorn.shell-syntax)
   - [ShellCheck](https://marketplace.visualstudio.com/items?itemName=timonwong.shellcheck)
   - [Shell Format](https://marketplace.visualstudio.com/items?itemName=foxundermoon.shell-format)

### 重要说明

- 创建新脚本时使用 [AppName.sh](https://github.com/jiege6-66/ProxmoxVE/blob/main/docs/contribution/templates_ct/AppName.sh) 和 [AppName-install.sh](https://github.com/jiege6-66/ProxmoxVE/blob/main/docs/contribution/templates_install/AppName-install.sh) 作为模板。

---

# 🚀 应用程序脚本（ct/AppName.sh）

- 您可以在[这里](https://github.com/jiege6-66/ProxmoxVE/blob/main/docs/contribution/templates_ct/AppName.md)找到此文件的所有编码标准以及结构。
- 这些脚本负责容器创建、设置必要的变量以及在安装后处理应用程序的更新。

---

# 🛠 安装脚本（install/AppName-install.sh）

- 您可以在[这里](https://github.com/jiege6-66/ProxmoxVE/blob/main/docs/contribution/templates_install/AppName-install.md)找到此文件的所有编码标准以及结构。
- 这些脚本负责应用程序的安装。

---

## 🚀 构建您自己的脚本

从[模板脚本](https://github.com/jiege6-66/ProxmoxVE/blob/main/docs/contribution/templates_install/AppName-install.sh)开始

---

## 🤝 贡献流程

### 1. 分叉仓库

分叉到您的 GitHub 账户

### 2. 在本地环境克隆您的分支

```bash
git clone https://github.com/yourUserName/ForkName
```

### 3. 创建新分支

```bash
git switch -c your-feature-branch
```

### 4. 运行 setup-fork.sh 自动配置您的分支

```bash
bash docs/contribution/setup-fork.sh --full
```

此脚本自动：

- 检测您的 GitHub 用户名
- 更新所有 curl URL 指向您的分支（用于测试）
- 创建包含您配置的 `.git-setup-info`
- 备份所有修改的文件（\*.backup）

**重要**：这会修改 600+ 个文件！提交 PR 时使用 cherry-pick（见下文）。

### 5. 仅提交您的新应用程序文件

```bash
git commit -m "Your commit message"
```

### 5. 推送到您的分支

```bash
git push origin your-feature-branch
```

### 6. Cherry-Pick：仅提交您的文件用于 PR

⚠️ **重要**：setup-fork.sh 修改了 600+ 个文件。您必须只提交您的 3 个新文件！

查看 [README.md - Cherry-Pick 指南](README.md#-cherry-pick-submitting-only-your-changes) 获取分步说明。

快速版本：

```bash
# 从上游创建干净的分支
git fetch upstream
git checkout -b submit/myapp upstream/main

# 仅复制您的文件
cp ../your-work-branch/ct/myapp.sh ct/myapp.sh
cp ../your-work-branch/install/myapp-install.sh install/myapp-install.sh
cp ../your-work-branch/frontend/public/json/myapp.json frontend/public/json/myapp.json

# 提交并验证
git add ct/myapp.sh install/myapp-install.sh frontend/public/json/myapp.json
git commit -m "feat: add MyApp"
git diff upstream/main --name-only  # 应该只显示您的 3 个文件

# 推送并创建 PR
git push origin submit/myapp
```

### 7. 创建 Pull Request

从 `submit/myapp` → `jiege6-66/ProxmoxVE/main` 打开 Pull Request。

验证 PR 仅显示这 3 个文件：

- `ct/myapp.sh`
- `install/myapp-install.sh`
- `frontend/public/json/myapp.json`

---

# 🛠️ 开发者模式和调试

构建或测试脚本时，您可以使用 `dev_mode` 变量启用强大的调试功能。这些标志可以组合使用（逗号分隔）。

**使用方法**：
```bash
# 示例：使用跟踪运行并在失败时保留容器
dev_mode="trace,keep" bash -c "$(curl -fsSL https://raw.githubusercontent.com/jiege6-66/ProxmoxVE/main/ct/myapp.sh)"
```

### 可用标志：

| 标志 | 描述 |
| :--- | :--- |
| `trace` | 启用 `set -x` 以在执行期间获得最大详细程度。 |
| `keep` | 如果构建失败，防止容器被删除。 |
| `pause` | 在关键点暂停执行（例如，在自定义之前）。 |
| `breakpoint` | 允许脚本中的硬编码 `breakpoint` 调用进入 shell。 |
| `logs` | 将详细的构建日志保存到 `/var/log/community-scripts/`。 |
| `dryrun` | 绕过实际的容器创建（有限支持）。 |
| `motd` | 强制更新每日消息（MOTD）。 |

---

## 📚 页面

- [CT 模板：AppName.sh](https://github.com/jiege6-66/ProxmoxVE/blob/main/docs/contribution/templates_ct/AppName.sh)
- [安装模板：AppName-install.sh](https://github.com/jiege6-66/ProxmoxVE/blob/main/docs/contribution/templates_install/AppName-install.sh)
- [JSON 模板：AppName.json](https://github.com/jiege6-66/ProxmoxVE/blob/main/docs/contribution/templates_json/AppName.json)
