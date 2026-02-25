# 技术参考：配置系统架构

> **面向开发者和高级用户**
>
> _深入了解默认值和配置系统的工作原理_

---

## 目录

1. [系统架构](#系统架构)
2. [文件格式规范](#文件格式规范)
3. [函数参考](#函数参考)
4. [变量优先级](#变量优先级)
5. [数据流图](#数据流图)
6. [安全模型](#安全模型)
7. [实现细节](#实现细节)

---

## 系统架构

### 组件概览

```
┌─────────────────────────────────────────────────────────────┐
│                    安装脚本                                   │
│  (pihole-install.sh, docker-install.sh, etc.)              │
└────────────────────┬────────────────────────────────────────┘
                     │
                     v
┌─────────────────────────────────────────────────────────────┐
│                   build.func 库                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  variables()                                         │   │
│  │  - 初始化 NSAPP, var_install 等                      │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  install_script()                                    │   │
│  │  - 显示模式菜单                                       │   │
│  │  - 路由到相应的工作流                                 │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  base_settings()                                     │   │
│  │  - 应用内置默认值                                     │   │
│  │  - 读取环境变量 (var_*)                              │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  load_vars_file()                                    │   │
│  │  - 安全文件解析（不使用 source/eval）                │   │
│  │  - 白名单验证                                         │   │
│  │  - 值清理                                            │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  default_var_settings()                              │   │
│  │  - 加载用户默认值                                     │   │
│  │  - 显示摘要                                          │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  maybe_offer_save_app_defaults()                     │   │
│  │  - 提供保存当前设置的选项                             │   │
│  │  - 处理更新与新保存                                   │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                     │
                     v
┌─────────────────────────────────────────────────────────────┐
│           配置文件（磁盘上）                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  /usr/local/community-scripts/default.vars          │   │
│  │  (用户全局默认值)                                     │   │
│  └──────────────────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────────────────┐   │
│  │  /usr/local/community-scripts/defaults/*.vars       │   │
│  │  (应用特定默认值)                                     │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 文件格式规范

### 用户默认值：`default.vars`

**位置**：`/usr/local/community-scripts/default.vars`

**MIME 类型**：`text/plain`

**编码**：UTF-8（无 BOM）

**格式规范**：

```
# 文件格式：简单的 key=value 对
# 用途：存储全局用户默认值
# 安全性：清理后的值，白名单验证

# 注释和空行会被忽略
# 行格式：var_name=value
# 等号周围不能有空格
# 字符串值不需要引号（但可以使用引号）

[内容]
var_cpu=4
var_ram=2048
var_disk=20
var_hostname=mydefault
var_brg=vmbr0
var_gateway=192.168.1.1
```

**形式化语法**：

```
FILE       := (BLANK_LINE | COMMENT_LINE | VAR_LINE)*
BLANK_LINE := \n
COMMENT_LINE := '#' [^\n]* \n
VAR_LINE   := VAR_NAME '=' VAR_VALUE \n
VAR_NAME   := 'var_' [a-z_]+
VAR_VALUE  := [^\n]*  # 除换行符外的任何可打印字符
```

**约束条件**：

| 约束条件      | 值                   |
| ------------- | -------------------- |
| 最大文件大小  | 64 KB                |
| 最大行长度    | 1024 字节            |
| 最大变量数    | 100                  |
| 允许的变量名  | `var_[a-z_]+`        |
| 值验证        | 白名单 + 清理        |

**有效文件示例**：

```bash
# 全局用户默认值
# 创建时间：2024-11-28

# 资源默认值
var_cpu=4
var_ram=2048
var_disk=20

# 网络默认值
var_brg=vmbr0
var_gateway=192.168.1.1
var_mtu=1500
var_vlan=100

# 系统默认值
var_timezone=Europe/Berlin
var_hostname=default-container

# 存储
var_container_storage=local
var_template_storage=local

# 安全
var_ssh=yes
var_protection=0
var_unprivileged=1
```

### 应用默认值：`<app>.vars`

**位置**：`/usr/local/community-scripts/defaults/<appname>.vars`

**格式**：与 `default.vars` 相同

**命名约定**：`<nsapp>.vars`

- `nsapp` = 小写应用名称，去除空格
- 示例：
  - `pihole` → `pihole.vars`
  - `opnsense` → `opnsense.vars`
  - `docker compose` → `dockercompose.vars`

**应用默认值示例**：

```bash
# PiHole (pihole) 的应用特定默认值
# 生成时间：2024-11-28T15:32:00Z
# 这些值在安装 pihole 时会覆盖用户默认值

var_unprivileged=1
var_cpu=2
var_ram=1024
var_disk=10
var_brg=vmbr0
var_net=veth
var_gateway=192.168.1.1
var_hostname=pihole
var_timezone=Europe/Berlin
var_container_storage=local
var_template_storage=local
var_tags=dns,pihole
```

---

## 函数参考

### `load_vars_file()`

**用途**：安全地从 .vars 文件加载变量，不使用 `source` 或 `eval`

**签名**：

```bash
load_vars_file(filepath)
```

**参数**：

| 参数     | 类型   | 必需 | 示例                                        |
| -------- | ------ | ---- | ------------------------------------------- |
| filepath | String | 是   | `/usr/local/community-scripts/default.vars` |

**返回值**：

- 成功时返回 `0`
- 错误时返回 `1`（文件缺失、解析错误等）

**环境副作用**：

- 将所有解析的 `var_*` 变量设置为 shell 变量
- 如果文件缺失，不会取消设置变量（安全）
- 不影响其他变量

**实现模式**：

```bash
load_vars_file() {
  local file="$1"

  # 文件必须存在
  [ -f "$file" ] || return 0

  # 逐行解析（不使用 source/eval）
  local line key val
  while IFS='=' read -r key val || [ -n "$key" ]; do
    # 跳过注释和空行
    [[ "$key" =~ ^[[:space:]]*# ]] && continue
    [[ -z "$key" ]] && continue

    # 验证键是否在白名单中
    _is_whitelisted_key "$key" || continue

    # 清理并导出值
    val="$(_sanitize_value "$val")"
    [ $? -eq 0 ] && export "$key=$val"
  done < "$file"

  return 0
}
```

**使用示例**：

```bash
# 加载用户默认值
load_vars_file "/usr/local/community-scripts/default.vars"

# 加载应用特定默认值
load_vars_file "$(get_app_defaults_path)"

# 检查是否成功
if load_vars_file "$vars_path"; then
  echo "设置加载成功"
else
  echo "加载设置失败"
fi

# 值现在可作为变量使用
echo "使用 $var_cpu 个核心"
echo "分配 ${var_ram} MB 内存"
```

---

### `get_app_defaults_path()`

**用途**：获取应用特定默认值文件的完整路径

**签名**：

```bash
get_app_defaults_path()
```

**参数**：无

**返回值**：

- String：应用默认值文件的完整路径

**实现**：

```bash
get_app_defaults_path() {
  local n="${NSAPP:-${APP,,}}"
  echo "/usr/local/community-scripts/defaults/${n}.vars"
}
```

**使用示例**：

```bash
# 获取应用默认值路径
app_defaults="$(get_app_defaults_path)"
echo "应用默认值位于：$app_defaults"

# 检查应用默认值是否存在
if [ -f "$(get_app_defaults_path)" ]; then
  echo "应用默认值可用"
fi

# 加载应用默认值
load_vars_file "$(get_app_defaults_path)"
```

---

### `default_var_settings()`

**用途**：加载并显示用户全局默认值

**签名**：

```bash
default_var_settings()
```

**参数**：无

**返回值**：

- 成功时返回 `0`
- 错误时返回 `1`

**工作流**：

```
1. 查找 default.vars 位置
   (通常是 /usr/local/community-scripts/default.vars)

2. 如果缺失则创建

3. 从文件加载变量

4. 映射 var_verbose → VERBOSE 变量

5. 调用 base_settings（应用到容器配置）

6. 调用 echo_default（显示摘要）
```

**实现模式**：

```bash
default_var_settings() {
  local VAR_WHITELIST=(
    var_apt_cacher var_apt_cacher_ip var_brg var_cpu var_disk var_fuse var_gpu
    var_gateway var_hostname var_ipv6_method var_mac var_mtu
    var_net var_ns var_pw var_ram var_tags var_tun var_unprivileged
    var_verbose var_vlan var_ssh var_ssh_authorized_key
    var_container_storage var_template_storage
  )

  # 确保文件存在
  _ensure_default_vars

  # 查找并加载
  local dv="$(_find_default_vars)"
  load_vars_file "$dv"

  # 映射详细标志
  if [[ -n "${var_verbose:-}" ]]; then
    case "${var_verbose,,}" in
      1 | yes | true | on) VERBOSE="yes" ;;
      *) VERBOSE="${var_verbose}" ;;
    esac
  fi

  # 应用并显示
  base_settings "$VERBOSE"
  echo_default
}
```

---

### `maybe_offer_save_app_defaults()`

**用途**：提供将当前设置保存为应用特定默认值的选项

**签名**：

```bash
maybe_offer_save_app_defaults()
```

**参数**：无

**返回值**：无（仅副作用）

**行为**：

1. 高级安装完成后
2. 向用户提供："保存为 <APP> 的应用默认值？"
3. 如果是：
   - 保存到 `/usr/local/community-scripts/defaults/<app>.vars`
   - 仅包含白名单变量
   - 备份之前的默认值（如果存在）
4. 如果否：
   - 不执行任何操作

**流程**：

```bash
maybe_offer_save_app_defaults() {
  local app_vars_path="$(get_app_defaults_path)"

  # 从内存构建当前设置
  local new_tmp="$(_build_current_app_vars_tmp)"

  # 检查是否已存在
  if [ -f "$app_vars_path" ]; then
    # 显示差异并询问：更新？保留？查看差异？
    _show_app_defaults_diff_menu "$new_tmp" "$app_vars_path"
  else
    # 新默认值 - 直接保存
    if whiptail --yesno "保存为 $APP 的应用默认值？" 10 60; then
      mv "$new_tmp" "$app_vars_path"
      chmod 644 "$app_vars_path"
    fi
  fi
}
```

---

### `_sanitize_value()`

**用途**：从配置值中移除危险字符/模式

**签名**：

```bash
_sanitize_value(value)
```

**参数**：

| 参数  | 类型   | 必需 |
| ----- | ------ | ---- |
| value | String | 是   |

**返回值**：

- `0`（成功）+ 在 stdout 输出清理后的值
- `1`（失败）+ 如果危险则不输出任何内容

**危险模式**：

| 模式      | 威胁             | 示例                 |
| --------- | ---------------- | -------------------- |
| `$(...)`  | 命令替换         | `$(rm -rf /)`        |
| `` ` ` `` | 命令替换         | `` `whoami` ``       |
| `;`       | 命令分隔符       | `value; rm -rf /`    |
| `&`       | 后台执行         | `value & malicious`  |
| `<(`      | 进程替换         | `<(cat /etc/passwd)` |

**实现**：

```bash
_sanitize_value() {
  case "$1" in
  *'$('* | *'`'* | *';'* | *'&'* | *'<('*)
    echo ""
    return 1  # 拒绝危险值
    ;;
  esac
  echo "$1"
  return 0
}
```

**使用示例**：

```bash
# 安全值
_sanitize_value "192.168.1.1"  # 返回：192.168.1.1（状态：0）

# 危险值
_sanitize_value "$(whoami)"     # 返回：（空）（状态：1）

# 代码中的使用
if val="$(_sanitize_value "$user_input")"; then
  export var_hostname="$val"
else
  msg_error "无效值：包含危险字符"
fi
```

---

### `_is_whitelisted_key()`

**用途**：检查变量名是否在允许的白名单中

**签名**：

```bash
_is_whitelisted_key(key)
```

**参数**：

| 参数 | 类型   | 必需 | 示例      |
| ---- | ------ | ---- | --------- |
| key  | String | 是   | `var_cpu` |

**返回值**：

- 如果键在白名单中返回 `0`
- 如果键不在白名单中返回 `1`

**实现**：

```bash
_is_whitelisted_key() {
  local k="$1"
  local w
  for w in "${VAR_WHITELIST[@]}"; do
    [ "$k" = "$w" ] && return 0
  done
  return 1
}
```

**使用示例**：

```bash
# 检查变量是否可以保存
if _is_whitelisted_key "var_cpu"; then
  echo "var_cpu 可以保存"
fi

# 拒绝未知变量
if ! _is_whitelisted_key "var_custom"; then
  msg_error "var_custom 不受支持"
fi
```

---

## 变量优先级

### 加载顺序

创建容器时，变量按以下顺序解析：

```
步骤 1：读取环境变量
   ├─ 检查 var_cpu 是否已在 shell 环境中设置
   ├─ 检查 var_ram 是否已设置
   └─ ...所有 var_* 变量

步骤 2：加载应用特定默认值
   ├─ 检查 /usr/local/community-scripts/defaults/pihole.vars 是否存在
   ├─ 从该文件加载所有 var_*
   └─ 这些会覆盖内置值，但不会覆盖环境变量

步骤 3：加载用户全局默认值
   ├─ 检查 /usr/local/community-scripts/default.vars 是否存在
   ├─ 从该文件加载所有 var_*
   └─ 这些会覆盖内置值，但不会覆盖应用特定值

步骤 4：使用内置默认值
   └─ 脚本中硬编码（最低优先级）
```

### 优先级示例

**示例 1：环境变量优先**

```bash
# Shell 环境具有最高优先级
$ export var_cpu=16
$ bash pihole-install.sh

# 结果：容器获得 16 个核心
# （忽略应用默认值、用户默认值、内置值）
```

**示例 2：应用默认值覆盖用户默认值**

```bash
# 用户默认值：var_cpu=4
# 应用默认值：var_cpu=2
$ bash pihole-install.sh

# 结果：容器获得 2 个核心
# （应用特定设置优先）
```

**示例 3：所有默认值缺失（使用内置值）**

```bash
# 未设置环境变量
# 无应用默认值文件
# 无用户默认值文件
$ bash pihole-install.sh

# 结果：使用内置默认值
# （var_cpu 默认可能是 2）
```

### 代码中的实现

```bash
# build.func 中的典型模式

base_settings() {
  # 优先级 1：环境变量（如果使用 export 则已设置）
  CT_TYPE=${var_unprivileged:-"1"}          # 使用现有值或默认值

  # 优先级 2：加载应用默认值（可能覆盖上述值）
  if [ -f "$(get_app_defaults_path)" ]; then
    load_vars_file "$(get_app_defaults_path)"
  fi

  # 优先级 3：加载用户默认值
  if [ -f "/usr/local/community-scripts/default.vars" ]; then
    load_vars_file "/usr/local/community-scripts/default.vars"
  fi

  # 优先级 4：应用内置默认值（最低）
  CORE_COUNT=${var_cpu:-"${APP_CPU_DEFAULT:-2}"}
  RAM_SIZE=${var_ram:-"${APP_RAM_DEFAULT:-1024}"}

  # 结果：var_cpu 已通过优先级链设置
}
```

---

## 数据流图

### 安装流程：高级设置

```
┌──────────────┐
│  启动脚本    │
└──────┬───────┘
       │
       v
┌──────────────────────────────┐
│ 显示安装模式菜单              │
│ （5 个选项）                  │
└──────┬───────────────────────┘
       │ 用户选择"高级设置"
       v
┌──────────────────────────────────┐
│ 调用：base_settings()            │
│ （应用内置默认值）                │
└──────┬───────────────────────────┘
       │
       v
┌──────────────────────────────────┐
│ 调用：advanced_settings()        │
│ （显示 19 步向导）                │
│ - 询问 CPU、RAM、磁盘、网络...    │
└──────┬───────────────────────────┘
       │
       v
┌──────────────────────────────────┐
│ 显示摘要                          │
│ 查看所有选择的值                  │
└──────┬───────────────────────────┘
       │ 用户确认
       v
┌──────────────────────────────────┐
│ 创建容器                          │
│ 使用当前变量值                    │
└──────┬───────────────────────────┘
       │
       v
┌──────────────────────────────────┐
│ 安装完成                          │
└──────┬───────────────────────────┘
       │
       v
┌──────────────────────────────────────┐
│ 提供：保存为应用默认值？              │
│ （保存当前设置）                      │
└──────┬───────────────────────────────┘
       │
       ├─ 是 → 保存到 defaults/<app>.vars
       │
       └─ 否 → 退出
```

### 变量解析流程

```
容器创建开始
         │
         v
   ┌─────────────────────┐
   │ 检查环境变量         │
   │ var_cpu, var_...    │
   └──────┬──────────────┘
          │ 找到？使用它们（优先级 1）
          │ 未找到？继续...
          v
   ┌──────────────────────────┐
   │ 加载应用默认值            │
   │ /defaults/<app>.vars     │
   └──────┬───────────────────┘
          │ 文件存在？解析并加载（优先级 2）
          │ 未找到？继续...
          v
   ┌──────────────────────────┐
   │ 加载用户默认值            │
   │ /default.vars            │
   └──────┬───────────────────┘
          │ 文件存在？解析并加载（优先级 3）
          │ 未找到？继续...
          v
   ┌──────────────────────────┐
   │ 使用内置默认值            │
   │ （硬编码值）              │
   └──────┬───────────────────┘
          │
          v
   ┌──────────────────────────┐
   │ 所有变量已解析            │
   │ 准备创建容器              │
   │                          │
   └──────────────────────────┘
```

---

## 安全模型

### 威胁模型

| 威胁                 | 缓解措施                                      |
| -------------------- | --------------------------------------------- |
| **任意代码执行**     | 不使用 `source` 或 `eval`；仅手动解析         |
| **变量注入**         | 允许的变量名白名单                            |
| **命令替换**         | `_sanitize_value()` 阻止 `$()`、反引号等      |
| **路径遍历**         | 文件锁定到 `/usr/local/community-scripts/`    |
| **权限提升**         | 使用受限权限创建文件                          |
| **信息泄露**         | 敏感变量不记录日志                            |

### 安全控制

#### 1. 输入验证

```bash
# 仅允许特定变量
if ! _is_whitelisted_key "$key"; then
  skip_this_variable
fi

# 值已清理
if ! val="$(_sanitize_value "$value")"; then
  reject_entire_line
fi
```

#### 2. 安全文件解析

```bash
# ❌ 危险（旧方式）
source /path/to/config.conf
# 可能执行：rm -rf / 或任何代码

# ✅ 安全（新方式）
load_vars_file "/path/to/config.conf"
# 仅读取 var_name=value 对，不执行
```

#### 3. 白名单

```bash
# 仅这些变量可以配置
var_cpu, var_ram, var_disk, var_brg, ...
var_hostname, var_pw, var_ssh, ...

# 不允许：
var_malicious, var_hack, custom_var, ...
```

#### 4. 值约束

```bash
# 无命令注入模式
if [[ "$value" =~ ($|`|;|&|<\() ]]; then
  reject_value
fi
```

---

## 实现细节

### 模块：`build.func`

**加载顺序**（在实际脚本中）：

1. `#!/usr/bin/env bash` - Shebang
2. `source /dev/stdin <<<$(curl ... api.func)` - API 函数
3. `source /dev/stdin <<<$(curl ... build.func)` - 构建函数
4. `variables()` - 初始化变量
5. `check_root()` - 安全检查
6. `install_script()` - 主流程

**关键部分**：

```bash
# 部分 1：初始化和变量
- variables()
- NSAPP, var_install, INTEGER 模式等

# 部分 2：存储管理
- storage_selector()
- ensure_storage_selection_for_vars_file()

# 部分 3：基础设置
- base_settings()          # 将默认值应用到所有 var_*
- echo_default()           # 显示当前设置

# 部分 4：变量加载
- load_vars_file()         # 安全解析
- _is_whitelisted_key()    # 验证
- _sanitize_value()        # 威胁缓解

# 部分 5：默认值管理
- default_var_settings()   # 加载用户默认值
- get_app_defaults_path()  # 获取应用默认值路径
- maybe_offer_save_app_defaults()  # 保存选项

# 部分 6：安装流程
- install_script()         # 主入口点
- advanced_settings()      # 20 步向导
```

### 使用的正则表达式模式

| 模式                   | 用途             | 匹配示例                |
| ---------------------- | ---------------- | ----------------------- |
| `^[0-9]+([.][0-9]+)?$` | 整数验证         | `4`, `192.168`          |
| `^var_[a-z_]+$`        | 变量名           | `var_cpu`, `var_ssh`    |
| `*'$('*`               | 命令替换         | `$(whoami)`             |
| `*\`\*`                | 反引号替换       | `` `cat /etc/passwd` `` |

---

## 附录：迁移参考

### 旧模式（已弃用）

```bash
# ❌ 旧方式：config-file.func
source config-file.conf          # 执行任意代码
if [ "$USE_DEFAULTS" = "yes" ]; then
  apply_settings_directly
fi
```

### 新模式（当前）

```bash
# ✅ 新方式：load_vars_file()
if load_vars_file "$(get_app_defaults_path)"; then
  echo "设置已安全加载"
fi
```

### 函数映射

| 旧方式           | 新方式                                | 位置       |
| ---------------- | ------------------------------------- | ---------- |
| `read_config()`  | `load_vars_file()`                    | build.func
