# PHP2Shell lab - watch the hijacked-destructor payoff live under gdb.
#
# Attach this to the Apache MASTER (pid 1), not a worker:
#   docker exec -it rbt-p2s-lab gdb -p 1 -x /tmp/p2s-trace.gdb
# (scripts/gdb-watch.sh does the master lookup + copy for you.)
#
# Why these settings:
#   - The chain deliberately crashes workers (OOM -> SIGABRT) during stages 1-2.
#     The master survives and forks replacements, so we attach to it and follow
#     every child.
#   - detach-on-fork=off + schedule-multiple=on keep gdb on each forked worker.
#   - The SIGABRT/SIGSEGV handlers + the Python exit hook sail past the dozens of
#     intentional crashes, auto-returning focus to the master and continuing, so
#     we only ever stop at the real payoff.
#   - PHP's zif_system runs the command via popen() -> execve("/bin/sh", ...),
#     it never calls libc system(). So we 'catch exec', not 'break system'.

set pagination off
set detach-on-fork off
set schedule-multiple on
handle SIGABRT nostop noprint pass
handle SIGSEGV nostop noprint pass

catch exec
commands
  printf "\n==== EXEC CAUGHT (zif_system -> popen -> execve) ====\n"
  info proc cmdline
end

python
import gdb
def _resume(event):
    def _go():
        try:
            gdb.execute("inferior 1", to_string=True)
            gdb.execute("continue")
        except gdb.error:
            pass
    gdb.post_event(_go)
gdb.events.exited.connect(_resume)
end

continue
