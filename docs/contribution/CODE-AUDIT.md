# 🧪 代码审计：LXC 脚本流程

本指南解释当前的执行流程以及在审查期间需要验证的内容。

## 执行流程（CT + Install）

1. `ct/appname.sh` 在 Proxmox 主机上运行并引用 `misc/build.func`。
2. `build.func` 协调提示、容器创建，并调用安装脚本。
3. 在容器内部，`misc/install.func` 通过 `$FUNCTIONS_FILE_PATH` 暴露辅助函数。
4. `install/appname-install.sh` 执行应用程序安装。
5. CT 脚本打印完成消息。

## 审计清单

### CT 脚本（ct/）

- 从 `community-scripts/ProxmoxVE/main` 引用 `misc/build.func`（setup-fork.sh 为分支更新）。
- 使用 `check_for_gh_release` + `fetch_and_deploy_gh_release` 进行更新。
- 不使用基于 Docker 的安装。

### 安装脚本（install/）

- 引用 `$FUNCTIONS_FILE_PATH`。
- 使用 `tools.func` 辅助函数（setup\_\*）。
- 以 `motd_ssh`、`customize`、`cleanup_lxc` 结束。

### JSON 元数据

- `frontend/public/json/<appname>.json` 中的文件与模板架构匹配。

### 测试

- 通过从您的分支 curl 测试（仅 CT 脚本）。
- 推送后等待 10-30 秒。

## 参考

- `docs/contribution/templates_ct/AppName.sh`
- `docs/contribution/templates_install/AppName-install.sh`
- `docs/contribution/templates_json/AppName.json`
- `docs/contribution/GUIDE.md`
