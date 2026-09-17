#!/bin/sh
set -eu

# Usage: decrypt.sh <dir>
# Call locally to decrypt <dir>/secrets.enc into <dir>/secrets

script_dir="$(cd "$(dirname "$0")" && pwd)"
export SOPS_DIR="$(cd "$script_dir/../sops" && pwd)"

dir="$(cd "$1" && pwd)"
src="$dir/secrets.enc"
dest="$dir/secrets"
mkdir -p "$dest"

sudo \
  SOPS_DIR="$SOPS_DIR" \
  SOPS_USER="$(id -u):$(id -g)" \
  docker compose -f "$SOPS_DIR/docker-compose.yml" run --rm \
  -v "$src":/work/secrets.enc:ro \
  -v "$dest":/work/secrets \
  sops /usr/local/bin/decrypt.sh secrets.enc secrets
