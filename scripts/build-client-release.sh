#!/bin/bash

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd -P)"
NODE="${NODE:-/Applications/ChatGPT.app/Contents/Resources/cua_node/bin/node}"
[ -x "$NODE" ] || { printf 'Codex bundled Node.js was not found: %s\n' "$NODE" >&2; exit 1; }
STRIP_UNUSED_ASSETS="false"
if [ "${1:-}" = "--strip-unused-assets" ]; then
  STRIP_UNUSED_ASSETS="true"
  shift
fi
OUTPUT="${1:-$HOME/Desktop/Codex 主题编辑器.zip}"
TMP="$(/usr/bin/mktemp -d /tmp/codex-dream-client.XXXXXX)"
CLIENT_ROOT="$TMP/Codex 主题编辑器"
SKILL="$CLIENT_ROOT/Codex Dream Skin Skill"
trap '/bin/rm -rf "$TMP"' EXIT

"$ROOT/tests/run-tests.sh"
/bin/mkdir -p "$SKILL"
/usr/bin/rsync -a \
  --exclude '.git/' \
  --exclude '.DS_Store' \
  --exclude 'release/' \
  --exclude 'runtime/' \
  "$ROOT/" "$SKILL/"

if [ "$STRIP_UNUSED_ASSETS" = "true" ]; then
  bundled_image="$("$NODE" -e '
    const fs = require("fs");
    const path = require("path");
    const theme = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    if (typeof theme.image !== "string" || !theme.image || path.basename(theme.image) !== theme.image) process.exit(1);
    process.stdout.write(theme.image);
  ' "$SKILL/assets/theme.json")"
  /usr/bin/find "$SKILL/assets" -maxdepth 1 -type f \
    \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' \) \
    ! -name "$bundled_image" -delete
fi

/usr/bin/printf '%s\n' \
  '#!/bin/bash' \
  'set -euo pipefail' \
  'ROOT="$(cd "$(dirname "$0")" && pwd -P)"' \
  'exec "$ROOT/Codex Dream Skin Skill/scripts/install-dream-skin-macos.sh" --replace-bundled-theme' \
  > "$CLIENT_ROOT/安装 Codex 主题编辑器.command"

/usr/bin/printf '%s\n' \
  'Codex Dream Skin 1.2.0' \
  '' \
  '推荐方式：把这个完整 ZIP、你喜欢的图片和“给 Codex 的部署提示词.md”一起发给自己的 Codex。' \
  '' \
  '手动方式：双击“安装 Codex 主题编辑器.command”。安装完成后，桌面会出现启动、定制、验证和恢复四个入口。' \
  '' \
  '不要只复制图片或 CSS。Codex Dream Skin Skill 是完整运行包，请勿删除或拆分。' \
  > "$CLIENT_ROOT/使用说明.txt"

/bin/cp "$ROOT/CLIENT_DEPLOY_PROMPT.md" "$CLIENT_ROOT/给 Codex 的部署提示词.md"
/bin/chmod 755 "$CLIENT_ROOT/安装 Codex 主题编辑器.command"
/bin/chmod 755 "$SKILL"/*.command "$SKILL"/scripts/*.sh "$SKILL"/tests/*.sh
/usr/bin/xattr -cr "$CLIENT_ROOT"
/usr/bin/find "$CLIENT_ROOT" -type f \( -name '.DS_Store' -o -name '._*' \) -delete
/bin/mkdir -p "$(dirname "$OUTPUT")"
/bin/rm -f "$OUTPUT"
COPYFILE_DISABLE=1 /usr/bin/ditto -c -k --keepParent --norsrc --noextattr "$CLIENT_ROOT" "$OUTPUT"
SHA256="$(/usr/bin/shasum -a 256 "$OUTPUT" | /usr/bin/awk '{print $1}')"
/usr/bin/printf 'Created %s\nSHA-256 %s\n' "$OUTPUT" "$SHA256"
