# Setup

If you're trying to recreate this repo from scratch, here's the steps you need to take. If you're a next-in-line leader, don't follow these steps -- a bunch of the configuration should already be complete and you should just need to decrypt the files. However, if you lost the key, then you'll need to follow this setup again.

> The services are sorted alphabetically for ease of lookup.

## Locally

A large majority of the setup will be done locally by both creating and preparing the secrets in each respective service and repository. Before you get started however, note these few things:

- Store all of these in `secrets/`
- Decide on a user and password
    - You can generate a secure password with `openssl rand -base64 24`
    - This pair will be referenced as myuser mypass for the rest of the document
    - You can store it in `secrets/login.txt` as myuser:mypass for convenience

### Dex

`dex/.env`

- Get the `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` by registering an oauth app through the org on GitHub
    - Go to org settings > developer settings > oauth apps
    - New oauth app
    - Give it a name then write the dex base url and callback url `/dex/callback`
    - Copy the client id and client secret
    - Go to org settings > actions > runner groups
- Generate a secret to **share** with outline with `openssl rand -hex 32`

```ini
GITHUB_CLIENT_ID=
GITHUB_CLIENT_SECRET=
OUTLINE_CLIENT_SECRET=

POSTGRES_USER=${DEX_POSTGRES_USER}
POSTGRES_PASSWORD=${DEX_POSTGRES_PASSWORD}
POSTGRES_DB=${DEX_POSTGRES_DB}
```

`dex/db.env`

- Generate a password with `openssl rand -hex 32`

```ini
# Fill
DEX_POSTGRES_USER=
DEX_POSTGRES_PASSWORD=

# As-is
DEX_POSTGRES_DB=dex
```

### nginx

`nginx/origin.pem` and `nginx/origin.key`

- `origin.pem` is an ssl certificate originating from our cloudflare hostname registration
- `origin.key` is the rsa key used for tls handshakes from cloudflare
- Both must be obtained and originate from our cloudflare

### Outline

`outline/.env`

- Generate the secret key, utils secret, and the **shared** OIDC client secret using `openssl rand -hex 32`

```ini
# Fill
SECRET_KEY=
UTILS_SECRET=
OIDC_CLIENT_SECRET=

# As-is
URL=<wiki public address>
PORT=9454

DATABASE_URL=postgres://${OUTLINE_POSTGRES_USER}:${OUTLINE_POSTGRES_PASSWORD}@postgres:5432/${OUTLINE_POSTGRES_DB}
PGSSLMODE=disable
REDIS_URL=redis://:${REDIS_PASSWORD}@redis:6379

FILE_STORAGE=local
FILE_STORAGE_LOCAL_ROOT_DIR=/var/lib/outline/data
FILE_STORAGE_UPLOAD_MAX_SIZE=262144000

OIDC_CLIENT_ID=outline
OIDC_AUTH_URI=<auth public address>/dex/auth
OIDC_TOKEN_URI=<container network address>/dex/token
OIDC_USERINFO_URI=<container network address>/dex/userinfo
OIDC_SCOPES=openid profile email groups offline_access
```

`outline/db.env`

- Generate a password with `openssl rand -hex 32`

```ini
# Fill
OUTLINE_POSTGRES_USER=
OUTLINE_POSTGRES_PASSWORD=

# As-is
OUTLINE_POSTGRES_DB=outline
```

### PostgreSQL

`postgres/.env`

- Generate a password with `openssl rand -hex 32`

```ini
# Fill
POSTGRES_USER=
POSTGRES_PASSWORD=

# As-Is
POSTGRES_DB=postgres
```

### Redis

`redis/.env`

- Generate a password with `openssl rand -hex 32`

```ini
# Fill
REDIS_PASSWORD=
```

### Registry

`registry/.env`

- Generate a secret with `openssl rand -hex 32`

```ini
# Fill
REGISTRY_HTTP_SECRET=

# As-Is
REGISTRY_AUTH="htpasswd"
REGISTRY_AUTH_HTPASSWD_REALM="Registry"
REGISTRY_AUTH_HTPASSWD_PATH="/auth/htpasswd"
```

`registry/.htpasswd`

```bash
docker run --rm --entrypoint htpasswd httpd:2 -Bbn myuser mypassword > secrets/registry.htpasswd
```

### Runner

`runner/.env`

- Get the `APP_ID` and `APP_PRIVATE_KEY` by registering an app through the org on GitHub
    - Go to org settings > developer settings > GitHub apps
    - New GitHub app
    - Give it a name and website, disable webhooks, and enable the organization permission "Self-hosted runners" as read/write
    - Copy the app id and download a private key
    - Go to org settings > actions > runner groups
    - Create a runner group and restrict access to certain repos then allow access to public repos
- To put the private key as a line in the env file, replace all the line breaks with `\n`

```ini
# Fill
APP_ID=
APP_PRIVATE_KEY=

# As-Is
APP_LOGIN=tamucybersec
RUNNER_SCOPE=org
ORG_NAME=tamucybersec
RUNNER_GROUP=Infrastructure
RUNNER_WORKDIR=/tmp/runner
LABELS=self-hosted
REGISTRY_URI=localhost:5000
DOCKER_CONFIG=/runner/data/.docker
```

`runner/config.json`

- This is used by the runner to authenticate with the registry

```bash
printf 'myuser:mypass' | base64
```

```json
{
	"auths": {
		"localhost:5000": {
			"auth": "base64"
		}
	}
}
```

### SOPS and age

`sops/age.key` and `sops/age.pub`

```bash
apt install age
age-keygen -o age.key
age-keygen -y age.key > age.pub
```

> [!IMPORTANT] These files reside in the sops directory, outside of the secrets folder.

#### Infrastructure, CyberHam, and cybr.club

Encrypt their secrets to secrets.enc using `scripts/encrypt.sh`.

### VaultWarden

`vaultwarden/.env`

- Generate a password with `openssl rand -hex 32`

```ini
# Fill
VAULTWARDEN_POSTGRES_USER=
VAULTWARDEN_POSTGRES_PASSWORD=

# As-is
VAULTWARDEN_POSTGRES_DB=vaultwarden
```

All of the remaining settings will be configured using the admin interface.

> This should probably be changed to be tracked via the [.env file](https://github.com/dani-garcia/vaultwarden/wiki/Configuration-overview) when we get a chance.

## On the Server

There are only two things you need to do actually connected to the server outside of the basic startup commands.

### Docker

Install docker on the server using [their guides](https://docs.docker.com/engine/install/).

> Be sure to `sudo usermod -aG docker $USER` and re-login to grant non-root docker perms.

### SCP

Place the age key on server so you can decrypt secrets:

```bash
scp /path/to/age.key user@ip_address:/path/to/Infrastructure/sops/age.key
```
