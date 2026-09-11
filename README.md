# Infrastructure

This repo adheres to the [infrastructure as code](https://en.wikipedia.org/wiki/Infrastructure_as_code) paradigm to configure an entire CI/CD stack using only three commands:

```bash
git clone https://github.com/tamucybersec/Infrastructure
docker compose run --rm bootstrap
docker compose up
```

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
- [SOPS](https://github.com/getsops/sops) with [age](https://github.com/FiloSottile/age)
    - Encrypts / decrypts secrets files for simple CD
- [Trivy](https://github.com/aquasecurity/trivy)
    - Scans containers for vulnerabilities
- [Infrastructure](https://github.com/tamucybersec/Infrastructure), [CyberHam](https://github.com/tamucybersec/CyberHam), and [cybr.club](https://github.com/tamucybersec/cybr.club)
    - Repos managed and deployed by the runner
    - See respective repos for their CI/CD scripts

## Setup

Ok, I lied. You have to do more than just three commands to set up the repo -- but only on the first time you set up the server! See [Setup/SCP](SETUP.md#on-the-server) for more details on this setup. It involves installing docker and scp'ing our SOPS key to the server so we can decrypt all the secrets of the repositories. If this is the first time you're setting up the entire repo however, you'll need to read the full setup doc.

## SOPS

SOPS was chosen as the secret management tool for this project for a couple reasons:

- Very simple
    - One command to generate it, one command to place it on the server
- Keeps providers (secrets) next to consumers (codebase)
    - This also means that secret changes are a part of PR, preventing deployment order issues
- Triggers redeploys on changes
    - Simplifies key rotation process (if we had one)

Essentially, we use a key to encrypt secrets and keep them directly in the repository. Secrets are then decrypted at deploy time, making repositories completely blind to the encryption process, keeping the code simple.

## Next Features

- Some wiki or docs platform
    - Should include both public & private pages
    - Should be available for all officers and committees
- Cloudflare [Terraform](https://github.com/hashicorp/terraform) management
    - [`cloudflared`](https://github.com/cloudflare/cloudflared)?

## Author Notes

This is genuinely the most confusing thing I've ever had the displeasure of architecting. I think the worst it gets is a compose file deploying a dockerfile of an image containerizing the runner which connects to the host's docker daemon which then runs actions CI to build a container, in the process calling shells script which calls compose to build a dockerfile. Godspeed to whoever needs to maintain this system.

Here's a full logical trace from compose up to a repo deployment just to give you an idea of what I'm talking about:

- Run compose up in the root dir
- The sops dockerfile gets built
- The sops container decrypts the secrets
- The runner dockerfile gets built
- The runner installs custom decrypt script
- The runner container goes live
- The runner performs Docker-out-of-Docker
- Repo X triggers CI inside runner container
- Repo X begins build process
- Repo X CI calls the runner's decrypt script
- Decrypt script triggers sops compose
- Sops compose uses sops dockerfile
- Sops container executes decrypt commands
- Repo X finishes build process
- Runner container deploys repo X container on host
