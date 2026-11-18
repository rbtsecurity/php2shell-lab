#!/usr/bin/env bash
# Verify the defender lab is healthy and debug-ready.
set -euo pipefail
cd "$(dirname "$0")/.."

NAME="${CONTAINER_NAME:-rbt-p2s-lab}"
PORT="${PORT:-8105}"
FAIL=0

ok()   { printf '[+] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*"; }
bad()  { printf '[-] %s\n' "$*"; FAIL=1; }

echo "== RBT Security PHP2Shell lab verify =="

if ! docker ps --format '{{.Names}}' | grep -qx "$NAME"; then
  bad "container '$NAME' is not running (./up.sh first)"
  exit 1
fi
ok "container $NAME is running"

if curl -fsS "http://127.0.0.1:${PORT}/?probe=1" | grep -qx 'OK'; then
  ok "probe http://127.0.0.1:${PORT}/?probe=1 -> OK"
else
  bad "probe failed on :${PORT}"
fi

HDR="$(curl -fsS -D- "http://127.0.0.1:${PORT}/index.php" -o /dev/null || true)"
echo "$HDR" | grep -qi 'X-Lab: RBT-Security-php2shell' && ok "X-Lab header present" || bad "missing X-Lab header"
echo "$HDR" | grep -qi 'X-Powered-By: PHP/8.4.26' && ok "PHP/8.4.26 in X-Powered-By" || warn "X-Powered-By not 8.4.26 (check image)"

for cmd in 'python3 --version' 'ifconfig' 'gdb --version' 'ps --version' 'strace -V'; do
  if docker exec "$NAME" bash -c "$cmd" >/dev/null 2>&1; then
    ok "tool ok: $cmd"
  else
    bad "tool missing/failed: $cmd (rebuild image from Dockerfile)"
  fi
done

CAPS="$(docker inspect "$NAME" --format '{{json .HostConfig.CapAdd}} {{json .HostConfig.SecurityOpt}}')"
echo "$CAPS" | grep -q SYS_PTRACE && ok "SYS_PTRACE present" || bad "SYS_PTRACE missing (gdb -p may fail)"
echo "$CAPS" | grep -q seccomp:unconfined && ok "seccomp:unconfined present" || warn "seccomp not unconfined"

curl -fsS "http://127.0.0.1:${PORT}/?probe=1" >/dev/null || true
sleep 0.3
echo "[*] apache processes:"
docker exec "$NAME" ps auxww | awk 'NR==1 || /apache2/' | head -15

WORKER="$(
  docker exec "$NAME" bash -c '
    ps -eo pid,user,args --no-headers \
      | awk "/apache2/ && \$0 !~ /awk/ {print \$1, \$2}" \
      | while read -r pid user; do
          if [ "$user" != "root" ]; then echo "$pid"; exit 0; fi
        done
  ' || true
)"
if [ -n "${WORKER}" ]; then
  ok "non-root worker PID candidate: $WORKER"
  echo "    attach: docker exec -it $NAME gdb -p $WORKER"
else
  warn "no non-root apache worker found yet; hit the status page and re-run"
fi

if [ "$FAIL" -eq 0 ]; then
  echo
  ok "lab looks ready for file-proof + gdb/strace demo"
  echo "    Terminal A: docker exec -it $NAME gdb -p <worker-pid>"
  echo "                (gdb) set pagination off; catch exec; break system; break execve; continue"
  echo "    Terminal B: authorized HTTP client against http://127.0.0.1:${PORT}/index.php"
  echo "                  container=$NAME  version=8.4.26  proof: id>/out/x"
  exit 0
fi
echo
bad "fix some checks before the debug demo"
exit 1
