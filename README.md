# Infrastructure

This repo adheres to the [infrastructure as code](https://en.wikipedia.org/wiki/Infrastructure_as_code) paradigm to configure an entire CI/CD stack using only two commands: `git clone` and `docker compose up`.

## Overview

- [Runner](https://github.com/myoung34/docker-github-actions-runner)
    - GitHub Actions runner (containerized) for CI/CD
- [Registry](https://github.com/distribution/distribution)
    - Hosts the containers from CI builds for CD
- [nginx](https://github.com/nginx/nginx)
    - A reverse proxy for routing requests to services
- [PostgreSQL](https://github.com/postgres/postgres)
    - Powerful FOSS relational database
- [VaultWarden](https://github.com/dani-garcia/vaultwarden)
    - Hosts passwords for simple secret sharing among the team
- [SOPS](https://github.com/getsops/sops)
    - Encrypts / decrypts secrets files for simple CD
- [CyberHam](https://github.com/tamucybersec/CyberHam)
    - Club discord bot and API
- [cybr.club](https://github.com/tamucybersec/cybr.club)
    - Club website and sponsor dashboard

## Next Features

- Cloudflare [Terraform](https://github.com/hashicorp/terraform) management
    - [`cloudflared`](https://github.com/cloudflare/cloudflared)?
