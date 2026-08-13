#!/bin/bash
set -euo pipefail

# Claude Code on the webのリモートセッションでのみFlutter SDKをセットアップする。
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

FLUTTER_DIR="/opt/flutter"

if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi

echo "export PATH=\"$FLUTTER_DIR/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"

"$FLUTTER_DIR/bin/flutter" precache

cd "$CLAUDE_PROJECT_DIR"
"$FLUTTER_DIR/bin/flutter" pub get
