# x-infra (Node.js)

Minimal Ansible + GitHub Actions deploy pipeline for a single Node.js application.

## Structure

```
.github/workflows/deploy.yml     — CI/CD pipeline
ansible/
  ansible.cfg                    — Ansible settings
  requirements.yml               — Ansible collections
  inventories/
    staging/
      hosts.ini                  — Server IP (from vault)
      group_vars/all/
        foundation.yml           — Paths, Caddy, registry config
        app.yml                  — App definition (image, domains, env, services)
        vault.yml                — Secrets (encrypt with ansible-vault)
    production/                  — Same structure, different values
  playbooks/
    deploy.yml                   — Main deploy playbook
  roles/
    app_env_node/                — Builds and writes .env to the server
    app_runtime_node/            — Renders docker-compose.yml and runs the app
```

## Quick Start

### 1. Set your app config

Edit `ansible/inventories/staging/group_vars/all/app.yml`:
- Set `image` to your GHCR image path
- Set `domains.staging` to your staging domain
- Add your env vars under `env.base`, `env.derived`, and `env.secret_map`

### 2. Set your secrets

Edit `ansible/inventories/staging/group_vars/all/vault.yml`, then encrypt it:

```bash
ansible-vault encrypt ansible/inventories/staging/group_vars/all/vault.yml
```

### 3. Add GitHub Secrets

| Secret | Description |
|--------|-------------|
| `SSH_PRIVATE_KEY` | Private key for SSH access to your server |
| `SERVER_USER` | SSH username |
| `WIREGUARD_CONFIG` | Full WireGuard config file content |
| `STAGING_SERVER_VPN_IP` | Server's WireGuard IP (staging) |
| `PRODUCTION_SERVER_VPN_IP` | Server's WireGuard IP (production) |
| `ANSIBLE_VAULT_PASSWORD` | Password used to encrypt vault.yml |
| `INFRA_REPO_PAT` | GitHub PAT for commit comments (optional) |

### 4. Deploy

**Via GitHub Actions UI:** Actions → Deploy → Run workflow

**Via repository dispatch** (from your app repo's CI):
```bash
curl -X POST https://api.github.com/repos/yourorg/x-infra/dispatches \
  -H "Authorization: Bearer $PAT" \
  -H "Content-Type: application/json" \
  -d '{"event_type":"deploy-app","client_payload":{"environment":"staging","tag":"abc123","repo":"yourorg/yourapp","commit_sha":"abc123","triggered_by":"github-actions"}}'
```

## Prerequisites on the server

- Docker + Docker Compose v2
- A running Caddy container named `caddy` connected to the `proxy_global` network
- A running shared cluster network: `cluster_staging_shared` / `cluster_production_shared`
- Shared services (postgres, redis, etc.) already running on those networks
