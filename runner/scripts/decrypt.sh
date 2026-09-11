#!/bin/sh
set -eu

# Usage: decrypt
# Call in CI to decrypt secrets during the build process

src="$GITHUB_WORKSPACE/secrets.enc"
dest="$GITHUB_WORKSPACE/secrets"

mkdir -p "$dest"

docker compose -f "$SOPS_DIR/docker-compose.yml" run --rm \
  -v "$src":/work/secrets.enc:ro \
  -v "$dest":/work/secrets \
  sops /usr/local/bin/decrypt.sh secrets.enc secrets
