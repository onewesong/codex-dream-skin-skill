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
RUNTIME="$CLIENT_ROOT/Codex Dream Skin Runtime"
trap '/bin/rm -rf "$TMP"' EXIT

"$ROOT/tests/run-tests.sh"
/bin/mkdir -p "$RUNTIME"
/usr/bin/rsync -a "$ROOT/assets/" "$RUNTIME/assets/"
/usr/bin/rsync -a \
  --exclude 'build-client-release.sh' \
  --exclude 'build-release.sh' \
  "$ROOT/scripts/" "$RUNTIME/scripts/"
/bin/cp "$ROOT/VERSION" "$ROOT/LICENSE" "$ROOT/NOTICE.md" "$RUNTIME/"

if [ "$STRIP_UNUSED_ASSETS" = "true" ]; then
  bundled_image="$("$NODE" -e '
    const fs = require("fs");
    const path = require("path");
    const theme = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    if (typeof theme.image !== "string" || !theme.image || path.basename(theme.image) !== theme.image) process.exit(1);
    process.stdout.write(theme.image);
  ' "$RUNTIME/assets/theme.json")"
  /usr/bin/find "$RUNTIME/assets" -maxdepth 1 -type f \
    \( -name '*.png' -o -name '*.jpg' -o -name '*.jpeg' -o -name '*.webp' \) \
    ! -name "$bundled_image" -delete
fi

/usr/bin/printf '%s\n' \
  '#!/bin/bash' \
  'set -euo pipefail' \
  'ROOT="$(cd "$(dirname "$0")" && pwd -P)"' \
  'export CODEX_DREAM_SKIN_ROOT="$HOME/Library/Application Support/CodexDreamSkinStudio/runtime"' \
  'exec "$ROOT/Codex Dream Skin Runtime/scripts/install-dream-skin-macos.sh" --replace-bundled-theme' \
  > "$CLIENT_ROOT/安装 Codex 主题编辑器.command"

/usr/bin/printf '%s\n' \
  'Codex Dream Skin 1.2.0' \
  '' \
  '双击“安装 Codex 主题编辑器.command”。安装完成后，桌面会出现启动、定制、验证和恢复四个入口。' \
  '' \
  '“Codex Dream Skin Runtime”是完整运行时。安装成功后可以删除这个解压目录，运行时已复制到本机 Application Support。' \
  > "$CLIENT_ROOT/使用说明.txt"

/bin/chmod 755 "$CLIENT_ROOT/安装 Codex 主题编辑器.command"
/bin/chmod 755 "$RUNTIME"/scripts/*.sh
/usr/bin/xattr -cr "$CLIENT_ROOT"
/usr/bin/find "$CLIENT_ROOT" -type f \( -name '.DS_Store' -o -name '._*' \) -delete
/bin/mkdir -p "$(dirname "$OUTPUT")"
/bin/rm -f "$OUTPUT"
COPYFILE_DISABLE=1 /usr/bin/ditto -c -k --keepParent --norsrc --noextattr "$CLIENT_ROOT" "$OUTPUT"
SHA256="$(/usr/bin/shasum -a 256 "$OUTPUT" | /usr/bin/awk '{print $1}')"
/usr/bin/printf 'Created %s\nSHA-256 %s\n' "$OUTPUT" "$SHA256"
