# CT 容器脚本 - 快速参考

> [!WARNING]
> **这是旧版文档。** 请参考 [templates_ct/AppName.sh](AppName.sh) 中的**现代模板**以获取最佳实践。
>
> 当前模板使用：
>
> - `tools.func` 辅助函数而不是手动模式
> - 来自 build.func 的 `check_for_gh_release` 和 `fetch_and_deploy_gh_release`
> - 自动 setup-fork.sh 配置

---

## 创建脚本之前

1. **分叉和克隆：**

   ```bash
   git clone https://github.com/YOUR_USERNAME/ProxmoxVE.git
   cd ProxmoxVE
   ```

2. **运行 setup-fork.sh**（将所有 curl URL 更新到您的分支）：

   ```bash
   bash docs/contribution/setup-fork.sh
   ```

3. **复制现代模板：**

   ```bash
   cp templates_ct/AppName.sh ct/MyApp.sh
   # 使用您的应用详细信息编辑 ct/MyApp.sh
   ```

4. **测试您的脚本（通过 GitHub）：**

   ⚠️ **重要：** 您必须推送到 GitHub 并通过 curl 测试，而不是 `bash ct/MyApp.sh`！

   ```bash
   # 首先将更改推送到您的分支
   git push origin feature/my-awesome-app

   # 然后通过 curl 测试（这从您的分支加载，而不是本地文件）
   bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/ct/MyApp.sh)"
   ```

   > 💡 **为什么？** 脚本的 curl 命令由 setup-fork.sh 修改，但本地执行使用本地文件，而不是更新的 GitHub URL。通过 curl 测试可确保您的脚本实际工作。
   >
   > ⏱️ **注意：** GitHub 有时需要 10-30 秒来更新文件。如果您没有看到更改，请等待并重试。

5. **Cherry-Pick 用于 PR**（仅提交您的 3-4 个文件）：
   - 查看 [Cherry-Pick 指南](../README.md) 获取分步 git 命令

---

## 模板结构

现代模板包括：

### 头部

```bash
#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# （注意：setup-fork.sh 在开发期间将此 URL 更改为指向您的分支）
```

### 元数据

```bash
# Copyright (c) 2021-2026 community-scripts ORG
# Author: YourUsername
# License: MIT
APP="MyApp"
var_tags="app-category;foss"
var_cpu="2"
var_ram="2048"
var_disk="4"
var_os="alpine"
var_version="3.20"
var_unprivileged="1"
```

### 核心设置

```bash
header_info "$APP"
variables
color
catch_errors
```

### 更新函数

现代模板提供标准更新模式：

```bash
function update_script() {
  header_info
  check_container_storage
  check_container_resources

  # 使用 tools.func 辅助函数：
  check_for_gh_release "myapp" "owner/repo"
  fetch_and_deploy_gh_release "myapp" "owner/repo" "tarball" "latest" "/opt/myapp"
}
```

---

## 关键模式

### 检查更新（应用仓库）

使用 `check_for_gh_release` 与**应用仓库**：

```bash
check_for_gh_release "myapp" "owner/repo"
```

### 部署外部应用

使用 `fetch_and_deploy_gh_release` 与**应用仓库**：

```bash
fetch_and_deploy_gh_release "myapp" "owner/repo"
```

### 避免手动版本检查

❌ 旧方式（手动）：

```bash
RELEASE=$(curl -fsSL https://api.github.com/repos/myapp/myapp/releases/latest | grep tag_name)
```

✅ 新方式（使用 tools.func）：

```bash
fetch_and_deploy_gh_release "myapp" "owner/repo"
```

---

## 最佳实践

1. **使用 tools.func 辅助函数** - 不要手动 curl 获取版本
2. **仅添加应用特定的依赖项** - 不要添加 ca-certificates、curl、gnupg（由 build.func 处理）
3. **通过您的分支 curl 测试** - 首先推送，然后：`bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/ProxmoxVE/main/ct/MyApp.sh)"`
4. **等待 GitHub 更新** - git push 后需要 10-30 秒
5. **仅 cherry-pick 您的文件** - 仅提交 ct/MyApp.sh、install/MyApp-install.sh、frontend/public/json/myapp.json（3 个文件）
6. **PR 前验证** - 运行 `git diff upstream/main --name-only` 确认仅更改了您的文件

---

## 常见更新模式

查看[现代模板](AppName.sh)和 [AI.md](../AI.md) 获取完整的工作示例。

具有良好更新函数的最新参考脚本：

- [Trip](https://github.com/community-scripts/ProxmoxVE/blob/main/ct/trip.sh)
- [Thingsboard](https://github.com/community-scripts/ProxmoxVE/blob/main/ct/thingsboard.sh)
- [UniFi](https://github.com/community-scripts/ProxmoxVE/blob/main/ct/unifi.sh)

---

## 需要帮助？

- **[README.md](../README.md)** - 完整的贡献工作流
- **[AI.md](../AI.md)** - AI 生成的脚本指南
- **[FORK_SETUP.md](../FORK_SETUP.md)** - 为什么 setup-fork.sh 很重要
- **[Slack 社区](https://discord.gg/your-link)** - 提问

### 3.4 **详细程度**

- 使用适当的标志（示例中的 **-q**）来抑制命令的输出。
  示例：

```bash
curl -fsSL
unzip -q
```

- 如果命令没有此功能，请使用 `$STD` 来抑制其输出。

示例：

```bash
$STD php artisan migrate --force
$STD php artisan config:clear
```

### 3.5 **备份**

- 必要时备份用户数据。
- 更新完成后将所有用户数据移回目录。

> [!NOTE]
> 这不是永久备份

备份示例：

```bash
  mv /opt/snipe-it /opt/snipe-it-backup
```

配置恢复示例：

```bash
  cp /opt/snipe-it-backup/.env /opt/snipe-it/.env
  cp -r /opt/snipe-it-backup/public/uploads/ /opt/snipe-it/public/uploads/
  cp -r /opt/snipe-it-backup/storage/private_uploads /opt/snipe-it/storage/private_uploads
```

### 3.6 **清理**

- 不要忘记删除任何临时文件/文件夹，如 zip 文件或临时备份。
  示例：

```bash
  rm -rf /opt/v${RELEASE}.zip
  rm -rf /opt/snipe-it-backup
```

### 3.7 **无更新函数**

- 如果您无法提供更新函数，请使用以下代码提供用户反馈。

```bash
function update_script() {
    header_info
    check_container_storage
    check_container_resources
    if [[ ! -d /opt/snipeit ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi
    msg_error "Currently we don't provide an update function for this ${APP}."
    exit
}
```

---

## 4 **脚本结尾**

- `start`：启动 Whiptail 对话框
- `build_container`：收集并集成用户设置
- `description`：设置 LXC 容器描述
- 使用 `echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"` 可以指向用户访问应用所需的 IP:PORT/folder。

```bash
start
build_container
description

msg_ok "Completed successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}http://${IP}${CL}"
```

---

## 5. **贡献清单**

- [ ] Shebang 设置正确（`#!/usr/bin/env bash`）。
- [ ] 正确链接到 _build.func_
- [ ] 顶部包含元数据（作者、许可证）。
- [ ] 变量遵循命名约定。
- [ ] 存在更新函数。
- [ ] 更新函数检查应用是否已安装以及是否有新版本。
- [ ] 更新函数清理临时文件。
- [ ] 脚本以帮助用户访问应用的有用消息结束。
