#!/bin/sh
set -eu

# Usage: encrypt.sh <dir>
# Call locally to encrypt <dir>/secrets into <dir>/secrets.enc

script_dir="$(cd "$(dirname "$0")" && pwd)"
export SOPS_DIR="$(cd "$script_dir/../sops" && pwd)"
export SOPS_USER="$(id -u):$(id -g)"

dir="$(cd "$1" && pwd)"
src="$dir/secrets"
dest="$dir/secrets.enc"
mkdir -p "$dest"

docker compose \
  -f "$SOPS_DIR/docker-compose.yml" run --rm --build \
  -v "$src":/work/secrets:ro \
  -v "$dest":/work/secrets.enc \
  sops /usr/local/bin/encrypt.sh secrets secrets.enc
