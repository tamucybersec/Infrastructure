#!/bin/sh
set -eu

# Usage: encrypt.sh <dir>
# Call locally to encrypt <dir>/secrets into <dir>/secrets.enc

script_dir="$(cd "$(dirname "$0")" && pwd)"
export SOPS_DIR="$(cd "$script_dir/../sops" && pwd)"

dir="$(cd "$1" && pwd)"
src="$dir/secrets"
dest="$dir/secrets.enc"
mkdir -p "$dest"

sudo SOPS_DIR="$SOPS_DIR" \
  docker compose -f "$SOPS_DIR/docker-compose.yml" run --rm \
  -v "$src":/work/secrets:ro \
  -v "$dest":/work/secrets.enc \
  sops /usr/local/bin/encrypt.sh secrets secrets.enc
