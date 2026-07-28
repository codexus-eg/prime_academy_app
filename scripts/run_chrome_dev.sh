#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

PROXY_PID=""

cleanup() {
  if [[ -n "$PROXY_PID" ]] && kill -0 "$PROXY_PID" 2>/dev/null; then
    kill "$PROXY_PID" 2>/dev/null || true
    wait "$PROXY_PID" 2>/dev/null || true
  fi
}

trap cleanup EXIT INT TERM

node "$ROOT/tool/web_dev_proxy.js" &
PROXY_PID=$!

sleep 0.3

echo "[run_chrome_dev] API proxy pid=$PROXY_PID — Flutter web debug uses http://127.0.0.1:8787/api"
flutter pub get
flutter run -d chrome "$@"
