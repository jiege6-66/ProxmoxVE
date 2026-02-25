<div align="center">
  <img src="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/images/logo-81x112.png" height="120px" alt="Proxmox VE Helper-Scripts Logo" />
  
  <h1>Proxmox VE Helper-Scripts</h1>
  <p><em>纪念 @tteck 的社区传承</em></p>

  <p>
    <a href="https://helper-scripts.com">
      <img src="https://img.shields.io/badge/🌐_Website-Visit-4c9b3f?style=for-the-badge&labelColor=2d3748" alt="Website" />
    </a>
    <a href="https://discord.gg/3AnUqsXnmK">
      <img src="https://img.shields.io/badge/💬_Discord-Join-7289da?style=for-the-badge&labelColor=2d3748" alt="Discord" />
    </a>
    <a href="https://ko-fi.com/community_scripts">
      <img src="https://img.shields.io/badge/❤️_Support-Donate-FF5F5F?style=for-the-badge&labelColor=2d3748" alt="Donate" />
    </a>
  </p>

  <p>
    <a href="https://github.com/community-scripts/ProxmoxVE/blob/main/docs/contribution/README.md">
      <img src="https://img.shields.io/badge/🤝_Contribute-Guidelines-ff4785?style=for-the-badge&labelColor=2d3748" alt="Contribute" />
    </a>
    <a href="https://github.com/community-scripts/ProxmoxVE/blob/main/docs/contribution/USER_SUBMITTED_GUIDES.md">
      <img src="https://img.shields.io/badge/📚_Guides-Read-0077b5?style=for-the-badge&labelColor=2d3748" alt="Guides" />
    </a>
    <a href="https://github.com/community-scripts/ProxmoxVE/blob/main/CHANGELOG.md">
      <img src="https://img.shields.io/badge/📋_Changelog-View-6c5ce7?style=for-the-badge&labelColor=2d3748" alt="Changelog" />
    </a>
  </p>

  <br />

 **使用社区驱动的自动化脚本简化您的 Proxmox VE 设置**  
 最初由 tteck 创建，现由社区维护和扩展

</div>

<br />

<div align="center">
  <sub>🙌 <strong>特别感谢</strong></sub>
  <br />
  <br />
  <a href="https://selfh.st/">
    <img src="https://img.shields.io/badge/selfh.st-Icons_for_Self--Hosted-2563eb?style=for-the-badge&logo=data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48cGF0aCBkPSJNMTIgMkM2LjQ4IDIgMiA2LjQ4IDIgMTJzNC40OCAxMCAxMCAxMCAxMC00LjQ4IDEwLTEwUzE3LjUyIDIgMTIgMnptMCAxOGMtNC40MSAwLTgtMy41OS04LThzMy41OS04IDgtOCA4IDMuNTkgOCA4LTMuNTkgOC04IDh6IiBmaWxsPSJ3aGl0ZSIvPjwvc3ZnPg==&labelColor=1e3a8a" alt="selfh.st Icons" />
  </a>
  <br />
  <sub><a href="https://github.com/selfhst/icons">在 GitHub 上查看</a> • 为 5000+ 个自托管应用提供一致、美观的图标</sub>
</div>

---

## 🎯 主要特性

<div align="center">

<table>
  <tr>
    <td align="center" width="25%">
      <h3>⚡ 快速设置</h3>
      <p>一键安装流行的服务和容器</p>
    </td>
    <td align="center" width="25%">
      <h3>⚙️ 灵活配置</h3>
      <p>为初学者提供简单模式，为高级用户提供高级选项</p>
    </td>
    <td align="center" width="25%">
      <h3>🔄 自动更新</h3>
      <p>通过内置更新机制保持安装最新</p>
    </td>
    <td align="center" width="25%">
      <h3>🛠️ 轻松管理</h3>
      <p>用于配置和故障排除的安装后脚本</p>
    </td>
  </tr>
  <tr>
    <td align="center" width="25%">
      <h3>👥 社区驱动</h3>
      <p>由来自世界各地的用户积极维护和贡献</p>
    </td>
    <td align="center" width="25%">
      <h3>📖 文档完善</h3>
      <p>全面的指南和社区支持</p>
    </td>
    <td align="center" width="25%">
      <h3>🔒 安全</h3>
      <p>定期安全更新和最佳实践</p>
    </td>
    <td align="center" width="25%">
      <h3>⚡ 性能</h3>
      <p>优化配置以获得最佳性能</p>
    </td>
  </tr>
</table>

</div>

---

## 📋 系统要求

<div align="center">

<table>
  <tr>
    <td align="center" width="33%">
      <h3>🖥️ Proxmox VE</h3>
      <p>版本：8.4.x | 9.0.x | 9.1.x</p>
    </td>
    <td align="center" width="33%">
      <h3>🐧 操作系统</h3>
      <p>基于 Debian 并带有 Proxmox Tools</p>
    </td>
    <td align="center" width="33%">
      <h3>🌐 网络</h3>
      <p>需要互联网连接</p>
    </td>
  </tr>
