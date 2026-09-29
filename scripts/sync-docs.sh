#!/usr/bin/env bash
# 用文件站匯出的 bundle 取代 references/docs/。
#
# 用法：scripts/sync-docs.sh <bundle-dir>
#
# <bundle-dir> 是文件站匯出工具產生的目錄，裡面有 manifest.json、INDEX.md，
# 以及 api/、developers/、start/、products/、ai/ 等章節。
# 這支腳本只複製 api/、developers/、start/、products/ 與 INDEX.md、manifest.json；
# ai/ 是介紹 Skill 與 MCP 本身的頁面，Skill 用不到，所以不複製。
# 複製的內容一律原樣保留，不做任何修改。
set -euo pipefail

SECTIONS="api developers start products"

die() {
  echo "錯誤：$*" >&2
  exit 1
}

[ $# -eq 1 ] || {
  echo "用法：$0 <bundle-dir>" >&2
  exit 2
}

[ -d "$1" ] || die "找不到 bundle 目錄：$1"
BUNDLE=$(cd "$1" && pwd)
REPO=$(cd "$(dirname "$0")/.." && pwd)
DEST="$REPO/references/docs"

[ -f "$BUNDLE/manifest.json" ] || die "$BUNDLE 沒有 manifest.json，這不是文件站匯出的 bundle"
[ -f "$BUNDLE/INDEX.md" ] || die "$BUNDLE 沒有 INDEX.md"
for section in $SECTIONS; do
  [ -d "$BUNDLE/$section" ] || die "$BUNDLE 沒有 $section/ 目錄"
done

# 先複製到暫存目錄，全部成功後再換掉 references/docs/，避免留下一半新一半舊的內容。
mkdir -p "$REPO/references"
TMP=$(mktemp -d "$REPO/references/.docs-sync.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

for section in $SECTIONS; do
  cp -R "$BUNDLE/$section" "$TMP/$section"
done
cp "$BUNDLE/INDEX.md" "$BUNDLE/manifest.json" "$TMP/"
find "$TMP" -name '.DS_Store' -delete

rm -rf "$DEST"
mv "$TMP" "$DEST"
trap - EXIT

manifest_string() {
  grep -o "\"$1\": *\"[^\"]*\"" "$DEST/manifest.json" | head -n 1 | sed 's/.*"\([^"]*\)"$/\1/'
}
manifest_bool() {
  grep -o "\"$1\": *[a-z]*" "$DEST/manifest.json" | head -n 1 | sed 's/.*: *//'
}

PAGES=$(find "$DEST" -name '*.md' ! -path "$DEST/INDEX.md" | wc -l | tr -d ' ')

echo "已更新 references/docs/（$PAGES 頁）"
echo "sourceCommit: $(manifest_string sourceCommit)"
echo "generatedAt: $(manifest_string generatedAt)"
echo "siteUrl: $(manifest_string siteUrl)"
echo "linksRewritten: $(manifest_bool linksRewritten)"

# 檢查：manifest 列出的頁面（ai/ 除外）是否都在，以及頁面之間的相對連結是否都指得到檔案。
# 只提出警告，不中斷。需要 python3，沒有就略過。
if command -v python3 >/dev/null 2>&1; then
  python3 - "$DEST" <<'PY'
import json
import os
import re
import sys
from urllib.parse import unquote

dest = sys.argv[1]
problems = []

with open(os.path.join(dest, "manifest.json"), encoding="utf-8") as f:
    manifest = json.load(f)
for page in manifest.get("pages", []):
    path = page.get("path", "")
    if path.startswith("ai/"):
        continue
    if not os.path.isfile(os.path.join(dest, path)):
        problems.append(f"manifest 列出但沒有複製到：{path}")

link = re.compile(r"\]\(([^)\s]+)\)")
site_absolute = 0
for root, _, files in os.walk(dest):
    for name in files:
        if not name.endswith(".md"):
            continue
        file_path = os.path.join(root, name)
        with open(file_path, encoding="utf-8") as f:
            text = f.read()
        for target in link.findall(text):
            if target.startswith("/"):
                site_absolute += 1
                continue
            if re.match(r"^[a-z][a-z0-9+.-]*:", target) or target.startswith("#"):
                continue
            target_path = unquote(target.split("#", 1)[0])
            if not target_path:
                continue
            resolved = os.path.normpath(os.path.join(root, target_path))
            if not os.path.exists(resolved):
                rel = os.path.relpath(file_path, dest)
                problems.append(f"{rel} 連到不存在的檔案：{target}")

if site_absolute:
    problems.append(
        f"有 {site_absolute} 個以 / 開頭的站內連結，離線讀不到；請改用 linksRewritten 為 true 的 bundle"
    )

if problems:
    print(f"警告：發現 {len(problems)} 個問題", file=sys.stderr)
    for problem in problems:
        print(f"  - {problem}", file=sys.stderr)
else:
    print("檢查：manifest 頁面與相對連結都正常")
PY
else
  echo "未安裝 python3，略過連結檢查"
fi
