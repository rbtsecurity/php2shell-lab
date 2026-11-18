#!/usr/bin/env bash
# RBT Security: bring the PHP2Shell defender lab up.
# Uses Docker Compose v2 only: `docker compose` (not broken `docker-compose`).
set -euo pipefail
cd "$(dirname "$0")"

PORT=8105
mkdir -p out && chmod 777 out

if ! command -v docker >/dev/null 2>&1; then
  echo "[-] docker not found" >&2
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "[-] Docker Compose v2 plugin missing." >&2
  echo "    Install:  sudo apt-get update && sudo apt-get install -y docker-compose-plugin" >&2
  echo "    Check:    docker compose version" >&2
    echo "    See also: README.md (Ubuntu: Compose v2 required)" >&2
  exit 1
fi

echo "[*] using: docker compose ($(docker compose version --short 2>/dev/null || echo v2))"

if [[ -f Dockerfile ]]; then
  docker compose build
fi

docker compose up -d

printf '[*] waiting for target'
for _ in $(seq 1 40); do
  if curl -fsS "http://127.0.0.1:${PORT}/?probe=1" >/dev/null 2>&1; then
    echo " ready"
    echo "[+] RBT Security lab up  ->  http://127.0.0.1:${PORT}/"
    exit 0
  fi
  printf '.'
  sleep 0.5
done
echo " NOT responding"
echo "[-] target did not answer; check: docker compose logs lab" >&2
exit 1
