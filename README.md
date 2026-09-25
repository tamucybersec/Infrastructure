# Infrastructure

This repo adheres to the [infrastructure as code](https://en.wikipedia.org/wiki/Infrastructure_as_code) paradigm to configure an entire CI/CD stack using only three commands:

```bash
git clone https://github.com/tamucybersec/Infrastructure
scripts/decrypt.sh .
scripts/compose.sh up
```

> **Always** run `compose up` from the root of the repo. We use several tricks revolving around the root of the repo to allow for the infrastructure to in-place update itself.

## Overview

- [Dex](https://github.com/dexidp/dex)
    - Simple OIDC auth platform
- [nginx](https://github.com/nginx/nginx)
    - A reverse proxy for routing requests to services
- [Outline](https://github.com/outline/outline)
    - Collaborative wiki documentation hub
- [PostgreSQL](https://github.com/postgres/postgres)
    - Powerful relational database
- [Redis](https://github.com/redis/redis)
    - Fast caching engine
- [Registry](https://github.com/distribution/distribution)
    - Hosts the containers from CI builds for CD
- [Runner](https://github.com/myoung34/docker-github-actions-runner)
    - GitHub Actions runner (containerized) for CI/CD
    - [Infrastructure](https://github.com/tamucybersec/Infrastructure), [CyberHam](https://github.com/tamucybersec/CyberHam), and [cybr.club](https://github.com/tamucybersec/cybr.club)
        - Repos managed and deployed by the runner
        - See respective repos for their CI/CD scripts
- [SOPS](https://github.com/getsops/sops) with [age](https://github.com/FiloSottile/age)
    - Encrypts / decrypts secrets files for simple CD
- [Terraform](https://github.com/hashicorp/terraform)
    - IaC for non-config driven systems
- [Trivy](https://github.com/aquasecurity/trivy)
    - Scans containers for vulnerabilities
- [VaultWarden](https://github.com/dani-garcia/vaultwarden)
    - Hosts passwords for simple secret sharing among the team

## Setup

Depending on the state of the repository, there are different steps you must follow:

- The infrastructure was already running but you need to restart the runner
    - Make sure you run `git pull origin` before decrypting and restarting the compose again
        - While the runner updates services in place, it does not update the original code that was cloned
            - Meaning if you want to run the latest version, you need to pull again
- You have all the secrets made you just need to run the infrastructure on a new server
    - Follow the steps in [Setup/On The Server](SETUP.md#on-the-server)
- You lost the `age` key or are starting from scratch with the repo
    - Follow the whole [setup guide](SETUP.md) to create and configure everything

## SOPS

SOPS was chosen as the secret management tool for this project for a couple reasons:

- Very simple
    - One command to generate it, one command to place it on the server
- Keeps providers (secrets) next to consumers (codebase)
    - This also means that secret changes are a part of PR, preventing deployment order issues
- Triggers redeploys on changes
    - Simplifies key rotation process (if we had one)

Essentially, we use a key to encrypt secrets and keep them directly in the repository. Secrets are then decrypted at deploy time, making repositories completely blind to the encryption process, keeping the code simple.

## Next (Possible) Features

- Backup program
    - Since we have SOPS, we can make encrypted backups to any provider
        - GCP buckets are like $6 a TB so probably only pennies for us
    - This is essential for resiliency
    - Probably use terraform
- Pin image versions and set up alerting system
    - To prevent unforseen breakages, pin the image version
    - Will need some alert system for upgrading when vulnerabilities are found
- Self-repairing infrastructure
    - Create intelligent CI workflows to deploy only the service that got updated
    - Run specific tests for the containers including vuln scanning before deployment
- Health checks and rollback
    - Include automatic health checks (maybe with a script on the runner)
    - Add a rollback when health check fails
- Rollback system
    - Some system to manually rollback changes to a specific previous version
- Container scanning
    - Probably using a script in runner, scan a particular image and report on it
    - Maybe do as a separate job so it shows as a separate check?
- Self hosted GitLabs mirror
    - Open source fallback in case github implodes
    - Mirror our repos and essential dependencies
- Prevent mass search scan attacks
    - fail2ban or nginx rate limiting
- Config for VaultWarden
    - We're currently using the vaultwarden config from a long time ago
    - IaC it and update any variables we may need (like using the postgres database!)
- Save terraform plans
    - Terraform will one day shoot us in the foot
    - Save the plan somewhere and require up to date PRs so it doesn't
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
