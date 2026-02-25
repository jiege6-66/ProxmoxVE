# 🍴 分支设置指南

**刚刚分叉了 ProxmoxVE？先运行这个！**

## 快速开始

```bash
# 克隆您的分支
git clone https://github.com/YOUR_USERNAME/ProxmoxVE.git
cd ProxmoxVE

# 运行设置脚本（从 git 自动检测您的用户名）
bash docs/contribution/setup-fork.sh --full
```

就是这样！✅

---

## 它做什么？

`setup-fork.sh` 脚本自动：

1. **检测** 从 git config 获取您的 GitHub 用户名
2. **更新所有硬编码链接** 指向您的分支：
   - 指向 `community-scripts/ProxmoxVE` 的文档链接
   - **脚本中的 Curl 下载 URL**（例如，`curl ... github.com/community-scripts/ProxmoxVE/main/...`）
3. **创建** `.git-setup-info` 包含您的配置详细信息
4. **备份** 所有修改的文件（\*.backup 以确保安全）

### 为什么更新 Curl 链接很重要

您的脚本包含从 GitHub 下载依赖项的 `curl` 命令（build.func、tools.func 等）：

```bash
# ct/myapp.sh 的第一行
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
```

**没有 setup-fork.sh：**

- 脚本 URL 仍然指向 `community-scripts/ProxmoxVE/main`
- 如果您使用 `bash ct/myapp.sh` 在本地测试，您正在测试本地文件，但脚本的 curl 命令会从**上游**仓库下载
- 您的修改实际上没有通过 curl 命令进行测试！❌

**运行 setup-fork.sh 后：**

- 脚本 URL 更新为 `YourUsername/ProxmoxVE/main`
- 当您通过 GitHub 的 curl 测试时：`bash -c "$(curl ... YOUR_USERNAME/ProxmoxVE/main/ct/myapp.sh)"`，它从**您的分支**下载
- 脚本的 curl 命令也指向您的分支，所以您实际上在测试您的更改！✅
- ⏱️ **重要：** GitHub 需要 10-30 秒来识别推送的文件 - 测试前请等待！

```bash
# 示例：setup-fork.sh 更改的内容

# 之前（指向上游）：
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)

# 之后（指向您的分支）：
source <(curl -fsSL https://raw.githubusercontent.com/john/ProxmoxVE/main/misc/build.func)
```

---

## 使用方法

### 自动检测（推荐）

```bash
bash docs/contribution/setup-fork.sh --full
```

自动从 `git remote origin url` 读取您的 GitHub 用户名

### 指定用户名

```bash
bash docs/contribution/setup-fork.sh --full john
```

将链接更新为 `github.com/john/ProxmoxVE`

### 自定义仓库名称

```bash
bash docs/contribution/setup-fork.sh --full john my-fork
```

将链接更新为 `github.com/john/my-fork`

---

## 更新了什么？

使用 `--full` 时，脚本会更新这些区域中的硬编码链接：

- `ct/`、`install/`、`vm/` 脚本
- `misc/` 函数库
- `docs/`（包括 `docs/contribution/`）
- 文档中的代码示例

---

## 设置后

1. **查看更改**

   ```bash
   git diff docs/
   ```

2. **阅读 git 工作流提示**

   ```bash
   cat .git-setup-info
   ```

3. **开始贡献**

   ```bash
   git checkout -b feature/my-app
   # 进行更改...
   git commit -m "feat: add my awesome app"
   ```

4. **遵循指南**
   ```bash
   cat docs/contribution/GUIDE.md
   ```

---

## 常见工作流

### 保持您的分支更新

```bash
# 如果还没有添加上游
git remote add upstream https://github.com/community-scripts/ProxmoxVE.git

# 从上游获取最新内容
git fetch upstream
git rebase upstream/main
git push origin main
```

### 创建功能分支

```bash
git checkout -b feature/docker-improvements
# 进行更改...
git push origin feature/docker-improvements
# 然后在 GitHub 上创建 PR
```

### 贡献前同步

```bash
git fetch upstream
git rebase upstream/main
git push -f origin main  # 更新您分支的 main
git checkout -b feature/my-feature
```

---

## 故障排除

### "Git 未安装"或"不是 git 仓库"

```bash
# 确保您首先克隆了仓库
git clone https://github.com/YOUR_USERNAME/ProxmoxVE.git
cd ProxmoxVE
bash docs/contribution/setup-fork.sh --full
```

### "无法自动检测 GitHub 用户名"

```bash
# 您的 git origin URL 设置不正确
git remote -v
# 应该显示您的分支 URL，而不是 community-scripts

# 修复它：
git remote set-url origin https://github.com/YOUR_USERNAME/ProxmoxVE.git
bash docs/contribution/setup-fork.sh --full
```

### "权限被拒绝"

```bash
# 使脚本可执行
chmod +x docs/contribution/setup-fork.sh
bash docs/contribution/setup-fork.sh --full
```

### 意外恢复了更改？

```bash
# 自动创建备份
git checkout docs/*.backup
# 或者只需重新运行 setup-fork.sh
bash docs/contribution/setup-fork.sh --full
```

---

## 下一步

1. ✅ 运行 `bash docs/contribution/setup-fork.sh --full`
2. 📖 阅读 [docs/contribution/GUIDE.md](GUIDE.md)
3. 🍴 选择您的贡献路径：
   - **容器** → [docs/ct/README.md](docs/ct/README.md)
   - **安装** → [docs/install/README.md](docs/install/README.md)
   - **虚拟机** → [docs/vm/README.md](docs/vm/README.md)
   - **工具** → [docs/tools/README.md](docs/tools/README.md)
4. 💻 创建您的功能分支并贡献！

---

## 有问题？

- **分支设置问题？** → 查看上面的[故障排除](#故障排除)
- **如何贡献？** → [docs/contribution/GUIDE.md](GUIDE.md)
- **Git 工作流？** → `cat .git-setup-info`
- **项目结构？** → [docs/README.md](docs/README.md)

---

## 祝贡献愉快！🚀
