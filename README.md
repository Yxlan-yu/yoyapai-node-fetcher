# 🚀 每日免费节点自动抓取

自动从 [yoyapai.com](https://yoyapai.com/category/mianfeijiedian) 抓取每日免费 V2Ray/Clash 节点，部署到 GitHub Pages。

**页面地址**: https://yxlan-yu.github.io/yoyapai-node-fetcher/

## ✨ 功能

- 📅 每天北京时间 8:00 后自动更新
- 📦 自托管订阅链接（GitHub Pages）
- ⬇️ 支持下载 V2Ray/Clash 配置文件
- 📋 一键复制订阅链接
- 🔄 请求失败自动重试 5 次（带浏览器 UA 伪装）
- ✅ 节点数校验（< 50 条自动中止，防止异常数据）
- 💾 抓取失败保留前一天数据（不白屏）
- ⚠️ 失败时自动创建 Issue 告警（GitHub 邮件通知）
- ✅ 恢复后自动关闭告警 Issue

## 📱 使用方式

### FlClash
复制 Clash 链接 → 配置 → 粘贴 → 确定

### V2RayNG
复制 V2Ray 链接 → 右上角+ → 从剪切板导入 → 右上角三竖点 → 更新订阅

## 🔗 订阅地址

| 类型 | 链接 |
|------|------|
| Clash / Mihomo | `https://yxlan-yu.github.io/yoyapai-node-fetcher/clash-config.yaml` |
| V2Ray / V2RayNG | `https://yxlan-yu.github.io/yoyapai-node-fetcher/v2ray-nodes.txt` |

## 📂 项目结构

```
├── .github/workflows/fetch-nodes.yml  # GitHub Actions 自动抓取
├── fetch_nodes.py                      # Python 版抓取脚本（本地使用）
├── fetch_nodes.sh                      # Shell 版抓取脚本（Termux/Linux）
└── worker.js                           # Cloudflare Worker 版（备用）
```

## ⚠️ 注意

- 免费节点多人共享，高峰时段可能较慢
- 节点来源于第三方，仅供学习研究使用
- 如需稳定高速，建议使用付费机场

