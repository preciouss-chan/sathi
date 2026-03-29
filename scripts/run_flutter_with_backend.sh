#!/usr/bin/env bash

set -euo pipefail

DEVICE_ID="${1:-}"
BACKEND_URL="${TRANSCRIBE_API_BASE_URL:-http://100.70.122.12:8000}"

CMD=(
  flutter
  run
  --dart-define=USE_FIREBASE=true
  --dart-define=USE_TRANSCRIBE_BACKEND=true
  --dart-define=TRANSCRIBE_API_BASE_URL="${BACKEND_URL}"
)

if [[ -n "${DEVICE_ID}" ]]; then
  CMD+=(-d "${DEVICE_ID}")
fi

printf 'Running with backend: %s\n' "${BACKEND_URL}"
if [[ -n "${DEVICE_ID}" ]]; then
  printf 'Target device: %s\n' "${DEVICE_ID}"
fi

"${CMD[@]}"
