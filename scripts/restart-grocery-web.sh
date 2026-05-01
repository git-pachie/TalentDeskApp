#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_DIR="$ROOT_DIR/GroceryWeb/src/GroceryApp.API/Logs"
API_PROJECT="$ROOT_DIR/GroceryWeb/src/GroceryApp.API/GroceryApp.API.csproj"
WEB_PROJECT="$ROOT_DIR/GroceryWeb/src/GroceryApp.Admin/GroceryApp.Admin.csproj"
ACTION="${1:-restart}"

mkdir -p "$LOG_DIR"

stop_port() {
  local port="$1"
  local pids
  pids="$(lsof -ti tcp:"$port" 2>/dev/null || true)"

  if [[ -n "$pids" ]]; then
    echo "Stopping process on port $port: $pids"
    kill $pids 2>/dev/null || true
  fi
}

wait_for_port_clear() {
  local port="$1"

  for _ in {1..20}; do
    if ! lsof -ti tcp:"$port" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.25
  done

  local pids
  pids="$(lsof -ti tcp:"$port" 2>/dev/null || true)"
  if [[ -n "$pids" ]]; then
    echo "Force stopping process on port $port: $pids"
    kill -9 $pids 2>/dev/null || true
  fi
}

start_app() {
  local name="$1"
  local project="$2"
  local log_file="$3"
  local pid_file="$4"

  echo "Starting $name..."
  nohup dotnet run --project "$project" --launch-profile https > "$log_file" 2>&1 &
  echo "$!" > "$pid_file"
  echo "$name started with PID $(cat "$pid_file"). Log: $log_file"
}

stop_apps() {
  echo "Stopping GroceryApp API and web..."

  stop_port 5010
  stop_port 5001
  stop_port 5100
  stop_port 5002

  wait_for_port_clear 5010
  wait_for_port_clear 5001
  wait_for_port_clear 5100
  wait_for_port_clear 5002

  rm -f "$LOG_DIR/api.pid" "$LOG_DIR/web.pid"

  echo "Stop complete."
}

start_apps() {
  echo "Starting GroceryApp API and web..."

  wait_for_port_clear 5010
  wait_for_port_clear 5001
  wait_for_port_clear 5100
  wait_for_port_clear 5002

  start_app "API" "$API_PROJECT" "$LOG_DIR/api-console.log" "$LOG_DIR/api.pid"
  start_app "Web" "$WEB_PROJECT" "$LOG_DIR/web-console.log" "$LOG_DIR/web.pid"

  echo
  echo "Start complete."
  echo "API HTTP:  http://localhost:5010"
  echo "API HTTPS: https://localhost:5001"
  echo "Web HTTP:  http://localhost:5100"
  echo "Web HTTPS: https://localhost:5002"
}

restart_apps() {
  echo "Restarting GroceryApp API and web..."
  stop_apps
  start_apps
}

usage() {
  echo "Usage: $0 [start|stop|restart]"
  echo
  echo "Examples:"
  echo "  $0 start"
  echo "  $0 stop"
  echo "  $0 restart"
}

case "$ACTION" in
  start)
    start_apps
    ;;
  stop)
    stop_apps
    ;;
  restart)
    restart_apps
    ;;
  *)
    usage
    exit 1
    ;;
esac
