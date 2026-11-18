#!/usr/bin/env bash
# Attach gdb to the Apache MASTER and catch the hijacked-destructor exec live.
#
# The PHP2Shell chain deliberately crashes workers during stages 1-2, so
# attaching to a single worker PID dies on the first crash. This attaches to
# the master (which survives and forks replacements) and loads p2s-trace.gdb,
# which follows every forked worker, sails past the sacrificial crashes, and
# stops only when a worker exec's /bin/sh -- the real payoff.
#
# Usage:
#   Terminal A:  scripts/gdb-watch.sh
#   Terminal B:  authorized HTTP client against the lab (e.g. proof: pwd>/out/pwd)
#   -> Terminal A prints:  ==== EXEC CAUGHT ... cmdline = 'sh -c -- pwd>/out/pwd'
#   Confirm:     docker exec rbt-p2s-lab cat /out/pwd
#
# To quit gdb when done: Ctrl+C to get the prompt, then 'quit' (y to detach).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR/.."

NAME="${CONTAINER_NAME:-rbt-p2s-lab}"
GDBSCRIPT_LOCAL="$SCRIPT_DIR/p2s-trace.gdb"
GDBSCRIPT_IN="/tmp/p2s-trace.gdb"

if ! docker ps --format '{{.Names}}' | grep -qx "$NAME"; then
  echo "[-] container '$NAME' is not running (./up.sh first)" >&2
  exit 1
fi

if [ ! -f "$GDBSCRIPT_LOCAL" ]; then
  echo "[-] missing $GDBSCRIPT_LOCAL" >&2
  exit 1
fi

# Apache master = root-owned apache2 with the lowest PID.
MASTER="$(docker exec "$NAME" bash -c \
  'ps -eo pid,user,args --no-headers | awk "/apache2/ && \$2==\"root\" && \$0 !~ /awk/ {print \$1; exit}"' || true)"
if [ -z "${MASTER:-}" ]; then
  echo "[-] could not find the apache master process in $NAME" >&2
  exit 1
fi

docker cp "$GDBSCRIPT_LOCAL" "$NAME:$GDBSCRIPT_IN"

echo "[*] attaching gdb to apache master pid $MASTER in $NAME"
echo "[*] run the HTTP client in another terminal; watch for '==== EXEC CAUGHT'"
exec docker exec -it "$NAME" gdb -p "$MASTER" -x "$GDBSCRIPT_IN"
