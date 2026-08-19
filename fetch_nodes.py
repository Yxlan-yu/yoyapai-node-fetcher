#!/usr/bin/env python3
"""
🚀 yoyapai.com 每日免费节点提取器 (Python 版)
适配 Termux (Android) / Linux / macOS / Windows
"""

import re
import os
import sys
import urllib.request
import urllib.error
from datetime import datetime

# --- 配置 ---
CATEGORY_URL = "https://yoyapai.com/category/mianfeijiedian"
OUTPUT_DIR = os.path.join(os.path.expanduser("~"), "yoyapai-nodes")

# --- 颜色 (Termux/Linux/macOS) ---
if sys.platform != "win32":
    CYAN = "\033[0;36m"
    GREEN = "\033[0;32m"
    YELLOW = "\033[1;33m"
    RED = "\033[0;31m"
    NC = "\033[0m"
else:
    CYAN = GREEN = YELLOW = RED = NC = ""


def info(msg): print(f"{CYAN}[INFO]{NC} {msg}")
def ok(msg):   print(f"{GREEN}[OK]{NC} {msg}")
def warn(msg): print(f"{YELLOW}[WARN]{NC} {msg}")
def fail(msg): print(f"{RED}[FAIL]{NC} {msg}"); sys.exit(1)


def fetch(url: str, timeout: int = 30) -> str:
    """获取网页内容"""
    req = urllib.request.Request(url, headers={
        "User-Agent": "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 "
                       "(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
    })
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.read().decode("utf-8", errors="replace")
    except urllib.error.URLError as e:
        fail(f"网络请求失败: {e}")


def extract_latest_url(html: str) -> str:
    """从分类页提取最新文章链接"""
    urls = re.findall(r'https://yoyapai\.com/\d+', html)
    return urls[0] if urls else ""


def extract_article_info(html: str) -> dict:
    """从文章页提取节点信息"""
    info = {}

    # 订阅链接 (处理 &#47; 等 HTML 实体)
    decoded = html.replace("&#47;", "/").replace("&amp;", "&").replace("&lt;", "<").replace("&gt;", ">")
    clash = re.findall(r'https://freenode\.yoyapai\.com/[^"<>\s]+\.yaml', decoded)
    v2ray = re.findall(r'https://freenode\.yoyapai\.com/[^"<>\s]+\.txt', decoded)
    info["clash_url"] = clash[0] if clash else ""
    info["v2ray_url"] = v2ray[0] if v2ray else ""

    # 文章日期
    date_match = re.search(r'(\d{4}年\d{1,2}月\d{1,2}日)', html)
    info["date"] = date_match.group(1) if date_match else datetime.now().strftime("%Y-%m-%d")

    # 节点数量
    count_match = re.search(r'更新数量[：:]\s*(\d+)', html)
    info["node_count"] = count_match.group(1) if count_match else "未知"

    # 实测速度
    speed_match = re.search(r'实测速度[：:]\s*([\d.]+MB/s)', html)
    info["speed"] = speed_match.group(1) if speed_match else "未知"

    return info


def main():
    today = datetime.now().strftime("%Y-%m-%d")
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    output_file = os.path.join(OUTPUT_DIR, f"{today}.txt")

    # Step 1: 获取分类页
    info("正在获取今日最新文章...")
    category_html = fetch(CATEGORY_URL)
    latest_url = extract_latest_url(category_html)
    if not latest_url:
        fail("无法获取最新文章链接，请检查网络")
    ok(f"最新文章: {latest_url}")

    # Step 2: 获取文章页
    info("正在提取节点订阅链接...")
    article_html = fetch(latest_url)
    article = extract_article_info(article_html)

    # Step 3: 显示结果
    print()
    print("━" * 44)
    print(f"  📅 {article['date']} 免费节点")
    print(f"  📊 {article['node_count']} 个节点 | {article['speed']}")
    print("━" * 44)

    # Step 4: 写入文件
    lines = [
        "# yoyapai.com 每日免费节点",
        f"# 日期: {article['date']}",
        f"# 节点数: {article['node_count']}",
        f"# 实测速度: {article['speed']}",
        f"# 来源: {latest_url}",
        f"# 提取时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        "",
        "━" * 44,
        "",
    ]

    if article["clash_url"]:
        ok(f"Clash 订阅: {article['clash_url']}")
        lines += ["[Clash / Clash Meta / Mihomo 订阅]", article["clash_url"], ""]
    else:
        warn("未找到 Clash 订阅链接")

    if article["v2ray_url"]:
        ok(f"V2Ray 订阅: {article['v2ray_url']}")
        lines += ["[V2Ray / V2RayN / V2RayNG 订阅]", article["v2ray_url"], ""]
    else:
        warn("未找到 V2Ray 订阅链接")

    # 下载订阅内容
    lines += ["━" * 44, ""]

    if article["clash_url"]:
        info("正在下载 Clash 配置...")
        clash_content = fetch(article["clash_url"])
        lines += ["[Clash 配置文件内容]", clash_content, ""]
        ok(f"Clash 配置: {len(clash_content.splitlines())} 行")

    if article["v2ray_url"]:
        info("正在下载 V2Ray 配置...")
        v2ray_content = fetch(article["v2ray_url"])
        lines += ["[V2Ray 节点列表]", v2ray_content, ""]
        ok(f"V2Ray 节点: {len(v2ray_content.splitlines())} 条")

    with open(output_file, "w", encoding="utf-8") as f:
        f.write("\n".join(lines))

    # 生成快捷链接文件
    if article["clash_url"]:
        with open(os.path.join(OUTPUT_DIR, "clash-latest.txt"), "w") as f:
            f.write(article["clash_url"])
    if article["v2ray_url"]:
        with open(os.path.join(OUTPUT_DIR, "v2ray-latest.txt"), "w") as f:
            f.write(article["v2ray_url"])

    print()
    print("━" * 44)
    ok(f"全部完成！文件保存到: {output_file}")
    print()
    print("📋 快速导入方式:")
    if article["clash_url"]:
        print(f"  Clash:  复制 yaml 链接到 Clash → 配置 → 粘贴URL")
    if article["v2ray_url"]:
        print(f"  V2Ray:  复制 txt 链接到 V2RayN → 订阅 → 粘贴URL")
    print()
    print("🔗 最新订阅链接:")
    if article["clash_url"]:
        print(f"  Clash:  {article['clash_url']}")
    if article["v2ray_url"]:
        print(f"  V2Ray:  {article['v2ray_url']}")
    print("━" * 44)


if __name__ == "__main__":
    main()
