# JSON 元数据文件 - 快速参考

元数据文件（`frontend/public/json/myapp.json`）告诉 Web 界面如何显示您的应用程序。

---

## 快速开始

**使用 JSON 生成器工具：**
[https://community-scripts.github.io/ProxmoxVE/json-editor](https://community-scripts.github.io/ProxmoxVE/json-editor)

1. 输入应用程序详细信息
2. 生成器创建 `frontend/public/json/myapp.json`
3. 将输出复制到您的贡献中

---

## 文件结构

```json
{
  "name": "MyApp",
  "slug": "myapp",
  "categories": [1],
  "date_created": "2026-01-18",
  "type": "ct",
  "updateable": true,
  "privileged": false,
  "interface_port": 3000,
  "documentation": "https://docs.example.com/",
  "website": "https://example.com/",
  "logo": "https://cdn.jsdelivr.net/gh/selfhst/icons@main/webp/myapp.webp",
  "config_path": "/opt/myapp/.env",
  "description": "MyApp 功能的简要描述",
  "install_methods": [
    {
      "type": "default",
      "script": "ct/myapp.sh",
      "resources": {
        "cpu": 2,
        "ram": 2048,
        "hdd": 8,
        "os": "Debian",
        "version": "13"
      }
    }
  ],
  "default_credentials": {
    "username": null,
    "password": null
  },
  "notes": [
    {
      "text": "首次登录后更改默认密码！",
      "type": "warning"
    }
  ]
}
```

---

## 字段参考

| 字段 | 必需 | 示例 | 说明 |
| --------------------- | -------- | ----------------- | ---------------------------------------------- |
| `name` | 是 | "MyApp" | 显示名称 |
| `slug` | 是 | "myapp" | URL 友好标识符（小写，无空格） |
| `categories` | 是 | [1] | 一个或多个类别 ID |
| `date_created` | 是 | "2026-01-18" | 格式：YYYY-MM-DD |
| `type` | 是 | "ct" | 容器类型："ct" 或 "vm" |
| `interface_port` | 是 | 3000 | 默认 Web 界面端口 |
| `logo` | 否 | "https://..." | Logo URL（64px x 64px PNG） |
| `config_path` | 是 | "/opt/myapp/.env" | 主配置文件位置 |
| `description` | 是 | "应用描述" | 简要描述（100 字符） |
| `install_methods` | 是 | 见下文 | 安装资源（数组） |
| `default_credentials` | 否 | 见下文 | 可选的默认登录 |
| `notes` | 否 | 见下文 | 附加说明（数组） |

---

## 安装方法

每个安装方法指定资源要求：

```json
"install_methods": [
  {
    "type": "default",
    "script": "ct/myapp.sh",
    "resources": {
      "cpu": 2,
      "ram": 2048,
      "hdd": 8,
      "os": "Debian",
      "version": "13"
    }
  }
]
```

**资源默认值：**

- CPU：核心数（1-8）
- RAM：兆字节（256-4096）
- 磁盘：千兆字节（4-50）

---

## 常见类别

- `0` 杂项
- `1` Proxmox 和虚拟化
- `2` 操作系统
- `3` 容器和 Docker
- `4` 网络和防火墙
- `5` 广告拦截和 DNS
- `6` 身份验证和安全
- `7` 备份和恢复
- `8` 数据库
- `9` 监控和分析
- `10` 仪表板和前端
- `11` 文件和下载
- `12` 文档和笔记
- `13` 媒体和流媒体
- `14` \*Arr 套件
- `15` NVR 和摄像头
- `16` 物联网和智能家居
- `17` ZigBee、Z-Wave 和 Matter
- `18` MQTT 和消息传递
- `19` 自动化和调度
- `20` AI / 编码和开发工具
- `21` Web 服务器和代理
- `22` 机器人和 ChatOps
- `23` 财务和预算
- `24` 游戏和休闲
- `25` 商业和 ERP

---

## 最佳实践

1. **使用 JSON 生成器** - 它验证结构
2. **保持描述简短** - 最多 100 个字符
3. **使用真实的资源要求** - 基于您的测试
4. **包含合理的默认值** - 在 install_methods 中预填充
5. **Slug 必须小写** - 无空格，使用连字符

---

## 参考示例

查看仓库中的实际示例：

- [frontend/public/json/trip.json](https://github.com/jiege6-66/ProxmoxVE/blob/main/frontend/public/json/trip.json)
- [frontend/public/json/thingsboard.json](https://github.com/jiege6-66/ProxmoxVE/blob/main/frontend/public/json/thingsboard.json)
- [frontend/public/json/unifi.json](https://github.com/jiege6-66/ProxmoxVE/blob/main/frontend/public/json/unifi.json)

---

## 需要帮助？

- **[JSON 生成器](https://community-scripts.github.io/ProxmoxVE/json-editor)** - 交互式工具
- **[README.md](../README.md)** - 完整的贡献工作流
- **[快速开始](../README.md)** - 分步指南
