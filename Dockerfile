# RBT Security PHP2Shell defender lab image.
# Official vulnerable PHP + classroom tools (no exploit code).
FROM php:8.4.26-apache

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      python3 \
      net-tools \
      iproute2 \
      gdb \
      procps \
      strace \
      curl \
      ca-certificates \
      vim-tiny \
      less \
 && rm -rf /var/lib/apt/lists/*

# Helpful defaults for instructor attach demos
ENV PYTHONDONTWRITEBYTECODE=1

# Allow gdb to read libphp helpers when attaching to the worker
RUN mkdir -p /root/.config/gdb \
 && printf 'set auto-load safe-path /\nset pagination off\n' > /root/.config/gdb/gdbinit
