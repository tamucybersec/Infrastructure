#!/bin/sh
set -eu

# Usage: compose.sh
# Call to set the correct bind paths for the runner

INFRA_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
SOPS_DIR="$INFRA_DIR/sops"

cd "$INFRA_DIR"
exec sudo \
	INFRA_DIR="$INFRA_DIR" \
	SOPS_DIR="$SOPS_DIR" \
	docker compose "$@"
