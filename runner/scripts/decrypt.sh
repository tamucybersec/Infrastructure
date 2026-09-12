#!/bin/sh
set -eu

# Usage: decrypt.sh <name?>
# Decrypt secrets during CI

src="$GITHUB_WORKSPACE/secrets.enc"

if [ $# -ge 1 ]; then
  vol="decrypted_secrets"
  dst="secrets/$1"
else
  vol="$GITHUB_WORKSPACE/secrets"
  dst="secrets"
fi

mkdir -p "$vol"
docker compose -f "$SOPS_DIR/docker-compose.yml" run --rm \
  -v "$src":/work/secrets.enc:ro \
  -v "$vol":/work/secrets \
  sops /usr/local/bin/decrypt.sh secrets.enc "$dst"
