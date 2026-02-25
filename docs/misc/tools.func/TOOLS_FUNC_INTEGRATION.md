# tools.func 集成指南

tools.func 如何与其他组件集成，并为 ProxmoxVE 生态系统提供包/工具服务。

## 组件关系

### tools.func 在安装流程中的位置

```
ct/AppName.sh (宿主机)
    │
    ├─ 调用 build.func
    │
    └─ 创建容器
            │
            ▼
install/appname-install.sh (容器内)
            │
            ├─ 引入: core.func (颜色、消息)
            ├─ 引入: error_handler.func (错误处理)
            ├─ 引入: install.func (容器设置)
            │
            └─ ★ 引入: tools.func ★
                        │
                        ├─ pkg_update()
                        ├─ pkg_install()
                        ├─ setup_nodejs()
                        ├─ setup_php()
                        ├─ setup_mariadb()
                        └─ ... 30+ 个函数
```

### 与 core.func 的集成

**tools.func 使用 core.func 提供的**:
- `msg_info()` - 显示进度消息
- `msg_ok()` - 显示成功消息
- `msg_error()` - 显示错误消息
- `msg_warn()` - 显示警告
- 颜色代码 (GN, RD, YW, BL) 用于格式化输出
- `$STD` 变量 - 输出抑制控制

**示例**:
```bash
# tools.func 内部调用:
msg_info "安装 Node.js"      # 使用 core.func
setup_nodejs "20"            # 执行设置
msg_ok "Node.js 已安装"      # 使用 core.func
```

### 与 error_handler.func 的集成

**tools.func 使用 error_handler.func 提供的**:
- 退出码映射到错误描述
- 自动错误捕获 (catch_errors)
- 信号处理器 (SIGINT, SIGTERM, EXIT)
- 结构化错误报告

**示例**:
```bash
# 如果 setup_nodejs 失败，error_handler 会捕获它:
catch_errors    # 从 error_handler.func 调用
setup_nodejs "20"  # 如果这里返回非零值
                   # error_handler 会记录并捕获它
```

### 与 install.func 的集成

**tools.func 与 install.func 协调完成**:
- 初始 OS 更新 (install.func) → 然后工具安装 (tools.func)
- 工具安装前的网络验证
- 包管理器状态验证
- 工具设置后的清理程序

**执行序列**:
```bash
setting_up_container()      # 来自 install.func
network_check()             # 来自 install.func
update_os()                 # 来自 install.func

pkg_update                  # 来自 tools.func
setup_nodejs()              # 来自 tools.func

motd_ssh()                  # 来自 install.func
customize()                 # 来自 install.func
cleanup_lxc()               # 来自 install.func
```

---

## 与 alpine-tools.func 的集成 (Alpine 容器)

### 何时使用 tools.func vs alpine-tools.func

