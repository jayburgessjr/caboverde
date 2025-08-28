#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
OUT_ZIP="$DIST_DIR/cabo-verde-hub.zip"
mkdir -p "$DIST_DIR"
cd "$ROOT_DIR"
for p in manifest source components images; do
  [[ -e "$p" ]] || { echo "Missing $p"; exit 1; }
done
rm -f "$OUT_ZIP"
zip -r "$OUT_ZIP" manifest source components images README.md -x "*/.*" ".git/*" ".github/*"
echo "Built $OUT_ZIP"