</table>

</div>

---

## 📥 快速开始

选择您喜欢的安装方法：

### 方法 1：一键网页安装器

最快的入门方式：

1. 访问 **[helper-scripts.com](https://helper-scripts.com/)** 🌐
2. 搜索您想要的脚本（例如 "Home Assistant"、"Docker"）
3. 复制脚本页面上显示的 bash 命令
4. 打开您的 **Proxmox Shell** 并粘贴命令
5. 按 Enter 键并按照交互式提示操作

### 方法 2：PVEScripts-Local

直接在您的 Proxmox UI 中安装便捷的脚本管理器：

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/ct/pve-scripts-local.sh)"
```

这会在您的 Proxmox 界面中添加一个菜单，方便访问脚本而无需访问网站。

📖 **了解更多：** [ProxmoxVE-Local Repository](https://github.com/community-scripts/ProxmoxVE-Local)

---

## 💬 加入社区

<div align="center">

<table>
  <tr>
    <td align="center" width="33%">
      <h3>💬 Discord</h3>
      <p>实时聊天、支持和讨论</p>
      <a href="https://discord.gg/3AnUqsXnmK">
        <img src="https://img.shields.io/badge/Join-7289da?style=for-the-badge&logo=discord&logoColor=white" alt="Discord" />
      </a>
    </td>
    <td align="center" width="33%">
      <h3>💭 讨论区</h3>
      <p>功能请求、问答和想法</p>
      <a href="https://github.com/community-scripts/ProxmoxVE/discussions">
        <img src="https://img.shields.io/badge/Discuss-238636?style=for-the-badge&logo=github&logoColor=white" alt="Discussions" />
      </a>
    </td>
    <td align="center" width="33%">
      <h3>🐛 问题反馈</h3>
      <p>错误报告和问题跟踪</p>
      <a href="https://github.com/community-scripts/ProxmoxVE/issues">
        <img src="https://img.shields.io/badge/Report-d73a4a?style=for-the-badge&logo=github&logoColor=white" alt="Issues" />
      </a>
    </td>
  </tr>
</table>

</div>

---

## 🛠️ 贡献

<div align="center">

<table>
  <tr>
    <td align="center" width="25%">
      <h3>💻 代码</h3>
      <p>添加新脚本或改进现有脚本</p>
    </td>
    <td align="center" width="25%">
      <h3>📝 文档</h3>
      <p>编写指南、改进 README、翻译内容</p>
    </td>
    <td align="center" width="25%">
      <h3>🧪 测试</h3>
      <p>测试脚本并报告兼容性问题</p>
    </td>
    <td align="center" width="25%">
      <h3>💡 想法</h3>
      <p>建议功能或工作流程改进</p>
    </td>
  </tr>
</table>

</div>

<div align="center">
  <br />
  
  👉 查看我们的 **[贡献指南](https://github.com/community-scripts/ProxmoxVE/blob/main/docs/contribution/README.md)** 开始贡献
  
</div>

---

## ❤️ 支持项目

该项目由志愿者维护，以纪念 tteck。您的支持帮助我们维护基础设施、改进文档，并回馈重要事业。

**🎗️ 所有捐款的 30% 将直接用于癌症研究和临终关怀**

<div align="center">

<a href="https://ko-fi.com/community_scripts">
  <img src="https://img.shields.io/badge/☕_Buy_us_a_coffee-Support_on_Ko--fi-FF5F5F?style=for-the-badge&labelColor=2d3748" alt="Support on Ko-fi" />
</a>

<br />
<sub>每一份贡献都有助于保持这个项目的活力并支持有意义的事业</sub>

</div>

---

## 📈 项目统计
<p align="center">
  <img
    src="https://repobeats.axiom.co/api/embed/57edde03e00f88d739bdb5b844ff7d07dd079375.svg"
    alt="Repobeats analytics"
    width="650"
  />
</p>

<p align="center">
  <a href="https://star-history.com/#community-scripts/ProxmoxVE&Date">
    <picture>
      <source
        media="(prefers-color-scheme: dark)"
        srcset="https://api.star-history.com/svg?repos=community-scripts/ProxmoxVE&type=Date&theme=dark"
      />
      <source
        media="(prefers-color-scheme: light)"
        srcset="https://api.star-history.com/svg?repos=community-scripts/ProxmoxVE&type=Date"
      />
      <img
        alt="Star History Chart"
        src="https://api.star-history.com/svg?repos=community-scripts/ProxmoxVE&type=Date"
        width="650"
      />
    </picture>
  </a>
</p>

---

## 📜 许可证

本项目采用 **[MIT License](LICENSE)** 许可 - 可自由使用、修改和分发。

---

<div align="center">
  <sub>由 Proxmox 社区用 ❤️ 制作，以纪念 tteck</sub>
  <br />
  <sub><i>Proxmox® 是 <a href="https://www.proxmox.com/en/about/company">Proxmox Server Solutions GmbH</a> 的注册商标</i></sub>
</div>
