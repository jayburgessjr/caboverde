#!/usr/bin/env bash
set -euo pipefail
ZIP_PATH="${1:-./dist/cabo-verde-hub.zip}"
: "${ROKU_IP:?Set ROKU_IP}"
: "${DEV_WEB_PASSWORD:?Set DEV_WEB_PASSWORD}"
[[ -f "$ZIP_PATH" ]] || { echo "Zip not found: $ZIP_PATH"; exit 1; }
curl -f -s -S -u "rokudev:${DEV_WEB_PASSWORD}"   -F "mysubmit=Install" -F "archive=@${ZIP_PATH}" "http://${ROKU_IP}/plugin_install"
echo
echo "Install request sent. Open http://${ROKU_IP} to confirm."
