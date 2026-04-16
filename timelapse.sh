#!/usr/bin/env bash
# Run from any terminal: ./timelapse.sh start   then   ./timelapse.sh stop
# Resolves to bin/timelapse next to this file (no PATH setup required).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
exec "$ROOT/bin/timelapse" "$@"
