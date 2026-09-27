# Incident: root filesystem 100% full (2026-09-27)

Host: CloudPanel `I2` / `188.245.192.203` (Discord alert label: `song-competition / CLP`).

## What happened

`/` (`/dev/sda1`, 150G) hit **100% used / 0G free**. MySQL crashed at 04:28 CEST. The weekly AlexAndy static SEO rebuild (`/opt/alexandy-static/deploy/refresh-instagram-static.sh`, Sunday 03:00) kept **three** ~25G copies of the same ~199k HTML pages:

| Path | Role | After incident |
|------|------|----------------|
| `/home/alexandyproductions/static/seo` | Live (nginx) | **kept** |
| `/opt/alexandy-static/dist-build` | Staging build | **removed** |
| `/opt/alexandy-static/dist` | Extra rsync "for inspection" | **removed** |

The disk-full write also **truncated** `/home/song-competition/htdocs/song-competition.live/.env` to 0 bytes (same inode since 2026-06-28, mtime 04:57). `song-competition.service` then crash-looped on `Invalid JWT_SECRET`.

## What was done on the host

1. Freed space: journal vacuum, truncated `/var/log/mysql/error.log`, stale `/tmp` archives, old song-competition access logs, June `site-export.tar.gz`.
2. Deleted the two unused 25G `/opt` trees. Live SEO stays under `static/seo`.
3. Restarted MySQL (down since 04:28).
4. Restored song-competition `.env` from rclone backup `impossible:lpm-clp-backups/2026-09-12/.../backup.tar` (3.7K, JWT_SECRET present). Restarted the unit.
5. Patched the weekly refresh script: no third copy, delete staging after deploy, abort if `< 35G` free.
6. Capped systemd-journald at 200M / 7 days (`/etc/systemd/journald.conf.d/size-limit.conf`).

Result after cleanup: **~91G used / 54G free (63%)**.

## Canonical copies in this repo

- `ops/alexandy-static/refresh-instagram-static.sh` — applied on the host at the same path under `/opt/alexandy-static/deploy/`.
- `ops/systemd/journald-size-limit.conf` — applied as `/etc/systemd/journald.conf.d/size-limit.conf`.

This repo does **not** auto-deploy those files. Re-apply over SSH if the host copies drift.
