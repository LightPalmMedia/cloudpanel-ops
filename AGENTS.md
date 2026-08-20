# Agent instructions

## Cursor Cloud specific instructions

This environment controls the **entire CloudPanel host** via SSH — not a single site.

- Host: `188.245.192.203`
- Alias: `ssh cloudpanel` → `root@188.245.192.203`
- Scope: all CloudPanel vhosts under `/home/*/htdocs/*` (spsaxxu, onsetwear, sunvault, fichtl, LPM apps, …)

### Verify

```bash
ssh cloudpanel 'hostname; uptime; clpctl --version; ls /home'
```

### Site layout

```text
/home/<site-user>/htdocs/<domain>/
/home/<site-user>/logs/nginx/
/home/<site-user>/logs/php/
```

Examples:

```bash
ssh cloudpanel 'clpctl site:list'
ssh cloudpanel 'ls /home/spsaxxu/htdocs/spsaxxu.de'
ssh cloudpanel 'cd /home/spsaxxu/htdocs/spsaxxu.de && wp --allow-root core version'
```

Shared Redis: `127.0.0.1:6379` (per-site DB via `WP_REDIS_DATABASE` / `WP_REDIS_CONFIG`).

### Safety

- Diagnose read-only first (logs, curl, status).
- Never assume “lightpalmmedia” is the only site on this host.
- Do not flush Redis DBs, drop databases, or mass-delete files unless explicitly asked for that site.
- Prefer `scp` + remote script for complex SQL/shell (PowerShell quoting is fragile).
- This git repo has **no deploy pipeline** to production websites.

### Secrets

- Required Runtime Secret: `CLOUDPANEL_SSH_PRIVATE_KEY`
- Optional: `CLOUDPANEL_SSH_HOST`, `CLOUDPANEL_SSH_USER`, `CLOUDPANEL_SSH_PORT`
