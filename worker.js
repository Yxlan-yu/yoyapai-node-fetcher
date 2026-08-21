// Cloudflare Worker - 每日节点代理
// 部署到 https://workers.cloudflare.com (免费)
// 每天访问你的 Worker URL 即可获取最新节点

export default {
  async fetch(request) {
    const CATEGORY_URL = "https://yoyapai.com/category/mianfeijiedian";

    try {
      // 获取分类页
      const catRes = await fetch(CATEGORY_URL, {
        headers: { "User-Agent": "Mozilla/5.0 (Linux; Android 14) Chrome/120" }
      });
      let catHtml = await catRes.text();
      catHtml = catHtml.replace(/&#47;/g, "/");

      // 提取最新文章链接
      const articleMatch = catHtml.match(/https:\/\/yoyapai\.com\/\d+/);
      if (!articleMatch) return new Response("无法获取文章链接", { status: 500 });

      // 获取文章页
      const artRes = await fetch(articleMatch[0], {
        headers: { "User-Agent": "Mozilla/5.0 (Linux; Android 14) Chrome/120" }
      });
      let html = await artRes.text();
      html = html.replace(/&#47;/g, "/").replace(/&amp;/g, "&");

      // 提取信息
      const clashMatch = html.match(/https:\/\/freenode\.yoyapai\.com\/[^"<>\s]+\.yaml/);
      const v2rayMatch = html.match(/https:\/\/freenode\.yoyapai\.com\/[^"<>\s]+\.txt/);
      const dateMatch = html.match(/(\d{4}年\d{1,2}月\d{1,2}日)/);
      const countMatch = html.match(/更新数量[：:](\d+)/);
      const speedMatch = html.match(/实测速度[：:]([\d.]+MB\/s)/);

      const page = `<!DOCTYPE html>
<html lang="zh"><head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>每日免费节点</title>
<style>
*{margin:0;padding:0;box-sizing:border-box}
body{font-family:-apple-system,sans-serif;background:#0d1117;color:#e6edf3;padding:16px}
.c{background:#161b22;border:1px solid #30363d;border-radius:12px;padding:20px;margin:12px 0}
h1{font-size:20px;margin-bottom:8px}
.d{color:#58a6ff;font-size:14px;margin-bottom:16px}
.i{display:flex;gap:12px;margin-bottom:16px;flex-wrap:wrap}
.i span{background:#21262d;padding:6px 12px;border-radius:8px;font-size:13px}
.l{color:#8b949e;font-size:13px;margin-bottom:6px}
.u{background:#0d1117;border:1px solid #30363d;border-radius:8px;padding:12px;font-size:13px;word-break:break-all;font-family:monospace;margin-bottom:8px}
.u a{color:#58a6ff;text-decoration:none}
.b{background:#238636;color:#fff;border:none;padding:10px 16px;border-radius:8px;font-size:14px;cursor:pointer;width:100%;margin:4px 0 12px}
.b:active{background:#2ea043}
.n{color:#8b949e;font-size:12px;line-height:1.8}
</style></head><body>
<div class="c">
<h1>🚀 每日免费节点</h1>
<div class="d">${dateMatch?.[1] || "今天"}</div>
<div class="i">
<span>📊 ${countMatch?.[1] || "?"} 条线路</span>
<span>⚡ ${speedMatch?.[1] || "未知"}</span>
</div>
<div class="label">Clash / Mihomo 订阅：</div>
<div class="u"><a id="c" href="${clashMatch?.[0] || "#"}">${clashMatch?.[0] || "未获取到"}</a></div>
<button class="b" onclick="cp('c')">📋 复制 Clash 链接</button>
<div class="l">V2Ray / V2RayNG 订阅：</div>
<div class="u"><a id="v" href="${v2rayMatch?.[0] || "#"}">${v2rayMatch?.[0] || "未获取到"}</a></div>
<button class="b" onclick="cp('v')">📋 复制 V2Ray 链接</button>
<div class="n">
⚠️ 免费节点多人共享，高峰可能较慢<br>
💡 <b>FlClash 导入：</b>复制 Clash 链接 → 配置 → 粘贴 → 确定<br>
💡 <b>V2RayNG 导入：</b>复制 V2Ray 链接 → 右上角+ → 订阅设置 → 粘贴 → 保存并更新<br>
🕐 每天北京时间 12:00 自动更新
</div></div>
<script>function cp(i){const t=document.getElementById(i).textContent;navigator.clipboard.writeText(t).then(()=>{const b=event.target;b.textContent='✅ 已复制！';setTimeout(()=>b.textContent='📋 复制 '+(i==='c'?'Clash':'V2Ray')+' 链接',2000)})}</script>
</body></html>`;

      return new Response(page, {
        headers: { "Content-Type": "text/html; charset=utf-8" }
      });
    } catch (e) {
      return new Response("错误: " + e.message, { status: 500 });
    }
  }
};
