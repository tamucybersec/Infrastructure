#!/bin/sh
set -eu

# Usage: compose.sh
# Call to set the correct bind paths for the runner

export INFRA_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
export SOPS_DIR="$INFRA_DIR/sops"

cd "$INFRA_DIR"
exec docker compose "$@"
