#!/bin/bash
# ============================================================
# 🚀 每日免费节点提取脚本 - yoyapai.com
# 适配 Termux (Android) / Linux / macOS
# ============================================================

# --- 配置 ---
CATEGORY_URL="https://yoyapai.com/category/mianfeijiedian"
OUTPUT_DIR="${HOME}/yoyapai-nodes"
TODAY=$(date +%Y-%m-%d)
OUTPUT_FILE="${OUTPUT_DIR}/${TODAY}.txt"

# --- 颜色 ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info()  { echo -e "${CYAN}[INFO]${NC} $*"; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
fail()  { echo -e "${RED}[FAIL]${NC} $*"; exit 1; }

# --- 依赖检查 ---
for cmd in curl grep sed; do
    command -v "$cmd" &>/dev/null || fail "缺少依赖: $cmd  →  安装: pkg install curl"
done

# 检查网络
info "检查网络连接..."
if ! curl -sL --connect-timeout 10 --max-time 15 "https://yoyapai.com" > /dev/null 2>&1; then
    fail "无法访问 yoyapai.com，请检查网络
  可能原因:
  1. 手机没联网
  2. DNS 被污染 → 试试: termux-change-repo 换源
  3. 网站暂时不可用 → 稍后再试"
fi
ok "网络正常"

mkdir -p "$OUTPUT_DIR"

# --- Step 1: 获取分类页，提取最新文章链接 ---
info "正在获取最新文章列表..."
CATEGORY_HTML=$(curl -sL --connect-timeout 20 --max-time 45 "$CATEGORY_URL" 2>/dev/null)

if [[ -z "$CATEGORY_HTML" ]]; then
    fail "获取分类页失败，返回为空"
fi

# 还原 HTML 实体
CATEGORY_HTML=$(echo "$CATEGORY_HTML" | sed 's/&#47;/\//g')

LATEST_URL=$(echo "$CATEGORY_HTML" | grep -oP 'https://yoyapai\.com/\d+' | head -1)

if [[ -z "$LATEST_URL" ]]; then
    warn "正则未匹配，尝试备用方式..."
    LATEST_URL=$(echo "$CATEGORY_HTML" | grep -oE 'https://yoyapai\.com/[0-9]+' | head -1)
fi

if [[ -z "$LATEST_URL" ]]; then
    fail "无法提取最新文章链接
  可能原因: 网页结构已变化，需要更新脚本"
fi
ok "最新文章: $LATEST_URL"

# --- Step 2: 获取文章页面 ---
info "正在读取文章内容..."
PAGE=$(curl -sL --connect-timeout 20 --max-time 45 "$LATEST_URL" 2>/dev/null)

if [[ -z "$PAGE" ]]; then
    fail "获取文章页面失败"
fi

# 还原 HTML 实体 (&#47; -> / 等)
PAGE=$(echo "$PAGE" | sed 's/&#47;/\//g; s/&amp;/\&/g; s/&lt;/</g; s/&gt;/>/g')

info "正在解析订阅链接..."

# 提取文章发布日期
ARTICLE_DATE=$(echo "$PAGE" | grep -oE '[0-9]{4}年[0-9]{1,2}月[0-9]{1,2}日' | head -1)
info "文章日期: ${ARTICLE_DATE:-未知}"

# 提取 Clash 订阅链接 (yaml)
CLASH_URL=$(echo "$PAGE" | grep -oE 'https://freenode\.yoyapai\.com/[^"<> ]+\.yaml' | head -1)

# 提取 V2Ray 订阅链接 (txt)
V2RAY_URL=$(echo "$PAGE" | grep -oE 'https://freenode\.yoyapai\.com/[^"<> ]+\.txt' | head -1)

# 提取节点数量
NODE_COUNT=$(echo "$PAGE" | grep -oE '更新数量[：:][0-9]+' | grep -oE '[0-9]+' | head -1)

