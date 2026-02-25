# API 集成文档 (/api)

本目录包含 `/api` 目录的 API 集成和综合文档。

## 概述

`/api` 目录包含 Proxmox Community Scripts API 后端，用于诊断报告、遥测和分析集成。

## 关键组件

### 主 API 服务
位于 `/api/main.go`：
- 用于接收遥测数据的 RESTful API
- 安装统计跟踪
- 错误报告和分析
- 性能监控

### 与脚本的集成
API 通过 `api.func` 集成到所有安装脚本中：
- 发送安装开始/完成事件
- 报告错误和退出代码
- 收集匿名使用统计
- 启用项目分析

## 文档结构

API 文档涵盖：
- API 端点规范
- 集成方法
- 数据格式和架构
- 错误处理
- 隐私和数据处理

## 关键资源

- **[misc/api.func/](../misc/api.func/)** - API 函数库文档
- **[misc/api.func/README.md](../misc/api.func/README.md)** - 快速参考
- **[misc/api.func/API_FUNCTIONS_REFERENCE.md](../misc/api.func/API_FUNCTIONS_REFERENCE.md)** - 完整函数参考

## API 函数

`api.func` 库提供：

### `post_to_api()`
将容器安装数据发送到 API。

**用法**：
```bash
post_to_api CTID STATUS APP_NAME
```

### `post_update_to_api()`
报告应用程序更新状态。

**用法**：
```bash
post_update_to_api CTID APP_NAME VERSION
```

### `get_error_description()`
从退出代码获取人类可读的错误描述。

**用法**：
```bash
ERROR_DESC=$(get_error_description EXIT_CODE)
```

## API 集成点

### 在容器创建中（`ct/AppName.sh`）
- 由 build.func 调用以报告容器创建
- 发送初始容器设置数据
- 报告成功或失败

### 在安装脚本中（`install/appname-install.sh`）
- 在安装开始时调用
- 在安装完成时调用
- 在错误条件下调用

### 收集的数据
- 容器/VM ID
- 应用程序名称和版本
- 安装持续时间
- 成功/失败状态
- 错误代码（如果失败）
- 匿名使用指标

## 隐私

所有 API 数据：
- ✅ 匿名（无个人数据）
- ✅ 聚合用于统计
- ✅ 仅用于项目改进
- ✅ 不跟踪用户身份
- ✅ 如需要可以禁用

## API 架构

```
安装脚本
    │
    ├─ 调用：api.func 函数
    │
    └─ POST 到：https://api.community-scripts.org
                │
                ├─ 接收数据
                ├─ 验证格式
                ├─ 存储指标
                └─ 聚合统计
                    │
                    └─ 用于：
                       ├─ 下载跟踪
                       ├─ 错误趋势
                       ├─ 功能使用统计
                       └─ 项目健康监控
```

## 常见 API 任务

- **启用 API 报告** → 默认内置，无需配置
- **禁用 API** → 在运行前设置 `api_disable="yes"`
- **查看 API 数据** → 访问 https://community-scripts.org/stats
- **报告 API 错误** → [GitHub Issues](https://github.com/community-scripts/ProxmoxVE/issues)

## 调试 API 问题

如果 API 调用失败：
1. 检查互联网连接
2. 验证 API 端点可用性
3. 查看 [EXIT_CODES.md](../EXIT_CODES.md) 中的错误代码
4. 检查 API 函数日志
5. 在 GitHub 上报告问题

## API 端点

**基础 URL**：`https://api.community-scripts.org`

**端点**：
- `POST /install` - 报告容器安装
- `POST /update` - 报告应用程序更新
- `GET /stats` - 公共统计

---

**最后更新**：2025 年 12 月
**维护者**：community-scripts 团队
