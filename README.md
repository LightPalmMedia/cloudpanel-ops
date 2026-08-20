# CloudPanel Ops (Cursor Cloud Environment)

Carrier repo for the **Cursor Cloud Agent** environment that SSHes into the shared CloudPanel host.

## Important

- This does **not** deploy or overwrite any website.
- Target is the whole server `root@188.245.192.203` (all CloudPanel sites), not a single domain.
- Live sites stay under `/home/<site-user>/htdocs/<domain>/` and are untouched by pushes to this repo.

## Setup in Cursor

1. Dashboard → Cloud Agents → Environments → select repo `LightPalmMedia/cloudpanel-ops`
2. Add secrets from your local paste file (never commit private keys):
   - Runtime Secret: `CLOUDPANEL_SSH_PRIVATE_KEY`
   - Env vars: `CLOUDPANEL_SSH_HOST=188.245.192.203`, `CLOUDPANEL_SSH_USER=root`, `CLOUDPANEL_SSH_PORT=22`
3. Allow network egress to `188.245.192.203:22`
4. Run a Build, then start a Cloud Agent and verify: `ssh cloudpanel 'hostname; clpctl --version'`
