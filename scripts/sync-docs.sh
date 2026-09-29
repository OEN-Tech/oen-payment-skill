#!/usr/bin/env bash
# 用文件站匯出的 bundle 取代 references/docs/。
#
# 用法：scripts/sync-docs.sh <bundle-dir>
#
# <bundle-dir> 是應援維護者用文件站匯出工具產生的目錄，裡面有 manifest.json、INDEX.md，
# 以及 api/、developers/、start/、products/、ai/ 等章節。
#
# 這支腳本只複製 api/、developers/、start/、products/ 與 INDEX.md、manifest.json。
# ai/ 是介紹 Skill 與 MCP 本身的頁面，Skill 用不到，所以不複製。
# 頁面內容一律原樣保留；只有兩個索引檔會配合「不複製 ai/」調整：
#   - INDEX.md：刪掉「章節」欄是 ai 的列，其餘內容不動。
#   - manifest.json：pages 只留下實際複製的頁面，其他欄位（sourceCommit 等）不動。
# 這樣 SKILL.md 叫 AI 查 INDEX.md 時，列出的路徑都讀得到。
set -euo pipefail

SECTIONS="api developers start products"
EXCLUDED_SECTION="ai"

die() {
  echo "錯誤：$*" >&2
  exit 1
}

[ $# -eq 1 ] || {
  echo "用法：$0 <bundle-dir>" >&2
  exit 2
}

command -v python3 >/dev/null 2>&1 || die "需要 python3 才能調整索引檔與檢查連結"

REPO=$(cd "$(dirname "$0")/.." && pwd)
# 確認腳本所在的 repo 就是這個 Skill，避免在別的目錄刪掉 references/docs/。
[ -f "$REPO/SKILL.md" ] && grep -q '^name: oen-payment$' "$REPO/SKILL.md" ||
  die "$REPO 不是 oen-payment skill 的目錄（找不到 name: oen-payment 的 SKILL.md）"

[ -d "$1" ] || die "找不到 bundle 目錄：$1"
BUNDLE=$(cd "$1" && pwd)
DEST="$REPO/references/docs"

[ -f "$BUNDLE/manifest.json" ] || die "$BUNDLE 沒有 manifest.json，這不是文件站匯出的 bundle"
[ -f "$BUNDLE/INDEX.md" ] || die "$BUNDLE 沒有 INDEX.md"
for section in $SECTIONS; do
  [ -d "$BUNDLE/$section" ] || die "$BUNDLE 沒有 $section/ 目錄"
done

# 先在暫存目錄準備好新內容。
mkdir -p "$REPO/references"
NEW=$(mktemp -d "$REPO/references/.docs-new.XXXXXX")
OLD=""
cleanup() {
  rm -rf "$NEW"
  [ -z "$OLD" ] || [ ! -d "$OLD" ] || [ -d "$DEST" ] || mv "$OLD" "$DEST"
}
trap cleanup EXIT

for section in $SECTIONS; do
  cp -R "$BUNDLE/$section" "$NEW/$section"
done
cp "$BUNDLE/INDEX.md" "$BUNDLE/manifest.json" "$NEW/"
find "$NEW" -name '.DS_Store' -delete

# 把 ai/ 從兩個索引檔拿掉（見檔頭說明）。
python3 - "$NEW" "$EXCLUDED_SECTION" <<'PY'
import json
import os
import sys

dest, excluded = sys.argv[1], sys.argv[2]

index_path = os.path.join(dest, "INDEX.md")
with open(index_path, encoding="utf-8") as f:
    lines = f.read().splitlines(keepends=True)
kept = []
for line in lines:
    cells = [c.strip() for c in line.strip().strip("|").split("|")] if line.lstrip().startswith("|") else []
    if cells and cells[0] == excluded:
        continue
    kept.append(line)
with open(index_path, "w", encoding="utf-8") as f:
    f.writelines(kept)

manifest_path = os.path.join(dest, "manifest.json")
with open(manifest_path, encoding="utf-8") as f:
    manifest = json.load(f)
manifest["pages"] = [
    page for page in manifest.get("pages", [])
    if not page.get("path", "").startswith(excluded + "/")
]
with open(manifest_path, "w", encoding="utf-8") as f:
    f.write(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
PY

# 換上新內容：舊目錄先移開，新目錄移進來成功後才刪舊的；
# 中途失敗時 cleanup 會把舊目錄放回去，不會讓 references/docs/ 消失。
if [ -d "$DEST" ]; then
  OLD=$(mktemp -d "$REPO/references/.docs-old.XXXXXX")
  rmdir "$OLD"
  mv "$DEST" "$OLD"
fi
mv "$NEW" "$DEST"
[ -z "$OLD" ] || rm -rf "$OLD"
OLD=""
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

# 檢查：manifest 與 INDEX.md 列出的檔案都在、manifest 與實際頁面一致、
# 頁面之間的相對連結都指得到檔案。只提出警告，不中斷。
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
listed = set()
for page in manifest.get("pages", []):
    path = page.get("path", "")
    listed.add(path)
    if not os.path.isfile(os.path.join(dest, path)):
        problems.append(f"manifest.json 列出但檔案不存在：{path}")

actual = set()
for root, _, files in os.walk(dest):
    for name in files:
        if name.endswith(".md"):
            rel = os.path.relpath(os.path.join(root, name), dest)
            if rel != "INDEX.md":
                actual.add(rel)
for path in sorted(actual - listed):
    problems.append(f"有這個檔案但 manifest.json 沒有列出：{path}")

with open(os.path.join(dest, "INDEX.md"), encoding="utf-8") as f:
    index_lines = f.read().splitlines()
file_column = None
index_count = 0
for line in index_lines:
    if not line.lstrip().startswith("|"):
        continue
    cells = [c.strip() for c in line.strip().strip("|").split("|")]
    if file_column is None:
        if "檔案" in cells:
            file_column = cells.index("檔案")
        continue
    if set("".join(cells)) <= set("-: "):
        continue
    if file_column >= len(cells):
        problems.append(f"INDEX.md 這一列沒有檔案欄：{line}")
        continue
    index_count += 1
    path = cells[file_column]
    if not os.path.isfile(os.path.join(dest, path)):
        problems.append(f"INDEX.md 列出但檔案不存在：{path}")
if file_column is None:
    problems.append("INDEX.md 找不到「檔案」欄")
elif index_count != len(listed):
    problems.append(f"INDEX.md 列了 {index_count} 頁，manifest.json 列了 {len(listed)} 頁")

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
    print(f"檢查：manifest.json 與 INDEX.md 的 {len(listed)} 頁都在，相對連結都正常")
PY
