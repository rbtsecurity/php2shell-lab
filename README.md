# RBT Security · PHP2Shell Lab

Intentionally vulnerable Docker lab for **CVE-2026-109618** / **CVE-2026-109619** (`session.upload_progress` in php-src).

**Target only.** This repository does not ship an exploit or shell payload.

> Authorized use only. The compose file binds **127.0.0.1:8105** by default. Do not expose this lab to the public internet.

Deck / walkthrough: [sessions.rbtsec.com](https://sessions.rbtsec.com/#s5-title) (Vuln Recreations · PHP2Shell).

## Authors

- **Christian (Polunchis) Ramirez** — [RBT Security](https://rbtsec.com) · [@Polunchis](https://github.com/P0lunchis)
- **Asif Khan** — [RBT Security](https://rbtsec.com) · [@0xAs1F](https://github.com/0xAs1F)

**Contact:** polunchis@rbtsec.com

## Quick start

```bash
chmod +x up.sh down.sh scripts/verify-lab.sh
./up.sh
./scripts/verify-lab.sh
# browser: http://127.0.0.1:8105/
```

Status page should show **ARMED** on `php:8.4.26-apache` with `session.upload_progress` enabled.

```bash
curl -fsS 'http://127.0.0.1:8105/?probe=1'
```

### Ubuntu: Compose v2 required

`./up.sh` needs `docker compose` (Compose v2 plugin):

```bash
sudo apt-get update && sudo apt-get install -y docker-compose-plugin
docker compose version
```

If apt has no `docker-compose-plugin` on your release:

```bash
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo curl -SL \
  "https://github.com/docker/compose/releases/download/v2.32.4/docker-compose-linux-x86_64" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
docker compose version
```

## Tools in the image

`Dockerfile` installs classroom tools: `python3`, `net-tools` (`ifconfig`), `iproute2`, `gdb`, `procps`, `strace`, `curl`.  
Compose enables `SYS_PTRACE` and `seccomp:unconfined` so you can attach `gdb` / `strace` to the prefork worker.

## Public PoC credit

This lab is a **target only**. The classroom demonstration uses a public HTTP PoC that is **not shipped** in this repository.

Client used for the 8.4.26 file-proof demo:

- **Álvaro Díaz ([@alvarodh5](https://github.com/alvarodh5))** — [php2shell](https://github.com/alvarodh5/php2shell) (single-file HTTP-only client; multi-version profiles including 8.4.26 / 8.5.11)

That client builds on prior public research:

- **[@9bie](https://github.com/9bie)** — [php2shell-bypass-aslr-exp](https://github.com/9bie/php2shell-bypass-aslr-exp) (original pure-HTTP ASLR bypass for PHP 8.4.26)
- **[@dinosn](https://github.com/dinosn)** — [php-cve-2026-10961x-lab-poc](https://github.com/dinosn/php-cve-2026-10961x-lab-poc) (8.5.11 reclaim geometry)
- PHP security team; disclosure and analysis work by **Wiz** and **Calif**

Advisories: [GHSA-w8hw-w9fx-j79w](https://github.com/php/php-src/security/advisories/GHSA-w8hw-w9fx-j79w) (CVE-2026-109618), [GHSA-6wmf-4rv5-p3rp](https://github.com/php/php-src/security/advisories/GHSA-6wmf-4rv5-p3rp) (CVE-2026-109619).

## Classroom proof (file write only)

Use a short proof command against this lab, for example `id>/out/x`, with your own authorized HTTP client. Container name: **`rbt-p2s-lab`**.

```bash
# example shape (HTTP client not shipped here)
python3 exploit.py -u http://127.0.0.1:8105/index.php \
  --container rbt-p2s-lab --version 8.4.26 -c 'id>/out/x'
cat out/x
# uid=33(www-data) ...
```

Supported classroom proof is the short file write. Interactive shell helpers and long carriers are out of scope for this repository and must not be contributed.

## Under the hood (optional)

**gdb (Stage 1-2):** attach to the www-data worker PID from `./scripts/verify-lab.sh`. Stages 1-2 often `SIGABRT` in `zend_mm_panic` / `rfc1867`. Show `bt`. The worker may die; Stage 3 can run on a respawn.

**strace (Stage 3):** follow children from the Apache parent:

```bash
docker exec -it rbt-p2s-lab strace -f -e trace=execve,execveat -p 1
```

Expect `execve` of `sh -c 'id>/out/x'` then `/usr/bin/id` when the file proof succeeds.

## Patched contrast

1. Edit `Dockerfile` `FROM` → `php:8.4.27-apache`
2. `./down.sh && ./up.sh`
3. Status page should show **PATCHED**; the same short proof should not write `out/x`

Sibling floors: 8.5.12 / 8.3.36 / 8.2.35 (confirm current vendor advisories).

## Layout

| Path | Role |
|------|------|
| `webroot/index.php` | ARMED / PATCHED status page |
| `Dockerfile` | PHP 8.4.26 + lab tools |
| `docker-compose.yml` | build, ptrace, mounts, localhost:8105 |
| `scripts/verify-lab.sh` | health + tool checks |
| `out/` | proof drop (`/out` in container; contents gitignored) |
| `SECURITY.md` | rules of engagement |

## License

MIT. See `LICENSE`, `NOTICE`, and `SECURITY.md`.

Maintained by [RBT Security](https://rbtsec.com).
