#!/usr/bin/env bash
# RBT Security: tear the PHP2Shell lab down.
set -euo pipefail
cd "$(dirname "$0")"

if ! command -v docker >/dev/null 2>&1; then
  echo "[-] docker not found" >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "[-] Docker Compose v2 plugin missing." >&2
  echo "    Install:  sudo apt-get update && sudo apt-get install -y docker-compose-plugin" >&2
  exit 1
fi

docker compose down
echo "[+] RBT Security lab down"