| 功能 | tools.func (Debian) | alpine-tools.func (Alpine) |
|---------|:---:|:---:|
| 包管理器 | apt-get | apk |
| 安装脚本 | install/*.sh | install/*-alpine.sh |
| 工具设置 | `setup_nodejs()` (apt) | `setup_nodejs()` (apk) |
| 仓库 | `setup_deb822_repo()` | `add_community_repo()` |
| 服务 | systemctl | rc-service |

### 自动选择

安装脚本会检测操作系统并引入相应的函数:

```bash
# install/myapp-install.sh
if grep -qi 'alpine' /etc/os-release; then
  # 检测到 Alpine - 使用 alpine-tools.func
  apk_update
  apk_add package
else
  # 检测到 Debian - 使用 tools.func
  pkg_update
  pkg_install package
fi
```

---

## 依赖管理

### 外部依赖

```
tools.func 需要:
├─ curl          (用于 HTTP 请求、GPG 密钥)
├─ wget          (用于下载)
├─ apt-get       (包管理器)
├─ gpg           (GPG 密钥管理)
├─ openssl       (用于加密)
└─ systemctl     (Debian 上的服务管理)
```

### 内部函数依赖

```
setup_nodejs()
    ├─ 调用: setup_deb822_repo()
    ├─ 调用: pkg_update()
    ├─ 调用: pkg_install()
    └─ 使用: msg_info(), msg_ok() [来自 core.func]

setup_mariadb()
    ├─ 调用: setup_deb822_repo()
    ├─ 调用: pkg_update()
    ├─ 调用: pkg_install()
    └─ 使用: msg_info(), msg_ok()

setup_docker()
    ├─ 调用: cleanup_repo_metadata()
    ├─ 调用: setup_deb822_repo()
    ├─ 调用: pkg_update()
    └─ 使用: msg_info(), msg_ok()
```

---

## 函数调用图

### 完整的安装依赖树

```
install/app-install.sh
    │
    ├─ setting_up_container()         [install.func]
    │
    ├─ network_check()                [install.func]
    │
    ├─ update_os()                    [install.func]
    │
    ├─ pkg_update()                   [tools.func]
    │   └─ 调用: apt-get update (带重试)
    │
    ├─ setup_nodejs("20")             [tools.func]
    │   ├─ setup_deb822_repo()        [tools.func]
    │   │   └─ 调用: apt-get update
    │   ├─ pkg_update()               [tools.func]
    │   └─ pkg_install()              [tools.func]
    │
    ├─ setup_php("8.3")               [tools.func]
    │   └─ 类似 setup_nodejs
    │
    ├─ setup_mariadb("11")            [tools.func]
    │   └─ 类似 setup_nodejs
    │
    ├─ motd_ssh()                     [install.func]
    │
    ├─ customize()                    [install.func]
    │
    └─ cleanup_lxc()                  [install.func]
```

---

## 配置管理

### tools.func 使用的环境变量

```bash
# 输出控制
STD="silent"              # 抑制 apt/apk 输出
VERBOSE="yes"             # 显示所有输出

# 包管理
DEBIAN_FRONTEND="noninteractive"

# 工具版本 (可选)
NODEJS_VERSION="20"
PHP_VERSION="8.3"
POSTGRES_VERSION="16"
```

### 创建的工具配置文件

```
/opt/
├─ nodejs_version.txt       # Node.js 版本
├─ php_version.txt          # PHP 版本
├─ mariadb_version.txt      # MariaDB 版本
├─ postgresql_version.txt   # PostgreSQL 版本
├─ docker_version.txt       # Docker 版本
└─ [TOOL]_version.txt       # 所有已安装工具的版本

/etc/apt/sources.list.d/
├─ nodejs.sources           # Node.js 仓库 (deb822)
├─ docker.sources           # Docker 仓库 (deb822)
└─ [name].sources           # 其他仓库 (deb822)
```

---

## 错误处理集成

### tools.func 的退出码

| 代码 | 含义 | 处理方 |
|------|:---:|:---:|
| 0 | 成功 | 正常流程 |
| 1 | 包安装失败 | error_handler.func |
| 100-101 | APT 错误 | error_handler.func |
| 127 | 命令未找到 | error_handler.func |

### 失败时的自动清理

```bash
# 如果安装脚本中的任何步骤失败:
catch_errors
pkg_update        # 在这里失败?
setup_nodejs      # 不会执行到这里

# error_handler 自动:
├─ 记录错误
├─ 捕获退出码
├─ 调用 cleanup_lxc()
└─ 以适当的代码退出
```

---

## 与 build.func 的集成

### 变量流

```
ct/app.sh
    │
    ├─ var_cpu="2"
    ├─ var_ram="2048"
    ├─ var_disk="10"
    │
    └─ 调用: build_container()     [build.func]
              │
              └─ 创建容器
                 │
                 └─ 调用: install/app-install.sh
                    │
                    └─ 使用: tools.func 进行安装
```

### 资源考虑

tools.func 遵守容器资源限制:
- 大型包安装遵守分配的 RAM
- 数据库设置使用分配的磁盘空间
- 构建工具 (gcc, make) 保持在 CPU 分配范围内

---

## 版本管理

### tools.func 如何跟踪版本

每个工具安装都会创建一个版本文件:

```bash
# setup_nodejs() 创建:
echo "20.10.5" > /opt/nodejs_version.txt

# 更新脚本使用:
CURRENT=$(cat /opt/nodejs_version.txt)
LATEST=$(curl ... # 获取最新版本)
if [[ "$LATEST" != "$CURRENT" ]]; then
  # 需要更新
fi
```

### 与更新函数的集成

```bash
# 在 ct/app.sh 中:
function update_script() {
  # 检查 Node 版本
  RELEASE=$(curl ... | jq '.version')
  CURRENT=$(cat /opt/nodejs_version.txt)

  if [[ "$RELEASE" != "$CURRENT" ]]; then
    # 使用 tools.func 升级
    setup_nodejs "$RELEASE"
  fi
}
```

---

## 集成最佳实践

### ✅ 应该做的

1. **按正确顺序调用函数**
   ```bash
   pkg_update
   setup_tool "version"
   ```

2. **在生产环境使用 $STD**
   ```bash
   export STD="silent"
   pkg_install curl wget
   ```

3. **检查现有安装**
   ```bash
   command -v nodejs >/dev/null || setup_nodejs "20"
   ```

4. **与 install.func 协调**
   ```bash
   setting_up_container
   update_os                    # 来自 install.func
   setup_nodejs                 # 来自 tools.func
   motd_ssh                     # 回到 install.func
   ```

### ❌ 不应该做的

1. **不要跳过 pkg_update**
   ```bash
   # 错误 - 可能因缓存过期而失败
   pkg_install curl
   ```

2. **不要硬编码版本**
   ```bash
   # 错误
   apt-get install nodejs=20.x

   # 正确
   setup_nodejs "20"
   ```

3. **不要混用包管理器**
   ```bash
   # 错误
   apt-get install curl
   apk add wget
   ```

4. **不要忽略错误**
   ```bash
   # 错误
   setup_docker || true

   # 正确
   if ! setup_docker; then
     msg_error "Docker 失败"
     exit 1
   fi
   ```

---

## 集成问题排查

### "包安装失败"
- 检查: 是否先调用了 `pkg_update`
- 检查: 包名对于操作系统是否正确
- 解决方案: 在容器中手动验证

### "安装后无法访问工具"
- 检查: 工具是否已添加到 PATH
- 检查: 版本文件是否已创建
- 解决方案: 使用 `which toolname` 验证

### "仓库冲突"
- 检查: 没有重复的仓库
- 解决方案: 添加前先执行 `cleanup_repo_metadata()`

### "在 Debian 工具上出现 Alpine 特定错误"
- 问题: 在 Alpine 上使用 tools.func 函数
- 解决方案: 改用 alpine-tools.func

---

**最后更新**: 2025年12月
**维护者**: community-scripts 团队
**集成状态**: 所有组件已完全集成
