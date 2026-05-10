#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  wslg-run.sh [--detach] <gui-command> [args...]

Examples:
  wslg-run.sh xclock
  wslg-run.sh --detach xclock
  wslg-run.sh firefox
USAGE
}

detach=0
if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
  usage
  exit 0
fi

if [[ "${1:-}" == "--detach" ]]; then
  detach=1
  shift
fi

if [[ $# -eq 0 ]]; then
  usage >&2
  exit 2
fi

if [[ -d /usr/lib/wsl/lib ]]; then
  export LD_LIBRARY_PATH="/usr/lib/wsl/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
fi

if [[ -S /tmp/.X11-unix/X0 || -S /mnt/wslg/.X11-unix/X0 ]]; then
  export DISPLAY="${DISPLAY:-:0}"
else
  echo "wslg-run: WSLg X11 socket not found at /tmp/.X11-unix/X0 or /mnt/wslg/.X11-unix/X0" >&2
  exit 1
fi

if [[ -S /mnt/wslg/runtime-dir/wayland-0 ]]; then
  export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"
  runtime_dir="${XDG_RUNTIME_DIR:-/tmp/wslg-runtime-$(id -u)}"
  mkdir -p "$runtime_dir"
  chmod 700 "$runtime_dir" 2>/dev/null || true
  export XDG_RUNTIME_DIR="$runtime_dir"

  if [[ ! -S "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" && ! -L "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" ]]; then
    ln -sf "/mnt/wslg/runtime-dir/$WAYLAND_DISPLAY" "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY"
  fi
  if [[ -e "/mnt/wslg/runtime-dir/$WAYLAND_DISPLAY.lock" && ! -e "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY.lock" ]]; then
    ln -sf "/mnt/wslg/runtime-dir/$WAYLAND_DISPLAY.lock" "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY.lock"
  fi
fi

if [[ -S /mnt/wslg/PulseServer ]]; then
  export PULSE_SERVER="${PULSE_SERVER:-unix:/mnt/wslg/PulseServer}"
fi

if ! command -v "$1" >/dev/null 2>&1; then
  echo "wslg-run: command not found: $1" >&2
  exit 127
fi

if [[ "$detach" -eq 1 ]]; then
  log_file="/tmp/wslg-$(basename "$1").log"
  nohup setsid "$@" >"$log_file" 2>&1 < /dev/null &
  pid=$!
  echo "Started $1 as PID $pid"
  echo "Log: $log_file"
else
  exec "$@"
fi
