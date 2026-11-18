# Security policy

## What this project is

An **intentionally vulnerable** local Docker lab for education and defensive research around:

- CVE-2026-109618
- CVE-2026-109619

## Rules of engagement

1. Run the lab only on hosts and networks you own or are explicitly authorized to use.
2. The default compose bind is `127.0.0.1:8105`. Do not expose this lab to the public internet.
3. This repository does **not** distribute exploits or shell payloads. Classroom proof is a short file write such as `id>/out/x`. Do not open issues asking for interactive shells or weaponization help.
4. If you discover a problem in the **lab packaging** (compose, docs, status page), open an issue on this repository or contact RBT Security through normal channels.

## Patch floor (contrast)

Vulnerable classroom default: `Dockerfile` `FROM php:8.4.26-apache` (local image `rbt-p2s-lab:8.4.26`)  
Patched contrast: change `FROM` to `php:8.4.27-apache`, rebuild (and sibling fixed releases on other branches).

The image includes classroom tools (python3, net-tools, gdb, strace, …). That does not change the PHP vulnerability surface; keep the lab firewalled.

Always verify current vendor advisories before drawing production conclusions.