# 提取实测速度
SPEED=$(echo "$PAGE" | grep -oE '实测速度[：:][0-9.]+MB/s' | head -1 | sed 's/.*[：:]//')

# --- 检查是否提取成功 ---
if [[ -z "$CLASH_URL" && -z "$V2RAY_URL" ]]; then
    warn "未找到任何订阅链接，可能原因:"
    warn "  1. 今日文章还没有发布订阅"
    warn "  2. 网页编码格式变化"
    echo ""
    echo "页面片段 (调试用):"
    echo "$PAGE" | grep -i "freenode\|yaml\|\.txt" | head -5
    fail "无法提取订阅链接"
fi

# --- Step 3: 输出结果 ---
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  📅 ${ARTICLE_DATE:-$TODAY} 免费节点"
echo "  📊 ${NODE_COUNT:-?} 个节点 | ${SPEED:-速度未知}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

{
    echo "# yoyapai.com 每日免费节点"
    echo "# 日期: ${ARTICLE_DATE:-$TODAY}"
    echo "# 节点数: ${NODE_COUNT:-未知}"
    echo "# 实测速度: ${SPEED:-未知}"
    echo "# 来源: $LATEST_URL"
    echo "# 提取时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
} > "$OUTPUT_FILE"

if [[ -n "$CLASH_URL" ]]; then
    ok "Clash 订阅: $CLASH_URL"
    echo "[Clash / Clash Meta / Mihomo 订阅]" >> "$OUTPUT_FILE"
    echo "$CLASH_URL" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
else
    warn "未找到 Clash 订阅链接"
fi

if [[ -n "$V2RAY_URL" ]]; then
    ok "V2Ray 订阅: $V2RAY_URL"
    echo "[V2Ray / V2RayN / V2RayNG 订阅]" >> "$OUTPUT_FILE"
    echo "$V2RAY_URL" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
else
    warn "未找到 V2Ray 订阅链接"
fi

# --- Step 4: 下载订阅内容到本地 ---
echo "" >> "$OUTPUT_FILE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

if [[ -n "$CLASH_URL" ]]; then
    info "正在下载 Clash 配置..."
    CLASH_CONTENT=$(curl -sL --connect-timeout 20 --max-time 60 "$CLASH_URL" 2>/dev/null || echo "# 下载失败")
    echo "[Clash 配置文件内容]" >> "$OUTPUT_FILE"
    echo "$CLASH_CONTENT" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    CLASH_LINES=$(echo "$CLASH_CONTENT" | wc -l)
    ok "Clash 配置: ${CLASH_LINES} 行"
fi

if [[ -n "$V2RAY_URL" ]]; then
    info "正在下载 V2Ray 配置..."
    V2RAY_CONTENT=$(curl -sL --connect-timeout 20 --max-time 60 "$V2RAY_URL" 2>/dev/null || echo "# 下载失败")
    echo "[V2Ray 节点列表]" >> "$OUTPUT_FILE"
    echo "$V2RAY_CONTENT" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    V2RAY_LINES=$(echo "$V2RAY_CONTENT" | wc -l)
    ok "V2Ray 节点: ${V2RAY_LINES} 条"
fi

# --- Step 5: 生成快捷导入文件 ---
if [[ -n "$CLASH_URL" ]]; then
    echo "$CLASH_URL" > "${OUTPUT_DIR}/clash-latest.txt"
fi
if [[ -n "$V2RAY_URL" ]]; then
    echo "$V2RAY_URL" > "${OUTPUT_DIR}/v2ray-latest.txt"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
ok "全部完成！文件保存到:"
echo "  📁 $OUTPUT_FILE"
echo ""
echo "📋 快速导入方式:"
if [[ -n "$CLASH_URL" ]]; then
    echo "  Clash → 配置 → 粘贴URL"
    echo "  $CLASH_URL"
fi
if [[ -n "$V2RAY_URL" ]]; then
    echo "  V2RayN → 订阅 → 粘贴URL"
    echo "  $V2RAY_URL"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
